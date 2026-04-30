//! VirtIO Sound driver using the modern PCI MMIO interface.
//!
//! Discovers the VirtIO sound device (PCI vendor=0x1AF4, device=0x1059),
//! walks the PCI VirtIO capability list to find the CommonCfg and Notify
//! MMIO regions, then initialises the control and TX queues to stream WAV
//! audio in PCM periods.

const std = @import("std");

const pci = @import("pci.zig");
const virtio = @import("virtio.zig");
const wav = @import("wav.zig");

const log = std.log.scoped(.virtio_sound);

// ── VirtIO Sound identity ─────────────────────────────────────────────────────

/// PCI vendor ID assigned to all VirtIO devices.
const virtio_vendor_id: u16 = 0x1AF4;
/// PCI device ID for the VirtIO sound device (0x1040 + VIRTIO_ID_SOUND=25).
const virtio_sound_dev_id: u16 = 0x1059;

// ── VirtIO Sound enumerations (§5.14) ─────────────────────────────────────────

/// VirtIO sound control command codes (§5.14.6.8.1).
const CommandCode = enum(u32) {
    /// Configure PCM stream parameters (format, rate, channels, buffer sizes).
    set_params = 0x0101,
    /// Prepare a PCM stream for playback.
    prepare = 0x0102,
    /// Start PCM stream playback.
    start = 0x0104,
};

/// VirtIO sound response status codes (§5.14.6.8.1).
/// Non-exhaustive so device-returned codes not listed here are held without trapping.
const StatusCode = enum(u32) {
    /// Command completed successfully.
    ok = 0x8000,
    _,
};

/// VirtIO sound virtqueue indices (§5.14.2).
const Queue = enum(u16) {
    /// Control queue: carries command requests and responses.
    control = 0,
    /// TX queue: carries PCM audio frames from the driver to the device.
    tx = 2,
};

/// PCM sample format codes (§5.14.6.6.1).
const PcmFmt = enum(u8) {
    /// Unsigned 8-bit PCM.
    u8 = 4,
    /// Signed 16-bit little-endian PCM.
    s16 = 5,
};

/// PCM sample rate codes (§5.14.6.6.2).
const PcmRate = enum(u8) {
    @"8000" = 1,
    @"11025" = 2,
    @"16000" = 3,
    @"22050" = 4,
    @"32000" = 5,
    @"44100" = 6,
    @"48000" = 7,
};

// ── Virtqueue static storage ──────────────────────────────────────────────────

/// Number of descriptors per virtqueue. Must be a power of two.
const queue_size: u16 = 64;

/// Control queue: carries command requests and responses.
var ctrl_queue: virtio.Virtqueue(queue_size) = .{};
/// TX queue: carries PCM audio frames from the driver to the device.
var tx_queue: virtio.Virtqueue(queue_size) = .{};

// ── VirtIO Sound message structures ──────────────────────────────────────────

/// Generic response header returned by the device for all control commands.
const SndHdr = extern struct {
    /// Response status code; StatusCode.ok (0x8000) indicates success.
    code: StatusCode,
};

/// Request header for PCM stream commands that target a specific stream.
const SndPcmHdr = extern struct {
    /// Command code (e.g. CommandCode.prepare, CommandCode.start).
    code: CommandCode,
    /// Index of the PCM stream to operate on.
    stream_id: u32,
};

/// PCM_SET_PARAMS request: configures the stream's format before prepare/start.
const SndPcmSetParams = extern struct {
    /// Command code; must be CommandCode.set_params.
    code: CommandCode,
    /// Index of the PCM stream to configure.
    stream_id: u32,
    /// Total device buffer size in bytes (must be a multiple of `period_bytes`).
    buffer_bytes: u32,
    /// Period (interrupt granularity) size in bytes.
    period_bytes: u32,
    /// Optional feature flags (0 = none).
    features: u32,
    /// Number of audio channels.
    channels: u8,
    /// Sample format (see PcmFmt).
    format: PcmFmt,
    /// Sample rate (see PcmRate).
    rate: PcmRate,
    /// Reserved; must be zero.
    padding: u8,
};

/// Header prepended to each TX buffer to identify the target stream.
const SndPcmXfer = extern struct {
    /// Index of the PCM stream receiving the audio data.
    stream_id: u32,
};

/// Status written back by the device at the end of each TX descriptor chain.
const SndPcmStatus = extern struct {
    /// Completion status; StatusCode.ok (0x8000) indicates success.
    status: StatusCode,
    /// Estimated device playback latency in bytes at the time of completion.
    latency_bytes: u32,
};

comptime {
    std.debug.assert(@sizeOf(SndPcmSetParams) == 24);
}

// ── Queue helpers ─────────────────────────────────────────────────────────────

// ── Control queue submit (polling, chain always starts at desc 0) ─────────────

/// Submit a two-descriptor request/response chain on the control queue and
/// spin until the device writes a completion entry to the used ring.
fn ctrlSubmit(
    req: []const u8,
    resp: []u8,
    caps: *const virtio.Caps,
) void {
    ctrl_queue.submit(caps, &[_]virtio.Desc{
        .{ .addr = @intFromPtr(req.ptr), .len = @intCast(req.len), .flags = .{ .next = true }, .next = 1 },
        .{ .addr = @intFromPtr(resp.ptr), .len = @intCast(resp.len), .flags = .{ .write = true }, .next = 0 },
    });
}

// ── TX queue submit (polling, chain always starts at desc 0) ──────────────────

/// Submit a three-descriptor xfer-header/pcm-data/status chain on the TX queue
/// and spin until the device writes a completion entry to the used ring.
fn txSubmit(
    xfer: *const SndPcmXfer,
    pcm: []const u8,
    status: *SndPcmStatus,
    caps: *const virtio.Caps,
) void {
    tx_queue.submit(caps, &[_]virtio.Desc{
        .{ .addr = @intFromPtr(xfer), .len = @sizeOf(SndPcmXfer), .flags = .{ .next = true }, .next = 1 },
        .{ .addr = @intFromPtr(pcm.ptr), .len = @intCast(pcm.len), .flags = .{ .next = true }, .next = 2 },
        .{ .addr = @intFromPtr(status), .len = @sizeOf(SndPcmStatus), .flags = .{ .write = true }, .next = 0 },
    });
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Parse `data` as a WAV file and stream it through the VirtIO sound device.
pub fn play(data: []const u8) !void {
    const parsed = try wav.parse(data);
    const fmt = parsed.fmt;

    log.info("WAV: {}Hz {}ch {}-bit, {} bytes PCM", .{
        fmt.sample_rate, fmt.channels, fmt.bits_per_sample, parsed.pcm.len,
    });

    const found = virtio.findDevice(virtio_vendor_id, virtio_sound_dev_id) orelse {
        log.err("VirtIO sound device not found on PCI bus", .{});
        return error.NoDevice;
    };
    log.info("VirtIO sound at PCI bus={} dev={}", .{ found.bus, found.dev });

    // Enable memory decode (bit 1) and bus mastering (bit 2).
    const dev_addr = pci.ConfigurationAddress{ .bus = found.bus, .device = found.dev };
    var cs: pci.CommandStatus = @bitCast(pci.configRead32(dev_addr.atOffset(.command)));
    cs.command.memory_space = true;
    cs.command.bus_master = true;
    pci.configWrite32(dev_addr.atOffset(.command), @bitCast(cs));

    const caps = try virtio.walkCaps(found.bus, found.dev);
    const common = caps.common;

    // ── Device initialisation sequence (§3.1) ────────────────────────────────
    common.device_status = .{}; // reset
    common.device_status = .{ .acknowledge = true, .driver = true };

    // Negotiate VIRTIO_F_VERSION_1 (feature bit 32 → select=1, bit 0).
    common.driver_feature_select = .low;
    common.driver_feature = .{};
    common.driver_feature_select = .high;
    common.driver_feature = .{ .version_1 = true };
    common.device_status = .{ .acknowledge = true, .driver = true, .features_ok = true };
    if (!common.device_status.features_ok) {
        log.err("device rejected VIRTIO_F_VERSION_1", .{});
        return error.FeaturesRejected;
    }

    // ── Queue setup ───────────────────────────────────────────────────────────
    ctrl_queue.setup(common, @intFromEnum(Queue.control));
    tx_queue.setup(common, @intFromEnum(Queue.tx));
    log.debug("controlq notify_off={} txq notify_off={}", .{ ctrl_queue.notify_off, tx_queue.notify_off });

    common.device_status = .{ .acknowledge = true, .driver = true, .features_ok = true, .driver_ok = true };

    // ── PCM_SET_PARAMS ────────────────────────────────────────────────────────
    const fmt_code: PcmFmt = if (fmt.bits_per_sample == 8) .u8 else .s16;
    const rate_code: PcmRate = switch (fmt.sample_rate) {
        8000 => .@"8000",
        11025 => .@"11025",
        16000 => .@"16000",
        22050 => .@"22050",
        32000 => .@"32000",
        44100 => .@"44100",
        48000 => .@"48000",
        else => .@"44100",
    };
    const frame_bytes: u32 = @as(u32, fmt.channels) * (fmt.bits_per_sample / 8);
    const period_bytes: u32 = 1024 * frame_bytes;
    var set_params = SndPcmSetParams{
        .code = .set_params,
        .stream_id = 0,
        .buffer_bytes = period_bytes * 4,
        .period_bytes = period_bytes,
        .features = 0,
        .channels = @intCast(fmt.channels),
        .format = fmt_code,
        .rate = rate_code,
        .padding = 0,
    };
    var ctrl_resp = SndHdr{ .code = .ok };
    ctrlSubmit(std.mem.asBytes(&set_params), std.mem.asBytes(&ctrl_resp), &caps);
    log.info("SET_PARAMS resp=0x{X}", .{@intFromEnum(ctrl_resp.code)});
    if (ctrl_resp.code != .ok) return error.SetParamsFailed;

    // ── PCM_PREPARE ───────────────────────────────────────────────────────────
    var prepare_req = SndPcmHdr{ .code = .prepare, .stream_id = 0 };
    ctrl_resp.code = .ok;
    ctrlSubmit(std.mem.asBytes(&prepare_req), std.mem.asBytes(&ctrl_resp), &caps);
    log.info("PREPARE resp=0x{X}", .{@intFromEnum(ctrl_resp.code)});
    if (ctrl_resp.code != .ok) return error.PrepareFailed;

    // ── PCM_START ─────────────────────────────────────────────────────────────
    var start_req = SndPcmHdr{ .code = .start, .stream_id = 0 };
    ctrl_resp.code = .ok;
    ctrlSubmit(std.mem.asBytes(&start_req), std.mem.asBytes(&ctrl_resp), &caps);
    log.info("START resp=0x{X}", .{@intFromEnum(ctrl_resp.code)});
    if (ctrl_resp.code != .ok) return error.StartFailed;

    // ── TX: stream PCM data one period at a time ──────────────────────────────
    const xfer = SndPcmXfer{ .stream_id = 0 };
    var tx_status = SndPcmStatus{ .status = .ok, .latency_bytes = 0 };
    var offset: usize = 0;
    var chunk: u32 = 0;
    const total_chunks = (parsed.pcm.len + period_bytes - 1) / period_bytes;
    while (offset < parsed.pcm.len) {
        const end = @min(offset + period_bytes, parsed.pcm.len);
        txSubmit(&xfer, parsed.pcm[offset..end], &tx_status, &caps);
        if (tx_status.status != .ok) {
            log.err("TX chunk {} failed: status=0x{X}", .{ chunk, @intFromEnum(tx_status.status) });
            return error.TxFailed;
        }
        offset = end;
        chunk += 1;
        if (chunk % 256 == 0) log.debug("TX {}/{} chunks", .{ chunk, total_chunks });
    }
    log.info("playback complete ({} chunks)", .{chunk});
}

// ── Tests ─────────────────────────────────────────────────────────────────────

test "SndHdr size" {
    try std.testing.expectEqual(4, @sizeOf(SndHdr));
}

test "SndPcmHdr size" {
    try std.testing.expectEqual(8, @sizeOf(SndPcmHdr));
}

test "SndPcmSetParams size" {
    try std.testing.expectEqual(24, @sizeOf(SndPcmSetParams));
}

test "SndPcmXfer size" {
    try std.testing.expectEqual(4, @sizeOf(SndPcmXfer));
}

test "SndPcmStatus size" {
    try std.testing.expectEqual(8, @sizeOf(SndPcmStatus));
}

test "play succeeds with minimal silent WAV" {
    const arch = @import("arch");
    try arch.freestanding();

    // One period of 16-bit mono silence at 44100 Hz.
    const pcm_len = 1024 * 2;
    var wav_buf: [44 + pcm_len]u8 = undefined;
    @memcpy(wav_buf[0..4], "RIFF");
    std.mem.writeInt(u32, wav_buf[4..8], wav_buf.len - 8, .little);
    @memcpy(wav_buf[8..12], "WAVE");
    @memcpy(wav_buf[12..16], "fmt ");
    std.mem.writeInt(u32, wav_buf[16..20], 16, .little); // fmt chunk size
    std.mem.writeInt(u16, wav_buf[20..22], 1, .little); // PCM
    std.mem.writeInt(u16, wav_buf[22..24], 1, .little); // mono
    std.mem.writeInt(u32, wav_buf[24..28], 44100, .little); // sample rate
    std.mem.writeInt(u32, wav_buf[28..32], 88200, .little); // byte rate
    std.mem.writeInt(u16, wav_buf[32..34], 2, .little); // block align
    std.mem.writeInt(u16, wav_buf[34..36], 16, .little); // bits per sample
    @memcpy(wav_buf[36..40], "data");
    std.mem.writeInt(u32, wav_buf[40..44], pcm_len, .little);
    @memset(wav_buf[44..], 0);

    try play(&wav_buf);
}
