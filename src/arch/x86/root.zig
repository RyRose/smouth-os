//! Root module for x86 architecture.

/// Install and flush the Global Descriptor Table (GDT).
/// Defined in assembly at installAndFlushGDT.S
pub extern fn installAndFlushGDT(gdt_ptr: u64) void;

/// Read the Time Stamp Counter (TSC) value.
pub fn rdtsc() !u64 {
    var hi: u32 = 0;
    var lo: u32 = 0;
    asm volatile ("rdtsc"
        : [lo] "={eax}" (lo),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, lo);
}

/// Read a Model-Specific Register (MSR) value.
pub fn rdmsr(msr: u32) !u64 {
    var hi: u32 = 0;
    var lo: u32 = 0;
    asm volatile ("rdmsr"
        : [lo] "={eax}" (lo),
          [hi] "={edx}" (hi),
        : [msr] "{ecx}" (msr),
    );
    return (@as(u64, hi) << 32) | @as(u64, lo);
}
