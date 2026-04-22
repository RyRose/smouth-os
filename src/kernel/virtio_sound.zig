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

/// Command code: configure PCM stream parameters (format, rate, channels, buffer sizes).
const virtio_snd_r_pcm_set_params: u32 = 0x0101;
/// Command code: prepare a PCM stream for playback.
const virtio_snd_r_pcm_prepare: u32 = 0x0102;
/// Command code: start PCM stream playback.
const virtio_snd_r_pcm_start: u32 = 0x0104;
/// Response status code indicating the command completed successfully.
const virtio_snd_s_ok: u32 = 0x8000;

/// Queue index for the VirtIO sound control queue (commands and responses).
const controlq: u16 = 0;
/// Queue index for the VirtIO sound TX queue (PCM audio data).
const txq: u16 = 2;

/// PCM sample format code for unsigned 8-bit PCM.
const virtio_snd_pcm_fmt_u8: u8 = 4;
/// PCM sample format code for signed 16-bit little-endian PCM.
const virtio_snd_pcm_fmt_s16: u8 = 5;

/// PCM rate code for 8000 Hz.
const virtio_snd_pcm_rate_8000: u8 = 1;
/// PCM rate code for 11025 Hz.
const virtio_snd_pcm_rate_11025: u8 = 2;
/// PCM rate code for 16000 Hz.
const virtio_snd_pcm_rate_16000: u8 = 3;
/// PCM rate code for 22050 Hz.
const virtio_snd_pcm_rate_22050: u8 = 4;
/// PCM rate code for 32000 Hz.
const virtio_snd_pcm_rate_32000: u8 = 5;
/// PCM rate code for 44100 Hz.
const virtio_snd_pcm_rate_44100: u8 = 6;
/// PCM rate code for 48000 Hz.
const virtio_snd_pcm_rate_48000: u8 = 7;

// ── Virtqueue static storage ──────────────────────────────────────────────────

/// Number of descriptors per virtqueue. Must be a power of two.
const queue_size: u16 = 64;

// Static queue memory (BSS-allocated, no heap needed).
var ctrl_descs: [queue_size]virtio.Desc align(16) = undefined;
var ctrl_avail: virtio.AvailRing(queue_size) align(2) = undefined;
var ctrl_used: virtio.UsedRing(queue_size) align(4) = undefined;

var tx_descs: [queue_size]virtio.Desc align(16) = undefined;
var tx_avail: virtio.AvailRing(queue_size) align(2) = undefined;
var tx_used: virtio.UsedRing(queue_size) align(4) = undefined;

// ── VirtIO Sound message structures ──────────────────────────────────────────

/// Generic response header returned by the device for all control commands.
const SndHdr = extern struct {
    /// Response status code; virtio_snd_s_ok (0x8000) indicates success.
    code: u32,
};

/// Request header for PCM stream commands that target a specific stream.
const SndPcmHdr = extern struct {
    /// Command code (e.g. PCM_PREPARE, PCM_START).
    code: u32,
    /// Index of the PCM stream to operate on.
    stream_id: u32,
};

/// PCM_SET_PARAMS request: configures the stream's format before prepare/start.
const SndPcmSetParams = extern struct {
    /// Command code; must be virtio_snd_r_pcm_set_params.
    code: u32,
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
    /// Sample format code (e.g. virtio_snd_pcm_fmt_s16).
    format: u8,
    /// Sample rate code (e.g. virtio_snd_pcm_rate_44100).
    rate: u8,
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
    /// Completion status; virtio_snd_s_ok (0x8000) indicates success.
    status: u32,
    /// Estimated device playback latency in bytes at the time of completion.
    latency_bytes: u32,
};

comptime {
    std.debug.assert(@sizeOf(SndPcmSetParams) == 24);
}

// ── Queue helpers ─────────────────────────────────────────────────────────────

/// Zero all virtqueue memory before handing addresses to the device.
fn zeroQueues() void {
    ctrl_descs = std.mem.zeroes(@TypeOf(ctrl_descs));
    ctrl_avail = std.mem.zeroes(@TypeOf(ctrl_avail));
    ctrl_used = std.mem.zeroes(@TypeOf(ctrl_used));
    tx_descs = std.mem.zeroes(@TypeOf(tx_descs));
    tx_avail = std.mem.zeroes(@TypeOf(tx_avail));
    tx_used = std.mem.zeroes(@TypeOf(tx_used));
}

// ── Control queue submit (polling, chain always starts at desc 0) ─────────────

/// Submit a two-descriptor request/response chain on the control queue and
/// spin until the device writes a completion entry to the used ring.
fn ctrlSubmit(
    req: []const u8,
    resp: []u8,
    caps: *const virtio.Caps,
    ctrl_notify_off: u16,
) void {
    ctrl_descs[0] = .{
        .addr = @intFromPtr(req.ptr),
        .len = @intCast(req.len),
        .flags = virtio.virtq_desc_f_next,
        .next = 1,
    };
    ctrl_descs[1] = .{
        .addr = @intFromPtr(resp.ptr),
        .len = @intCast(resp.len),
        .flags = virtio.virtq_desc_f_write,
        .next = 0,
    };

    const idx = ctrl_avail.idx;
    ctrl_avail.ring[idx % queue_size] = 0;
    @as(*volatile u16, &ctrl_avail.idx).* = idx +% 1;

    virtio.kickQueue(caps, ctrl_notify_off, controlq);

    while (@as(*volatile u16, &ctrl_used.idx).* != idx +% 1)
        std.atomic.spinLoopHint();
}

// ── TX queue submit (polling, chain always starts at desc 0) ──────────────────

/// Submit a three-descriptor xfer-header/pcm-data/status chain on the TX queue
/// and spin until the device writes a completion entry to the used ring.
fn txSubmit(
    xfer: *const SndPcmXfer,
    pcm: []const u8,
    status: *SndPcmStatus,
    caps: *const virtio.Caps,
    tx_notify_off: u16,
) void {
    tx_descs[0] = .{
        .addr = @intFromPtr(xfer),
        .len = @sizeOf(SndPcmXfer),
        .flags = virtio.virtq_desc_f_next,
        .next = 1,
    };
    tx_descs[1] = .{
        .addr = @intFromPtr(pcm.ptr),
        .len = @intCast(pcm.len),
        .flags = virtio.virtq_desc_f_next,
        .next = 2,
    };
    tx_descs[2] = .{
        .addr = @intFromPtr(status),
        .len = @sizeOf(SndPcmStatus),
        .flags = virtio.virtq_desc_f_write,
        .next = 0,
    };

    const idx = tx_avail.idx;
    tx_avail.ring[idx % queue_size] = 0;
    @as(*volatile u16, &tx_avail.idx).* = idx +% 1;

    virtio.kickQueue(caps, tx_notify_off, txq);

    while (@as(*volatile u16, &tx_used.idx).* != idx +% 1)
        std.atomic.spinLoopHint();
}

// ── Public API ────────────────────────────────────────────────────────────────

pub const Error = error{
    NoDevice,
    NoCaps,
    FeaturesRejected,
    SetParamsFailed,
    PrepareFailed,
    StartFailed,
    TxFailed,
} || wav.Error;

/// Parse `data` as a WAV file and stream it through the VirtIO sound device.
pub fn play(data: []const u8) Error!void {
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
    const cmd = pci.configRead32(found.bus, found.dev, 0, 0x04) & 0xFFFF;
    pci.configWrite32(found.bus, found.dev, 0, 0x04, cmd | 0x0006);

    const caps = virtio.walkCaps(found.bus, found.dev) orelse return error.NoCaps;
    const common = caps.common;

    // ── Device initialisation sequence (§3.1) ────────────────────────────────
    common.device_status = 0; // reset
    common.device_status = virtio.status_acknowledge | virtio.status_driver;

    // Negotiate VIRTIO_F_VERSION_1 (feature bit 32 → select=1, bit 0).
    common.driver_feature_select = 0;
    common.driver_feature = 0;
    common.driver_feature_select = 1;
    common.driver_feature = virtio.virtio_f_version_1;
    common.device_status = virtio.status_acknowledge | virtio.status_driver | virtio.status_features_ok;
    if (common.device_status & virtio.status_features_ok == 0) {
        log.err("device rejected VIRTIO_F_VERSION_1", .{});
        return error.FeaturesRejected;
    }

    // ── Queue setup ───────────────────────────────────────────────────────────
    zeroQueues();
    const ctrl_notify_off = virtio.setupQueue(common, controlq, queue_size, @intFromPtr(&ctrl_descs), @intFromPtr(&ctrl_avail), @intFromPtr(&ctrl_used));
    const tx_notify_off = virtio.setupQueue(common, txq, queue_size, @intFromPtr(&tx_descs), @intFromPtr(&tx_avail), @intFromPtr(&tx_used));
    log.debug("controlq notify_off={} txq notify_off={}", .{ ctrl_notify_off, tx_notify_off });

    common.device_status = virtio.status_acknowledge | virtio.status_driver | virtio.status_features_ok | virtio.status_driver_ok;

    // ── PCM_SET_PARAMS ────────────────────────────────────────────────────────
    const fmt_code: u8 = if (fmt.bits_per_sample == 8) virtio_snd_pcm_fmt_u8 else virtio_snd_pcm_fmt_s16;
    const rate_code: u8 = switch (fmt.sample_rate) {
        8000 => virtio_snd_pcm_rate_8000,
        11025 => virtio_snd_pcm_rate_11025,
        16000 => virtio_snd_pcm_rate_16000,
        22050 => virtio_snd_pcm_rate_22050,
        32000 => virtio_snd_pcm_rate_32000,
        44100 => virtio_snd_pcm_rate_44100,
        48000 => virtio_snd_pcm_rate_48000,
        else => virtio_snd_pcm_rate_44100,
    };
    const frame_bytes: u32 = @as(u32, fmt.channels) * (fmt.bits_per_sample / 8);
    const period_bytes: u32 = 1024 * frame_bytes;
    var set_params = SndPcmSetParams{
        .code = virtio_snd_r_pcm_set_params,
        .stream_id = 0,
        .buffer_bytes = period_bytes * 4,
        .period_bytes = period_bytes,
        .features = 0,
        .channels = @intCast(fmt.channels),
        .format = fmt_code,
        .rate = rate_code,
        .padding = 0,
    };
    var ctrl_resp = SndHdr{ .code = 0 };
    ctrlSubmit(std.mem.asBytes(&set_params), std.mem.asBytes(&ctrl_resp), &caps, ctrl_notify_off);
    log.info("SET_PARAMS resp=0x{X}", .{ctrl_resp.code});
    if (ctrl_resp.code != virtio_snd_s_ok) return error.SetParamsFailed;

    // ── PCM_PREPARE ───────────────────────────────────────────────────────────
    var prepare_req = SndPcmHdr{ .code = virtio_snd_r_pcm_prepare, .stream_id = 0 };
    ctrl_resp.code = 0;
    ctrlSubmit(std.mem.asBytes(&prepare_req), std.mem.asBytes(&ctrl_resp), &caps, ctrl_notify_off);
    log.info("PREPARE resp=0x{X}", .{ctrl_resp.code});
    if (ctrl_resp.code != virtio_snd_s_ok) return error.PrepareFailed;

    // ── PCM_START ─────────────────────────────────────────────────────────────
    var start_req = SndPcmHdr{ .code = virtio_snd_r_pcm_start, .stream_id = 0 };
    ctrl_resp.code = 0;
    ctrlSubmit(std.mem.asBytes(&start_req), std.mem.asBytes(&ctrl_resp), &caps, ctrl_notify_off);
    log.info("START resp=0x{X}", .{ctrl_resp.code});
    if (ctrl_resp.code != virtio_snd_s_ok) return error.StartFailed;

    // ── TX: stream PCM data one period at a time ──────────────────────────────
    const xfer = SndPcmXfer{ .stream_id = 0 };
    var tx_status = SndPcmStatus{ .status = 0, .latency_bytes = 0 };
    var offset: usize = 0;
    var chunk: u32 = 0;
    const total_chunks = (parsed.pcm.len + period_bytes - 1) / period_bytes;
    while (offset < parsed.pcm.len) {
        const end = @min(offset + period_bytes, parsed.pcm.len);
        txSubmit(&xfer, parsed.pcm[offset..end], &tx_status, &caps, tx_notify_off);
        if (tx_status.status != virtio_snd_s_ok) {
            log.err("TX chunk {} failed: status=0x{X}", .{ chunk, tx_status.status });
            return error.TxFailed;
        }
        offset = end;
        chunk += 1;
        if (chunk % 256 == 0)
            log.debug("TX {}/{} chunks", .{ chunk, total_chunks });
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
    std.mem.writeInt(u32, wav_buf[16..20], 16, .little);    // fmt chunk size
    std.mem.writeInt(u16, wav_buf[20..22], 1, .little);     // PCM
    std.mem.writeInt(u16, wav_buf[22..24], 1, .little);     // mono
    std.mem.writeInt(u32, wav_buf[24..28], 44100, .little); // sample rate
    std.mem.writeInt(u32, wav_buf[28..32], 88200, .little); // byte rate
    std.mem.writeInt(u16, wav_buf[32..34], 2, .little);     // block align
    std.mem.writeInt(u16, wav_buf[34..36], 16, .little);    // bits per sample
    @memcpy(wav_buf[36..40], "data");
    std.mem.writeInt(u32, wav_buf[40..44], pcm_len, .little);
    @memset(wav_buf[44..], 0);

    try play(&wav_buf);
}
