//! A minimal std.Io implementation for the freestanding kernel.
//!
//! Routes stderr / debug output to the serial port and leaves all other
//! operations returning errors (via std.Io.failing's vtable).  Suitable for
//! use as std_options_debug_io so that std.debug.print, stack-trace dumps,
//! and std.log all reach the serial console.

const std = @import("std");
const arch = @import("arch");
const serial = @import("serial.zig");

// ── stderr file-writer ────────────────────────────────────────────────────────

// Buffer held by the serial Io.Writer that backs stderr.
var io_buffer: [0]u8 = undefined;

// A File.Writer whose .interface drains to the serial port.
// Only the .interface field is used; .io and .file are never reached because
// our custom drain bypasses the normal file-write path.
var stderr_file_writer: std.Io.File.Writer = undefined;
var stderr_file_writer_ready = false;

fn stderrFileWriter() *std.Io.File.Writer {
    if (!stderr_file_writer_ready) {
        stderr_file_writer = .{
            .io = std.Io.failing,
            .file = .{ .handle = {}, .flags = .{ .nonblocking = false } },
            .interface = serial.newWriter(&io_buffer),
        };
        stderr_file_writer_ready = true;
    }
    return &stderr_file_writer;
}

// ── VTable implementations ────────────────────────────────────────────────────

fn crashHandler(userdata: ?*anyopaque) void {
    _ = userdata;
    // Trigger a QEMU shutdown then spin — same behaviour as kernel panic.
    arch.x86.insn.outw(0xF4, 0);
    while (true) {}
}

fn lockStderrFn(
    userdata: ?*anyopaque,
    terminal_mode: ?std.Io.Terminal.Mode,
) std.Io.Cancelable!std.Io.LockedStderr {
    _ = userdata;
    return .{
        .file_writer = stderrFileWriter(),
        .terminal_mode = terminal_mode orelse .escape_codes,
    };
}

fn tryLockStderrFn(
    userdata: ?*anyopaque,
    terminal_mode: ?std.Io.Terminal.Mode,
) std.Io.Cancelable!?std.Io.LockedStderr {
    return try lockStderrFn(userdata, terminal_mode);
}

fn unlockStderrFn(userdata: ?*anyopaque) void {
    _ = userdata;
    if (stderr_file_writer_ready) {
        stderr_file_writer.interface.flush() catch {};
    }
}

// Called by std.debug after a crash to spin forever.
fn futexWaitUncancelableFn(
    userdata: ?*anyopaque,
    ptr: *const u32,
    expected: u32,
) void {
    _ = .{ userdata, ptr, expected };
    arch.x86.insn.outw(0xF4, 0);
    while (true) {}
}

// ── VTable ────────────────────────────────────────────────────────────────────

// Start from std.Io.failing's vtable (returns errors for everything) and
// override only the handful of functions needed for serial debug output.
const kernel_vtable: std.Io.VTable = blk: {
    var v = std.Io.failing.vtable.*;
    v.crashHandler = crashHandler;
    v.lockStderr = lockStderrFn;
    v.tryLockStderr = tryLockStderrFn;
    v.unlockStderr = unlockStderrFn;
    v.futexWaitUncancelable = futexWaitUncancelableFn;
    break :blk v;
};

// ── Public interface ──────────────────────────────────────────────────────────

/// A minimal Io instance that routes stderr/debug output to the serial port.
/// Assign to std_options_debug_io to connect std.debug and std.log to serial.
pub const io: std.Io = .{
    .userdata = null,
    .vtable = &kernel_vtable,
};
