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
pub const Fmt = struct {
    /// Number of audio channels (e.g. 1 for mono, 2 for stereo).
    channels: u16,
    /// Sample rate in samples per second (e.g. 44100).
    sample_rate: u32,
    /// Bits per sample (e.g. 8 or 16).
    bits_per_sample: u16,
};

/// Parsed WAV contents: format and a slice of raw PCM sample bytes.
pub const Wav = struct {
    fmt: Fmt,
    /// Raw PCM sample bytes from the "data" chunk. For 8-bit audio, each byte is an unsigned
    /// sample value in the range [0, 255] with 128 as the zero point. For 16-bit audio, each
    /// pair of bytes is a signed little-endian sample value in the range [-32768, 32767] with 0 as
    /// the zero point.
    pcm: []const u8,
};

/// Helper to read a little-endian u32 from `data` at `offset`, with bounds
/// checking.
fn readU32(data: []const u8, offset: usize) Error!u32 {
    if (offset + 4 > data.len) return error.Truncated;
    return std.mem.readInt(u32, data[offset..][0..4], .little);
}

/// Helper to read a little-endian u16 from `data` at `offset`, with bounds
/// checking.
fn readU16(data: []const u8, offset: usize) Error!u16 {
    if (offset + 2 > data.len) return error.Truncated;
    return std.mem.readInt(u16, data[offset..][0..2], .little);
}

/// Parse the RIFF/WAVE header from `data` and return format + PCM slice.
/// Scans all chunks so extra metadata chunks between "fmt " and "data" are
/// skipped safely.
pub fn parse(data: []const u8) Error!Wav {
    if (data.len < 12) return error.Truncated;
    if (!std.mem.eql(u8, data[0..4], "RIFF")) return error.InvalidRiff;
    if (!std.mem.eql(u8, data[8..12], "WAVE")) return error.InvalidWave;

    // Start of first chunk is always at offset 12, right after the RIFF header.
    var pos: usize = 12;
    var fmt: ?Fmt = null;
    var pcm: ?[]const u8 = null;

    // Each chunk has an 8-byte header: 4-byte tag + 4-byte size, followed by `size`
    // bytes of payload. Chunks are padded to even byte boundaries, so the next chunk
    // starts at offset `pos + 8 + size`, rounded up to the next even number.
    //
    // Tag is a 4-byte ASCII string (e.g. "fmt ", "data", "LIST", etc.). Size is the length of
    // the payload in bytes, not including the 8-byte header or any padding. Payload is the
    // raw bytes of the chunk, whose format depends on the tag. The "fmt " chunk contains
    // the audio format parameters, and the "data" chunk contains the raw PCM sample bytes.
    //
    while (pos + 8 <= data.len) {
        const tag = data[pos..][0..4];
        const size = try readU32(data, pos + 4);
        const chunk_start = pos + 8;
        const chunk_end = chunk_start + size;
        if (chunk_end > data.len) return error.Truncated;

        if (std.mem.eql(u8, tag, "fmt ")) {
            if (size < 16) return error.MissingFmt;
            const audio_format = try readU16(data, chunk_start);
            if (audio_format != 1) return error.UnsupportedFormat;
            const channels = try readU16(data, chunk_start + 2);
            const sample_rate = try readU32(data, chunk_start + 4);
            const bits_per_sample = try readU16(data, chunk_start + 14);
            if (bits_per_sample != 8 and bits_per_sample != 16) return error.UnsupportedFormat;
            fmt = .{
                .channels = channels,
                .sample_rate = sample_rate,
                .bits_per_sample = bits_per_sample,
            };
        } else if (std.mem.eql(u8, tag, "data")) {
            pcm = data[chunk_start..chunk_end];
        }

        // Chunks are padded to even byte boundaries.
        pos = chunk_end + (size & 1);
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
