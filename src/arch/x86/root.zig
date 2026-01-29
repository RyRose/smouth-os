//! Root module for x86 architecture.

// Ensure this code is only compiled for x86 freestanding targets.
comptime {
    std.debug.assert(builtin.target.cpu.arch == .x86);
    std.debug.assert(builtin.os.tag == .freestanding);
}

const builtin = @import("builtin");
const std = @import("std");

const log = @import("kernel").log;

pub const ioport = @import("ioport.zig");

/// Install and flush the Global Descriptor Table (GDT).
/// Defined in assembly at installAndFlushGDT.S
pub extern fn installAndFlushGDT(gdt_ptr: u64) void;

/// Read the Time Stamp Counter (TSC) value.
pub fn rdtsc() u64 {
    var hi: u32 = 0;
    var lo: u32 = 0;
    asm volatile ("rdtsc"
        : [lo] "={eax}" (lo),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, lo);
}

/// Read a Model-Specific Register (MSR) value.
pub fn rdmsr(msr: u32) u64 {
    var hi: u32 = 0;
    var lo: u32 = 0;
    asm volatile ("rdmsr"
        : [lo] "={eax}" (lo),
          [hi] "={edx}" (hi),
        : [msr] "{ecx}" (msr),
    );
    return (@as(u64, hi) << 32) | @as(u64, lo);
}

pub fn double_fault_handler() callconv(.{ .x86_interrupt = .{} }) void {
    log.fatal("Double fault occurred!");
}
