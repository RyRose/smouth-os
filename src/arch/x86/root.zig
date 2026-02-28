//! Root module for x86 architecture.

const std = @import("std");

const kernel = @import("kernel");

const log = std.log.scoped(.x86);

// Ensure this code is only compiled for x86 freestanding targets.
comptime {
    const builtin = @import("builtin");
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

const InterruptStackFrame = extern struct {
    instruction_pointer: usize,
    code_segment: u64,
    cpu_flags: u64,
    stack_pointer: u64,
    stack_segment: u64,
};

pub fn double_fault_handler(
    frame: *InterruptStackFrame,
    error_code: u32,
) callconv(.{ .x86_interrupt = .{} }) void {
    _ = error_code;
    log.err("Double fault occurred at:", .{});
    kernel.debug.printLineInfo(frame.instruction_pointer) catch |err| {
        log.err("Failed to print line info for double fault: {}", .{err});
    };
    std.debug.panic("Double fault occurred!", .{});
}
