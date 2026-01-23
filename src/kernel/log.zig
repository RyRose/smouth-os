const std = @import("std");

const sync = @import("sync.zig");
const serial = @import("serial.zig");

/// A simple log buffer protected by a spinlock.
/// This can be used to store log messages before flushing them to the serial port.
var log_buffer = sync.SpinLock([1024]u8).init([_]u8{0} ** 1024);

// Number of iterations to attempt acquiring the lock before giving up.
// Generally used for fatal logs where we want to avoid deadlocks.
const lockIterations = 100_000_000;

/// Internal function to write formatted log messages to the serial port.
fn write(comptime fmt: []const u8, args: anytype) !void {
    const buf = try std.fmt.bufPrint(&log_buffer.value, fmt, args);
    serial.writeString(buf);
}

/// Write the log preamble including the log level and lock status.
fn logPreamble(level: []const u8, locked: bool) void {
    serial.writeString(level);
    serial.writeString(": ");
    if (!locked) {
        serial.writeString("(unlocked) ");
    }
}

/// Log an informational message.
/// Acquires the lock on the log buffer before logging.
pub fn info(msg: []const u8) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    logPreamble("INFO", true);
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

    logPreamble("WARN", true);
    serial.writeString(msg);
    serial.writeString("\n");
}

/// Log a warning message with formatting.
/// Acquires the lock on the log buffer before logging.
pub fn warnF(comptime fmt: []const u8, args: anytype) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    logPreamble("WARN", true);
    try write(fmt, args);
    serial.writeString("\n");
}

/// Log an error message.
/// Acquires the lock on the log buffer before logging.
pub fn err(msg: []const u8) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    logPreamble("ERROR", true);
    serial.writeString(msg);
    serial.writeString("\n");
}

fn errFInternal(comptime fmt: []const u8, args: anytype) !void {
    logPreamble("ERROR", true);
    try write(fmt, args);
    serial.writeString("\n");
}

/// Log an error message with formatting.
/// Acquires the lock on the log buffer before logging.
pub fn errF(comptime fmt: []const u8, args: anytype) !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    try errFInternal(fmt, args);
}

/// Log a fatal error message and halt the system.
/// Attempts to acquire the lock log buffer before logging.
/// If the lock cannot be acquired, it proceeds without locking.
pub fn fatal(msg: []const u8) noreturn {
    const locked = log_buffer.tryLock(lockIterations);
    defer log_buffer.unlock();

    logPreamble("FATAL", locked);
    serial.writeString(msg);
    serial.writeString("\n");
    std.debug.panic("Fatal error occurred", .{});
}

/// Log a fatal error message with formatting and halt the system.
/// Attempts to acquire the lock log buffer before logging.
/// If the lock cannot be acquired, it proceeds without locking.
pub fn fatalF(comptime fmt: []const u8, args: anytype) noreturn {
    const locked = log_buffer.tryLock(lockIterations);
    defer log_buffer.unlock();

    logPreamble("FATAL", locked);
    write(fmt, args) catch {
        serial.writeString(fmt);
    };
    serial.writeString("\n");
    std.debug.panic("Fatal error occurred", .{});
}

/// Log the current error return trace.
/// Acquires the lock on the log buffer before logging.
pub fn logErrorReturnTrace() !void {
    log_buffer.lock();
    defer log_buffer.unlock();

    const trace = @errorReturnTrace();
    if (!trace) {
        return;
    }
    const stackTrace = trace.?;
    if (stackTrace.index <= 0) {
        return;
    }
    try errFInternal("Error return trace ({d} frames, {d} elements):", .{
        stackTrace.instruction_addresses.len,
        stackTrace.index,
    });
    for (stackTrace.instruction_addresses) |addr| {
        if (addr == 0) continue;
        try errFInternal("0x{x}", .{addr});
    }
}
