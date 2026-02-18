//! A simple logging utility for freestanding Zig environments.
//! Provides functions to log messages at various levels (info, warn, error, fatal).
//! Logs are written to a serial port for output.
//! Designed to work in both freestanding and hosted environments.
//! In hosted environments, it falls back to std.log.
//!

const builtin = @import("builtin");
const std = @import("std");

const serial = @import("serial.zig");
const sync = @import("sync.zig");

// Directly write to serial console, no need to buffer.
// TODO: Consider buffering if performance becomes an issue.
const serial_writer_buffer: [0]u8 = undefined;
var serial_writer = serial.writer(&serial_writer_buffer);

pub fn defaultLog(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    if (comptime builtin.os.tag != .freestanding) return std.log.defaultLog(
        message_level,
        scope,
        format,
        args,
    );

    const locked = serial.lock.tryLock(1_000_000_000);
    defer serial.lock.unlock();
    serial.writeString(comptime message_level.asText());
    if (scope != .default) {
        serial.writeString(" (");
        serial.writeString(@tagName(scope));
        serial.writeString(")");
    }
    serial.writeString(": ");
    if (!locked) {
        serial.writeString("[LOG LOCK TIMEOUT] ");
    }

    serial_writer.print(format, args) catch {
        serial.writeString("[WRITE ERROR] ");
        serial.writeString(format);
    };
    serial.writeString("\n");
}
