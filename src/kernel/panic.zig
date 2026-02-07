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

fn innerPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    log.err("{s}", .{msg});
    log.err("First trace address = {?x}", .{first_trace_addr});
    debug.logErrorReturnTrace(.err, .PANIC) catch |err| {
        log.err("Failed to log error return trace: {}", .{err});
    };
    log.err("System is shutting down.", .{});
    shutdown();
}

fn shutdown() noreturn {
    arch.x86.insn.outw(0xF4, 0);
    while (true) {}
}
