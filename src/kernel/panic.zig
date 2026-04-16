//! Panic handling for the kernel.
//! Dumps panic information to the log and halts the system.
//! Halts the system by writing to the appropriate I/O port,
//! which is emulated by QEMU to trigger a shutdown.
//!

const builtin = @import("builtin");
const std = @import("std");

const arch = @import("arch");

const debug = @import("debug.zig");
const dwarf = @import("dwarf.zig");

const log = std.log.scoped(.PANIC);

pub const panic = std.debug.FullPanic(innerPanic);

fn innerPanic(msg: []const u8, return_address: ?usize) noreturn {
    log.err("{s}", .{msg});
    if (return_address) |addr| {
        log.err("Panic stack trace: 0x{x}", .{addr});
        debug.printStackTrace(null) catch |err| {
            log.err("Failed to log stack trace: {}", .{err});
        };
    }
    log.err("Panic return trace:", .{});
    if (debug.printErrorReturnTrace()) |value| {
        if (!value) {
            log.warn("No error return trace available.", .{});
        }
    } else |err| {
        log.err("Failed to log error return trace: {}", .{err});
    }
    log.err("System is shutting down.", .{});
    badShutdown();
}

// Use QEMU shutdown port to halt the system with a non-zero exit code.
fn badShutdown() noreturn {
    arch.x86.insn.outw(0xF4, 0);
    while (true) {}
}
