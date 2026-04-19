//! Panic handling for the kernel.
//! Dumps panic information to the log and halts the system.
//! Halts the system by writing to the appropriate I/O port,
//! which is emulated by QEMU to trigger a shutdown.
//!

const std = @import("std");
const builtin = @import("builtin");

const arch = @import("arch");

const serial = @import("serial.zig");

const log = std.log.scoped(.PANIC);

pub const handler = std.debug.FullPanic(innerPanic);

fn innerPanic(msg: []const u8, return_address: ?usize) noreturn {
    log.err("{s}", .{msg});

    log.err("Panic stack trace: 0x{?x}", .{return_address});
    std.debug.writeCurrentStackTrace(
        .{ .allow_unsafe_unwind = true },
        serial.tty,
    ) catch |err| {
        log.err("Failed to log stack trace: {}", .{err});
    };

    if (@errorReturnTrace()) |trace| {
        log.err("Panic return trace:", .{});
        std.debug.writeErrorReturnTrace(trace, serial.tty) catch |err| {
            log.warn("Failed to write error trace: {}.", .{err});
        };
    }
    log.err("System is shutting down.", .{});
    badShutdown();
}

// Use QEMU shutdown port to halt the system with a non-zero exit code.
fn badShutdown() noreturn {
    arch.x86.insn.outw(0xF4, 0);
    while (true) {}
}
