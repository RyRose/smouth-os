const std = @import("std");

const sync = @import("sync.zig");
const serial = @import("serial.zig");

/// A simple log buffer protected by a spinlock.
/// This can be used to store log messages before flushing them to the serial port.
var log_buffer = sync.SpinLock([1024]u8).init([_]u8{0} ** 1024);

/// Internal function to write formatted log messages to the serial port.
fn write(comptime fmt: []const u8, args: anytype) !void {
    const buf = try std.fmt.bufPrint(&log_buffer.value, fmt, args);
    serial.writeString(buf);
}

/// Log an informational message.
/// Acquires the lock on the log buffer before logging.
pub fn info(msg: []const u8) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    serial.writeString("INFO: ");
    serial.writeString(msg);
    serial.writeString("\n");
}

/// Log an informational message with formatting.
/// Acquires the lock on the log buffer before logging.
pub fn infoF(comptime fmt: []const u8, args: anytype) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    serial.writeString("INFO: ");
    try write(fmt, args);
    serial.writeString("\n");
}

/// Log a warning message.
/// Acquires the lock on the log buffer before logging.
pub fn warn(msg: []const u8) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    serial.writeString("WARN: ");
    serial.writeString(msg);
    serial.writeString("\n");
}

/// Log a warning message with formatting.
/// Acquires the lock on the log buffer before logging.
pub fn warnF(comptime fmt: []const u8, args: anytype) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    serial.writeString("WARN: ");
    try write(fmt, args);
    serial.writeString("\n");
}

/// Log an error message.
/// Acquires the lock on the log buffer before logging.
pub fn err(msg: []const u8) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    serial.writeString("ERROR: ");
    serial.writeString(msg);
    serial.writeString("\n");
}

/// Log an error message with formatting.
/// Acquires the lock on the log buffer before logging.
pub fn errF(comptime fmt: []const u8, args: anytype) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    serial.writeString("ERROR: ");
    try write(fmt, args);
    serial.writeString("\n");
}

/// Log a fatal error message and halt the system.
/// Attempts to acquire the lock log buffer before logging.
/// If the lock cannot be acquired, it proceeds without locking.
pub fn fatal(msg: []const u8) noreturn {
    const locked = log_buffer.tryLock(100_000_000);
    defer if (locked) log_buffer.unlock();

    serial.writeString("FATAL: ");
    serial.writeString(msg);
    serial.writeString("\n");

    std.debug.panic("Fatal error occurred", .{});
}

/// Log a fatal error message with formatting and halt the system.
/// Attempts to acquire the lock log buffer before logging.
/// If the lock cannot be acquired, it proceeds without locking.
pub fn fatalF(comptime fmt: []const u8, args: anytype) noreturn {
    const locked = log_buffer.tryLock(100_000_000);
    defer if (locked) log_buffer.unlock();

    serial.writeString("FATAL: ");
    write(fmt, args) catch {
        serial.writeString("Failed to format panic message");
    };
    serial.writeString("\n");

    std.debug.panic("Fatal error occurred", .{});
}
