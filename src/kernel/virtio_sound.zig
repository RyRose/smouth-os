//! VirtIO Sound playback using the active architecture's VirtIO transport.

const builtin = @import("builtin");
const std = @import("std");

const arch = @import("os").arch;
const virtio = @import("virtio.zig");
const wav = @import("wav.zig");

const log = std.log.scoped(.virtio_sound);

/// VirtIO sound control command codes (§5.14.6.8.1).
const CommandCode = enum(u32) {
    /// Configure PCM stream parameters.
    set_params = 0x0101,
    /// Prepare a PCM stream.
    prepare = 0x0102,
    /// Start PCM stream playback.
    start = 0x0104,
};

/// VirtIO sound response status codes (§5.14.6.8.1).
const StatusCode = enum(u32) {
    /// Command completed successfully.
    ok = 0x8000,
    _,
};

/// VirtIO sound queue indices (§5.14.2).
const Queue = enum(u16) {
    /// Control request and response queue.
    control = 0,
    /// PCM playback queue.
    tx = 2,
};

/// VirtIO PCM sample-format values (§5.14.6.6.1).
const PcmFmt = enum(u8) {
    /// Unsigned 8-bit PCM.
    u8 = 4,
    /// Signed 16-bit little-endian PCM.
    s16 = 5,
};

/// VirtIO PCM sample-rate values (§5.14.6.6.2).
const PcmRate = enum(u8) {
    @"8000" = 1,
    @"11025" = 2,
    @"16000" = 3,
    @"22050" = 4,
    @"32000" = 5,
    @"44100" = 6,
    @"48000" = 7,
};

/// Descriptor count for each statically allocated VirtIO sound queue.
const queue_size: u16 = 64;

/// Control queue used for commands and responses.
var ctrl_queue: virtio.Virtqueue(queue_size) = .{};
/// PCM transmit queue used for playback frames.
var tx_queue: virtio.Virtqueue(queue_size) = .{};

/// Generic response header returned by control commands.
const SndHdr = extern struct {
    /// Device response status.
    code: StatusCode,
};

/// Request header for commands directed at a PCM stream.
const SndPcmHdr = extern struct {
    /// PCM command code.
    code: CommandCode,
    /// Target stream identifier.
    stream_id: u32,
};

/// PCM_SET_PARAMS request (§5.14.6.8.2).
const SndPcmSetParams = extern struct {
    /// PCM_SET_PARAMS command code.
    code: CommandCode,
    /// Target stream identifier.
    stream_id: u32,
    /// Total device buffer size in bytes.
    buffer_bytes: u32,
    /// Playback period size in bytes.
    period_bytes: u32,
    /// Optional feature flags.
    features: u32,
    /// Number of PCM channels.
    channels: u8,
    /// PCM sample format.
    format: PcmFmt,
    /// PCM sample rate.
    rate: PcmRate,
    /// Reserved zero byte.
    padding: u8,
};

/// Header prepended to each PCM transmit buffer.
const SndPcmXfer = extern struct {
    /// Stream receiving PCM frames.
    stream_id: u32,
};

/// Status appended by the device to each PCM transmit request.
const SndPcmStatus = extern struct {
    /// Device completion status.
    status: StatusCode,
    /// Estimated playback latency in bytes.
    latency_bytes: u32,
};

comptime {
    std.debug.assert(@sizeOf(SndPcmSetParams) == 24);
}

/// Submits a control request and waits for its response.
fn ctrlSubmit(transport: anytype, req: []const u8, resp: []u8) void {
    ctrl_queue.submit(transport, &.{
        .{ .addr = @intFromPtr(req.ptr), .len = @intCast(req.len), .flags = .{ .next = true }, .next = 1 },
        .{ .addr = @intFromPtr(resp.ptr), .len = @intCast(resp.len), .flags = .{ .write = true }, .next = 0 },
    });
}

/// Submits one PCM period and waits for the completion status.
fn txSubmit(
    transport: anytype,
    xfer: *const SndPcmXfer,
    pcm: []const u8,
    status: *SndPcmStatus,
) void {
    tx_queue.submit(transport, &.{
        .{ .addr = @intFromPtr(xfer), .len = @sizeOf(SndPcmXfer), .flags = .{ .next = true }, .next = 1 },
        .{ .addr = @intFromPtr(pcm.ptr), .len = @intCast(pcm.len), .flags = .{ .next = true }, .next = 2 },
        .{ .addr = @intFromPtr(status), .len = @sizeOf(SndPcmStatus), .flags = .{ .write = true }, .next = 0 },
    });
}

/// Converts a WAV sample rate to its VirtIO PCM enumeration.
fn pcmRate(sample_rate: u32) !PcmRate {
    return switch (sample_rate) {
        8000 => .@"8000",
        11025 => .@"11025",
        16000 => .@"16000",
        22050 => .@"22050",
        32000 => .@"32000",
        44100 => .@"44100",
        48000 => .@"48000",
        else => error.UnsupportedSampleRate,
    };
}

/// Negotiates VirtIO version 1 and prepares the sound control and TX queues.
fn initialize(transport: anytype) !void {
    transport.reset();
    transport.setStatus(.{ .acknowledge = true, .driver = true });

    const high_features = transport.deviceFeatures(.high);
    if ((high_features & virtio.feature_version_1) == 0) return error.MissingVersion1;
    transport.driverFeatures(.low, 0);
    transport.driverFeatures(.high, virtio.feature_version_1);

    transport.setStatus(.{ .acknowledge = true, .driver = true, .features_ok = true });
    if (!transport.status().features_ok) return error.FeaturesRejected;

    try ctrl_queue.setup(transport, @intFromEnum(Queue.control));
    try tx_queue.setup(transport, @intFromEnum(Queue.tx));
    transport.setStatus(.{
        .acknowledge = true,
        .driver = true,
        .features_ok = true,
        .driver_ok = true,
    });
}

/// Streams parsed WAV data over an initialized architecture-specific transport.
fn playWithTransport(data: []const u8, transport: anytype) !void {
    const parsed = try wav.parse(data);
    const fmt = parsed.fmt;
    if (fmt.channels == 0 or fmt.channels > std.math.maxInt(u8)) return error.UnsupportedChannels;

    const format: PcmFmt = switch (fmt.bits_per_sample) {
        8 => .u8,
        16 => .s16,
        else => return error.UnsupportedFormat,
    };
    const rate = try pcmRate(fmt.sample_rate);
    const frame_bytes = @as(usize, fmt.channels) * (@as(usize, fmt.bits_per_sample) / 8);
    const period_bytes = 1024 * frame_bytes;
    if (period_bytes > std.math.maxInt(u32)) return error.UnsupportedFormat;

    log.info("WAV: {}Hz {}ch {}-bit, {} bytes PCM", .{
        fmt.sample_rate,
        fmt.channels,
        fmt.bits_per_sample,
        parsed.pcm.len,
    });

    try initialize(transport);

    var set_params = SndPcmSetParams{
        .code = .set_params,
        .stream_id = 0,
        .buffer_bytes = @intCast(period_bytes * 4),
        .period_bytes = @intCast(period_bytes),
        .features = 0,
        .channels = @intCast(fmt.channels),
        .format = format,
        .rate = rate,
        .padding = 0,
    };
    var ctrl_resp = SndHdr{ .code = .ok };
    ctrlSubmit(transport, std.mem.asBytes(&set_params), std.mem.asBytes(&ctrl_resp));
    if (ctrl_resp.code != .ok) return error.SetParamsFailed;

    var prepare_req = SndPcmHdr{ .code = .prepare, .stream_id = 0 };
    ctrl_resp.code = .ok;
    ctrlSubmit(transport, std.mem.asBytes(&prepare_req), std.mem.asBytes(&ctrl_resp));
    if (ctrl_resp.code != .ok) return error.PrepareFailed;

    var start_req = SndPcmHdr{ .code = .start, .stream_id = 0 };
    ctrl_resp.code = .ok;
    ctrlSubmit(transport, std.mem.asBytes(&start_req), std.mem.asBytes(&ctrl_resp));
    if (ctrl_resp.code != .ok) return error.StartFailed;

    const xfer = SndPcmXfer{ .stream_id = 0 };
    var tx_status = SndPcmStatus{ .status = .ok, .latency_bytes = 0 };
    var offset: usize = 0;
    var chunk: usize = 0;
    const total_chunks = (parsed.pcm.len + period_bytes - 1) / period_bytes;
    while (offset < parsed.pcm.len) {
        const end = @min(offset + period_bytes, parsed.pcm.len);
        txSubmit(transport, &xfer, parsed.pcm[offset..end], &tx_status);
        if (tx_status.status != .ok) return error.TxFailed;
        offset = end;
        chunk += 1;
        if (chunk % 256 == 0) log.debug("TX {}/{} chunks", .{ chunk, total_chunks });
    }
    log.info("playback complete ({} chunks)", .{chunk});
}

/// Parses and streams `data` through the active architecture's VirtIO sound device.
pub fn play(data: []const u8) !void {
    var transport = try arch.self.virtio.findSoundDevice();
    return playWithTransport(data, &transport);
}

test "VirtIO sound structure sizes" {
    try std.testing.expectEqual(4, @sizeOf(SndHdr));
    try std.testing.expectEqual(8, @sizeOf(SndPcmHdr));
    try std.testing.expectEqual(24, @sizeOf(SndPcmSetParams));
    try std.testing.expectEqual(4, @sizeOf(SndPcmXfer));
    try std.testing.expectEqual(8, @sizeOf(SndPcmStatus));
}

test "pcmRate rejects unsupported rates" {
    try std.testing.expectError(error.UnsupportedSampleRate, pcmRate(12345));
}

test "play succeeds with minimal silent WAV on x86" {
    if (comptime builtin.cpu.arch != .x86) return error.SkipZigTest;

    const pcm_len = 1024 * 2;
    var wav_buf: [44 + pcm_len]u8 = undefined;
    @memcpy(wav_buf[0..4], "RIFF");
    std.mem.writeInt(u32, wav_buf[4..8], wav_buf.len - 8, .little);
    @memcpy(wav_buf[8..12], "WAVE");
    @memcpy(wav_buf[12..16], "fmt ");
    std.mem.writeInt(u32, wav_buf[16..20], 16, .little);
    std.mem.writeInt(u16, wav_buf[20..22], 1, .little);
    std.mem.writeInt(u16, wav_buf[22..24], 1, .little);
    std.mem.writeInt(u32, wav_buf[24..28], 44100, .little);
    std.mem.writeInt(u32, wav_buf[28..32], 88200, .little);
    std.mem.writeInt(u16, wav_buf[32..34], 2, .little);
    std.mem.writeInt(u16, wav_buf[34..36], 16, .little);
    @memcpy(wav_buf[36..40], "data");
    std.mem.writeInt(u32, wav_buf[40..44], pcm_len, .little);
    @memset(wav_buf[44..], 0);

    try play(&wav_buf);
}
