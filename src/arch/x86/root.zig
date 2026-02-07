//! Root module for x86 architecture.

// Ensure this code is only compiled for x86 freestanding targets.
comptime {
    const builtin = @import("builtin");
    const std = @import("std");
    std.debug.assert(builtin.target.cpu.arch == .x86);
    std.debug.assert(builtin.os.tag == .freestanding);
}

pub const insn = @import("insn.zig");

/// Install and flush the Global Descriptor Table (GDT).
/// Defined in assembly at installAndFlushGDT.S
pub extern fn installAndFlushGDT(gdt_ptr: u64) void;

pub fn double_fault_handler() callconv(.{ .x86_interrupt = .{} }) void {
    @panic("Double fault occurred!");
}
