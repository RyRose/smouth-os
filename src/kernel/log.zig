//! A simple logging utility for freestanding Zig environments.
//! Provides functions to log messages at various levels (info, warn, error, fatal).
//! Logs are written to a serial port for output.
//! Designed to work in both freestanding and hosted environments.
//! In hosted environments, it falls back to std.log.
//!

const std = @import("std");
const builtin = @import("builtin");

const serial = @import("serial.zig");

/// The name of the currently running test, if any.
/// This is used to include the test name in log messages when running tests.
/// Set by testboot.zig when running tests, and null otherwise.
pub var test_name: ?[]const u8 = null;

/// Logs a message with the given level and scope.
/// In freestanding environments, logs are written to the serial port.
/// In hosted environments, it falls back to std.log.
pub fn defaultLog(
    comptime message_level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    if (comptime builtin.os.tag != .freestanding) {
        std.log.defaultLog(
            message_level,
            scope,
            format,
            args,
        );
        return;
    }
    _ = serial.lock.tryLock(1_000_000_000);
    defer serial.lock.unlock();

    std.log.defaultLogFileTerminal(message_level, scope, format, args, serial.tty) catch {};
}
