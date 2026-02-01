//! Panic handling for the kernel.
//! Dumps panic information to the log and halts the system.
//! Halts the system by writing to the appropriate I/O port,
//! which is emulated by QEMU to trigger a shutdown.
//!

const builtin = @import("builtin");
const std = @import("std");

const arch = @import("arch");

const dwarf = @import("dwarf.zig");

const log = std.log.scoped(.PANIC);

pub const panic = std.debug.FullPanic(innerPanic);

pub fn init() !void {
    panic_dwarf = try dwarf.open(dwarf_allocator.allocator());
}

// 1 MiB buffer for DWARF debug info
var dwarf_buffer: [1000 * 1024]u8 = undefined;
var dwarf_allocator = std.heap.FixedBufferAllocator.init(&dwarf_buffer);
var panic_dwarf: dwarf.Dwarf = undefined;

fn innerPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    log.err("{s}", .{msg});
    log.err("First trace address = {?x}", .{first_trace_addr});
    logErrorReturnTrace();
    shutdown();
}

/// Log the current error return trace.
/// Acquires the lock on the log buffer before logging.
fn logErrorReturnTrace() void {
    const trace = @errorReturnTrace();
    if (trace == null) {
        return;
    }
    const stackTrace = trace.?;
    if (stackTrace.index <= 0) {
        return;
    }
    log.err("Error return trace ({d} frames, {d} elements):", .{
        stackTrace.instruction_addresses.len,
        stackTrace.index,
    });
    for (stackTrace.instruction_addresses) |addr| {
        if (addr == 0) continue;
        log.err("0x{x} - {?s}", .{ addr, panic_dwarf.getSymbolName(addr) });
    }
}

fn shutdown() noreturn {
    arch.x86.ioport.outw(0xF4, 0);
    while (true) {}
}
