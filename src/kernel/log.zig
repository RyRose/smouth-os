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

pub var test_name: ?[]const u8 = null;

pub fn defaultLog(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    if (comptime builtin.os.tag != .freestanding) {
        if (scope == .testing) {
            std.debug.print(format, args);
        } else {
            std.log.defaultLog(
                message_level,
                scope,
                format,
                args,
            );
        }
        return;
    }

    const locked = serial.lock.tryLock(1_000_000_000);
    defer serial.lock.unlock();

    serial.write(comptime message_level.asText());
    if (scope != .default) {
        serial.write(" (");
        serial.write(@tagName(scope));
        serial.write(")");
    }
    if (test_name) |name| {
        serial.write(" (");
        serial.write(name);
        serial.write(")");
    }
    serial.write(": ");
    if (!locked) {
        serial.write("[LOG LOCK TIMEOUT] ");
    }

    serial.writer.print(format, args) catch {
        serial.write("[WRITE ERROR] ");
        serial.write(format);
    };
    serial.write("\n");
}
