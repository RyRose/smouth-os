//! RIFF/WAVE parser.
//!
//! Parses a RIFF/WAVE file (PCM format, 8-bit unsigned or 16-bit signed
//! little-endian, any sample rate, any channel count) and returns the format
//! parameters and a slice of the raw PCM sample bytes.
//!
//! RIFF: https://en.wikipedia.org/wiki/Resource_Interchange_File_Format
//! WAV: https://en.wikipedia.org/wiki/WAV
//! PCM: https://en.wikipedia.org/wiki/Pulse-code_modulation
//!

const std = @import("std");

pub const Error = error{
    /// The file does not begin with the "RIFF" magic bytes.
    InvalidRiff,
    /// The RIFF form type is not "WAVE".
    InvalidWave,
    /// No "fmt " chunk was found, or it is smaller than 16 bytes.
    MissingFmt,
    /// The audio format is not PCM (format tag != 1), or bits-per-sample is
    /// not 8 or 16.
    UnsupportedFormat,
    /// No "data" chunk was found.
    MissingData,
    /// The file is shorter than expected based on its internal size fields.
    Truncated,
};

/// WAV format parameters extracted from the "fmt " chunk.
pub const Format = struct {
    /// Number of audio channels (e.g. 1 for mono, 2 for stereo).
    channels: u16,
    /// Sample rate in samples per second (e.g. 44100).
    sample_rate: u32,
    /// Bits per sample (e.g. 8 or 16).
    bits_per_sample: u16,
};

/// Parsed WAV contents: format and a slice of raw PCM sample bytes.
pub const Wav = struct {
    fmt: Format,
    /// Raw PCM sample bytes from the "data" chunk. For 8-bit audio, each byte is an unsigned
    /// sample value in the range [0, 255] with 128 as the zero point. For 16-bit audio, each
    /// pair of bytes is a signed little-endian sample value in the range [-32768, 32767] with 0 as
    /// the zero point.
    pcm: []const u8,
};

/// Parse the RIFF/WAVE header from `data` and return format + PCM slice.
/// Scans all chunks so extra metadata chunks between "fmt " and "data" are
/// skipped safely.
pub fn parse(data: []const u8) Error!Wav {
    var r: std.Io.Reader = .fixed(data);

    // Read the RIFF file header: "RIFF", 4-byte file size (ignored), "WAVE".
    const riff = r.takeArray(4) catch return error.Truncated;
    if (!std.mem.eql(u8, riff, "RIFF")) return error.InvalidRiff;
    r.discardAll(4) catch return error.Truncated;
    const wave = r.takeArray(4) catch return error.Truncated;
    if (!std.mem.eql(u8, wave, "WAVE")) return error.InvalidWave;

    var fmt: ?Format = null;
    var pcm: ?[]const u8 = null;

    // Each chunk has an 8-byte header: 4-byte tag + 4-byte size, followed by `size`
    // bytes of payload. Chunks are padded to even byte boundaries.
    while (true) {
        const tag = r.takeArray(4) catch break;
        const size = r.takeInt(u32, .little) catch break;

        switch (std.mem.readInt(u32, tag, .big)) {
            std.mem.readInt(u32, "fmt ", .big) => {
                if (size < 16) return error.MissingFmt;
                const audio_format = r.takeInt(u16, .little) catch return error.Truncated;
                if (audio_format != 1) return error.UnsupportedFormat;
                const channels = r.takeInt(u16, .little) catch return error.Truncated;
                const sample_rate = r.takeInt(u32, .little) catch return error.Truncated;
                r.discardAll(6) catch return error.Truncated; // byte_rate (4) + block_align (2)
                const bits_per_sample = r.takeInt(u16, .little) catch return error.Truncated;
                if (bits_per_sample != 8 and bits_per_sample != 16) return error.UnsupportedFormat;
                fmt = .{ .channels = channels, .sample_rate = sample_rate, .bits_per_sample = bits_per_sample };
                r.discardAll(size - 16 + (size & 1)) catch return error.Truncated;
            },
            std.mem.readInt(u32, "data", .big) => {
                if (r.seek + @as(usize, size) > data.len) return error.Truncated;
                pcm = data[r.seek..][0..size];
                r.discardAll(size + (size & 1)) catch return error.Truncated;
            },
            else => r.discardAll(size + (size & 1)) catch return error.Truncated,
        }
    }

    if (fmt == null) return error.MissingFmt;
    if (pcm == null) return error.MissingData;
    return .{ .fmt = fmt.?, .pcm = pcm.? };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

/// Minimal valid 8-bit mono WAV at 8000 Hz with four silent (0x80) samples.
const test_wav_8bit_mono = blk: {
    // fmt chunk payload (16 bytes)
    const fmt_payload = [16]u8{
        0x01, 0x00, // audio format: PCM
        0x01, 0x00, // channels: 1
        0x40, 0x1F, 0x00, 0x00, // sample rate: 8000
        0x40, 0x1F, 0x00, 0x00, // byte rate: 8000
        0x01, 0x00, // block align: 1
        0x08, 0x00, // bits per sample: 8
    };
    // data chunk payload (4 bytes)
    const data_payload = [4]u8{ 0x80, 0x80, 0x80, 0x80 };
    // Full file size = 4 (WAVE) + 8 (fmt hdr) + 16 (fmt) + 8 (data hdr) + 4 (data) = 40
    const file_size = [4]u8{ 0x24, 0x00, 0x00, 0x00 }; // 36
    break :blk [_]u8{
        'R', 'I', 'F', 'F',
    } ++ file_size ++ [_]u8{
        'W', 'A', 'V', 'E',
        'f', 'm', 't', ' ',
        0x10, 0x00, 0x00, 0x00, // fmt chunk size: 16
    } ++ fmt_payload ++ [_]u8{
        'd', 'a', 't', 'a',
        0x04, 0x00, 0x00, 0x00, // data chunk size: 4
    } ++ data_payload;
};

test "parse 8-bit mono WAV" {
    const wav = try parse(&test_wav_8bit_mono);
    try std.testing.expectEqual(@as(u16, 1), wav.fmt.channels);
    try std.testing.expectEqual(@as(u32, 8000), wav.fmt.sample_rate);
    try std.testing.expectEqual(@as(u16, 8), wav.fmt.bits_per_sample);
    try std.testing.expectEqual(@as(usize, 4), wav.pcm.len);
    try std.testing.expectEqualSlices(u8, &.{ 0x80, 0x80, 0x80, 0x80 }, wav.pcm);
}

test "parse 16-bit stereo WAV" {
    // fmt chunk payload (16 bytes): 16-bit stereo at 44100 Hz
    const fmt_payload = [16]u8{
        0x01, 0x00, // PCM
        0x02, 0x00, // channels: 2
        0x44, 0xAC, 0x00, 0x00, // sample rate: 44100
        0x10, 0xB1, 0x02, 0x00, // byte rate: 176400
        0x04, 0x00, // block align: 4
        0x10, 0x00, // bits per sample: 16
    };
    const data_payload = [4]u8{ 0x00, 0x00, 0xFF, 0x7F }; // L=0, R=32767
    const file_size = [4]u8{ 0x24, 0x00, 0x00, 0x00 };
    const wav_bytes = [_]u8{
        'R', 'I', 'F', 'F',
    } ++ file_size ++ [_]u8{
        'W',  'A',  'V',  'E',
        'f',  'm',  't',  ' ',
        0x10, 0x00, 0x00, 0x00,
    } ++ fmt_payload ++ [_]u8{
        'd',  'a',  't',  'a',
        0x04, 0x00, 0x00, 0x00,
    } ++ data_payload;

    const wav = try parse(&wav_bytes);
    try std.testing.expectEqual(@as(u16, 2), wav.fmt.channels);
    try std.testing.expectEqual(@as(u32, 44100), wav.fmt.sample_rate);
    try std.testing.expectEqual(@as(u16, 16), wav.fmt.bits_per_sample);
    try std.testing.expectEqual(@as(usize, 4), wav.pcm.len);
}

test "parse returns InvalidRiff for bad magic" {
    const bad = [_]u8{ 'X', 'X', 'X', 'X' } ++ [_]u8{0} ** 8;
    try std.testing.expectError(error.InvalidRiff, parse(&bad));
}

test "parse returns InvalidWave for wrong form type" {
    const bad = [_]u8{ 'R', 'I', 'F', 'F', 0x00, 0x00, 0x00, 0x00, 'X', 'X', 'X', 'X' };
    try std.testing.expectError(error.InvalidWave, parse(&bad));
}

test "parse returns UnsupportedFormat for non-PCM" {
    const fmt_payload = [16]u8{
        0x03, 0x00, // audio format: IEEE float (not PCM)
        0x01, 0x00,
        0x40, 0x1F,
        0x00, 0x00,
        0x40, 0x1F,
        0x00, 0x00,
        0x01, 0x00,
        0x20, 0x00,
    };
    const wav_bytes = [_]u8{
        'R',  'I',  'F',  'F',  0x24, 0x00, 0x00, 0x00,
        'W',  'A',  'V',  'E',  'f',  'm',  't',  ' ',
        0x10, 0x00, 0x00, 0x00,
    } ++ fmt_payload ++ [_]u8{
        'd',  'a',  't',  'a',  0x04, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
    };
    try std.testing.expectError(error.UnsupportedFormat, parse(&wav_bytes));
}

test "parse returns MissingData when data chunk absent" {
    // Valid fmt chunk but no data chunk — stop after fmt
    const fmt_payload = [16]u8{
        0x01, 0x00, 0x01, 0x00, 0x40, 0x1F, 0x00, 0x00,
        0x40, 0x1F, 0x00, 0x00, 0x01, 0x00, 0x08, 0x00,
    };
    const wav_bytes = [_]u8{
        'R',  'I',  'F',  'F',  0x18, 0x00, 0x00, 0x00,
        'W',  'A',  'V',  'E',  'f',  'm',  't',  ' ',
        0x10, 0x00, 0x00, 0x00,
    } ++ fmt_payload;
    try std.testing.expectError(error.MissingData, parse(&wav_bytes));
}
