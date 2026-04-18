//! A minimal std.Io implementation for the freestanding kernel.
//!
//! Routes stderr / debug output to a caller-supplied writer interface and
//! leaves all other operations returning errors (via std.Io.failing's vtable).
//! Suitable for use as std_options_debug_io so that std.debug.print,
//! stack-trace dumps, and std.log all reach the configured output.
//!
//! Call make() with the desired writer interface before any output is produced.
//! For kernel mode pass serial.tty.writer.*; for test mode pass test_interface.

const std = @import("std");
const arch = @import("arch");
const serial = @import("serial.zig");

// ── Test-mode buffered output ─────────────────────────────────────────────────

/// Buffer that captures stderr output in test mode.
pub var buffer: [1000]u8 = undefined;

/// Fixed writer backed by buffer; reset .end to 0 between tests.
pub var writer = std.Io.Writer.fixed(&buffer);

fn drain(
    w: *std.Io.Writer,
    data: []const []const u8,
    splat: usize,
) std.Io.Writer.Error!usize {
    if (w.end > 0) {
        _ = try writer.writeAll(w.buffer[0..w.end]);
        w.end = 0;
    }
    var consumed: usize = 0;
    for (data, 0..) |slice, i| {
        const repeat = if (i + 1 == data.len) splat else 1;
        for (0..repeat) |_| {
            try writer.writeAll(slice);
            consumed += slice.len;
        }
    }
    return consumed;
}

var null_buffer: [0]u8 = undefined;

/// Writer interface that buffers to writer/buffer; pass to make() in test mode.
pub const test_interface: std.Io.Writer = .{
    .vtable = &.{ .drain = drain },
    .buffer = &null_buffer,
};

// ── stderr file-writer ────────────────────────────────────────────────────────

var stderr_file_writer: std.Io.File.Writer = undefined;
var stderr_file_writer_ready = false;
var _interface: ?std.Io.Writer = null;

fn stderrFileWriter() *std.Io.File.Writer {
    if (!stderr_file_writer_ready) {
        stderr_file_writer = .{
            .io = std.Io.failing,
            .file = .{ .handle = {}, .flags = .{ .nonblocking = false } },
            .interface = _interface orelse serial.tty.writer.*,
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

// The kernel is single-threaded with no async cancellation support.
// Callers (e.g. std.debug.lockStderr) swap to .blocked and restore; we just
// always report the previous state as .blocked so callers see a no-op.
fn swapCancelProtectionFn(
    userdata: ?*anyopaque,
    new: std.Io.CancelProtection,
) std.Io.CancelProtection {
    _ = .{ userdata, new };
    return .blocked;
}

// ── VTable ────────────────────────────────────────────────────────────────────

// Start from std.Io.failing's vtable (returns errors for everything) and
// override only the handful of functions needed for debug output.
const kernel_vtable: std.Io.VTable = blk: {
    var v = std.Io.failing.vtable.*;
    v.crashHandler = crashHandler;
    v.lockStderr = lockStderrFn;
    v.tryLockStderr = tryLockStderrFn;
    v.unlockStderr = unlockStderrFn;
    v.futexWaitUncancelable = futexWaitUncancelableFn;
    v.swapCancelProtection = swapCancelProtectionFn;
    break :blk v;
};

// ── Public interface ──────────────────────────────────────────────────────────

/// Configures the stderr writer interface and returns the Io instance.
/// Must be called before any output is produced.
pub fn make(interface: std.Io.Writer) std.Io {
    _interface = interface;
    return io;
}

/// A minimal Io instance for use as std_options_debug_io.
/// Call make() to configure the writer interface before first use.
pub const io: std.Io = .{
    .userdata = null,
    .vtable = &kernel_vtable,
};
