//! Root module for x86 architecture.

// Ensure this code is only compiled for x86 freestanding targets.
comptime {
    const builtin = @import("builtin");
    const std = @import("std");
    if (builtin.target.cpu.arch != .x86) {
        @compileError(std.fmt.comptimePrint(
            "This code is only supported on x86 architecture but found {}",
            .{builtin.target.cpu.arch},
        ));
    }
    if (builtin.os.tag != .freestanding) {
        @compileError(std.fmt.comptimePrint(
            "This code is only supported on freestanding targets but found {}",
            .{builtin.os.tag},
        ));
    }
}

pub const insn = @import("insn.zig");
pub const boot = @import("boot.zig");

pub fn installAndFlushGDT(
    gdt_ptr: u64,
    comptime code_segment: u16,
    data_segment: u16,
) void {
    asm volatile (
        \\ // Load the GDT using the provided pointer
        \\ lgdt (%[gdt_ptr])
        \\ // Far jumps to set CS register to provided code segment selector
        \\ ljmp %[code_segment], $1f
        \\ 1:
        \\ // Update all segment registers to provided data segment selector
        \\ mov %[data_segment], %ds
        \\ mov %[data_segment], %es
        \\ mov %[data_segment], %fs
        \\ mov %[data_segment], %gs
        \\ mov %[data_segment], %ss
        :
        : [gdt_ptr] "r" (&gdt_ptr),
          [code_segment] "i" (code_segment),
          [data_segment] "{ax}" (data_segment),
    );
}

pub fn double_fault_handler() callconv(.{ .x86_interrupt = .{} }) void {
    @panic("Double fault occurred!");
}
