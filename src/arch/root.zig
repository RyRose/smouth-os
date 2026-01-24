const x86 = @import("x86/root.zig");
const builtin = @import("builtin");

/// Returns an error if not in a freestanding environment.
fn freestanding() !void {
    if (comptime builtin.os.tag == .freestanding) {
        return;
    }
    return error.NotFreestanding;
}

/// Install and flush the Global Descriptor Table (GDT).
pub fn installAndFlushGDT(gdt: u64) !void {
    try freestanding();
    return switch (builtin.cpu.arch) {
        .x86 => x86.installAndFlushGDT(gdt),
        else => @compileError("Unsupported architecture"),
    };
}

/// Read the Time Stamp Counter (TSC) value.
pub fn rdtsc() !u64 {
    try freestanding();
    return switch (builtin.cpu.arch) {
        .x86 => x86.rdtsc(),
        else => @compileError("Unsupported architecture"),
    };
}

/// Read a Model-Specific Register (MSR) value.
pub fn rdmsr(msr: u32) !u64 {
    try freestanding();
    return switch (builtin.cpu.arch) {
        .x86 => x86.rdmsr(msr),
        else => @compileError("Unsupported architecture"),
    };
}
