//! Root module for x86 architecture.

// Ensure this code is only compiled for x86 freestanding targets.
comptime {
    const builtin = @import("builtin");
    const std = @import("std");
    std.debug.assert(builtin.target.cpu.arch == .x86);
    std.debug.assert(builtin.os.tag == .freestanding);
}

pub const insn = @import("insn.zig");
pub const boot = @import("boot.zig");

pub fn installAndFlushGDT(gdt_ptr: u64) void {
    const code_segment = 0x08;
    const data_segment = 0x10;
    asm volatile (
        \\ // Load the GDT using the provided pointer
        \\ lgdt (%[gdt_ptr])
        \\ // Far jumps to set CS register to 0x08
        \\ ljmp $0x08, $flush
        \\ flush:
        \\ mov %[data_segment], %ds
        \\ mov %[data_segment], %es
        \\ mov %[data_segment], %fs
        \\ mov %[data_segment], %gs
        \\ mov %[data_segment], %ss
        :
        : [gdt_ptr] "r" (&gdt_ptr),
          [code_segment] "r" (code_segment),
          [data_segment] "r" (data_segment),
    );
}

pub fn double_fault_handler() callconv(.{ .x86_interrupt = .{} }) void {
    @panic("Double fault occurred!");
}
