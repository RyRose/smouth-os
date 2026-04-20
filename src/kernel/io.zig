//! A minimal std.Io implementation for the freestanding kernel.
//!
//! Use make() with a compile-time Mode to construct an Io instance backed by
//! either the serial port or a capture buffer. Assign to std_options_debug_io
//! so that std.debug.print, stack-trace dumps, and std.log reach the chosen
//! output with no separate runtime initialisation call required.

const std = @import("std");

const arch = @import("arch");

const serial = @import("serial.zig");

// ── Buffer mode capture ───────────────────────────────────────────────────────

/// Buffer that captures stderr output in buffer mode.
/// TODO: Avoid allocating this for serial mode.
var buffer: [1000]u8 = undefined;

/// Fixed writer backed by buffer; reset .end to 0 between tests.
pub var writer = std.Io.Writer.fixed(&buffer);

fn drainToGlobalBuffer(
    w: *std.Io.Writer,
    data: []const []const u8,
    splat: usize,
) std.Io.Writer.Error!usize {
    if (w.end > 0) {
        try writer.writeAll(w.buffer[0..w.end]);
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

// ── Shared vtable helpers (mode-independent) ──────────────────────────────────

fn crashHandler(userdata: ?*anyopaque) void {
    _ = userdata;
    // Trigger a QEMU shutdown then spin — same behaviour as kernel panic.
    arch.x86.ioport.outw(.qemu_debug_exit, 0);
    while (true) {}
}

fn futexWaitUncancelableFn(
    userdata: ?*anyopaque,
    ptr: *const u32,
    expected: u32,
) void {
    _ = .{ userdata, ptr, expected };
    arch.x86.ioport.outw(.qemu_debug_exit, 0);
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

// ── Mode-specific vtable ──────────────────────────────────────────────────────

/// Selects the stderr backend used when constructing an Io with make().
pub const Mode = enum {
    /// Write to the serial port, with no buffering.
    serial,
    /// Capture output in the `buffer` variable, for retrieval by tests.
    buffer,
};

fn Backed(comptime mode: Mode) type {
    return struct {
        var fw: std.Io.File.Writer = undefined;
        var fw_ready = false;

        fn getWriter() *std.Io.File.Writer {
            if (!fw_ready) {
                fw = .{
                    .io = std.Io.failing,
                    .file = .{ .handle = {}, .flags = .{ .nonblocking = false } },
                    .interface = switch (mode) {
                        .serial => serial.tty.writer.*,
                        .buffer => .{
                            .vtable = &.{ .drain = drainToGlobalBuffer },
                            // Use zero-length buffer to force drain to global buffer on every write.
                            .buffer = &[0]u8{},
                        },
                    },
                };
                fw_ready = true;
            }
            return &fw;
        }

        fn lockStderrFn(
            userdata: ?*anyopaque,
            terminal_mode: ?std.Io.Terminal.Mode,
        ) std.Io.Cancelable!std.Io.LockedStderr {
            _ = userdata;
            return .{
                .file_writer = getWriter(),
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
            if (fw_ready) fw.interface.flush() catch {};
        }

        const vtable: std.Io.VTable = blk: {
            var v = std.Io.failing.vtable.*;
            v.crashHandler = crashHandler;
            v.lockStderr = lockStderrFn;
            v.tryLockStderr = tryLockStderrFn;
            v.unlockStderr = unlockStderrFn;
            v.futexWaitUncancelable = futexWaitUncancelableFn;
            v.swapCancelProtection = swapCancelProtectionFn;
            break :blk v;
        };
    };
}

// ── Public interface ──────────────────────────────────────────────────────────

/// Returns an Io instance for the given mode. Comptime-safe: suitable for
/// direct use in std_options_debug_io declarations.
pub fn make(comptime mode: Mode) std.Io {
    return .{ .userdata = null, .vtable = &Backed(mode).vtable };
}
