//! Thin wrappers for x86 CPU instructions.
//! These functions use inline assembly to execute specific x86 instructions
//! and return their results in a safe and ergonomic way.

/// Read the Time Stamp Counter (TSC) value.
pub fn rdtsc() u64 {
    var hi: u32 = 0;
    var lo: u32 = 0;
    asm volatile (
        \\ rdtsc
        : [lo] "={eax}" (lo),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, lo);
}

/// Read a Model-Specific Register (MSR) value.
pub fn rdmsr(msr: u32) u64 {
    var hi: u32 = 0;
    var lo: u32 = 0;
    asm volatile (
        \\ rdmsr
        : [lo] "={eax}" (lo),
          [hi] "={edx}" (hi),
        : [msr] "{ecx}" (msr),
    );
    return (@as(u64, hi) << 32) | @as(u64, lo);
}

/// Write a value to a Model-Specific Register (MSR).
pub fn wrmsr(msr: u32, value: u64) void {
    const hi = @as(u32, value >> 32);
    const lo = @as(u32, value & 0xFFFFFFFF);
    asm volatile (
        \\ wrmsr
        :
        : [lo] "{eax}" (lo),
          [hi] "{edx}" (hi),
          [msr] "{ecx}" (msr),
    );
}

/// Read a byte from the specified I/O port.
pub fn inb(port: u16) u8 {
    var value: u8 = 0;
    asm volatile (
        \\ inb %[port], %[value]
        : [value] "={al}" (value),
        : [port] "{dx}" (port),
    );
    return value;
}

/// Write a byte to an I/O port.
pub fn outb(port: u16, value: u8) void {
    asm volatile (
        \\ outb %[value], %[port]
        :
        : [value] "{al}" (value),
          [port] "{dx}" (port),
    );
}

/// Read a 16-bit value from the specified I/O port.
pub fn inw(port: u16) u16 {
    var value: u16 = 0;
    asm volatile (
        \\ inw %[port], %[value]
        : [value] "={ax}" (value),
        : [port] "{dx}" (port),
    );
    return value;
}

/// Write a 16-bit value to the specified I/O port.
pub fn outw(port: u16, value: u16) void {
    asm volatile (
        \\ outw %[value], %[port]
        :
        : [value] "{ax}" (value),
          [port] "{dx}" (port),
    );
}

/// Read a 32-bit value from the specified I/O port.
pub fn inl(port: u16) u32 {
    var value: u32 = 0;
    asm volatile (
        \\ inl %[port], %[value]
        : [value] "={eax}" (value),
        : [port] "{dx}" (port),
    );
    return value;
}

/// Write a 32-bit value to the specified I/O port.
pub fn outl(port: u16, value: u32) void {
    asm volatile (
        \\ outl %[value], %[port]
        :
        : [value] "{eax}" (value),
          [port] "{dx}" (port),
    );
}

/// Halt the CPU until the next external interrupt.
pub inline fn hlt() void {
    asm volatile ("hlt");
}

/// Disable interrupts on the CPU.
pub inline fn cli() void {
    asm volatile ("cli");
}

/// Enable interrupts on the CPU.
pub inline fn sti() void {
    asm volatile ("sti");
}

/// PAUSE instruction
///
/// std.atomic.spinLoopHint() should generally be used instead.
pub inline fn pause() void {
    asm volatile ("pause");
}

/// Execute the CPUID instruction with the specified EAX and ECX values.
/// Returns the results in a struct containing EAX, EBX, ECX, and EDX.
pub fn cpuid(eax: u32, ecx: u32) struct {
    eax: u32,
    ebx: u32,
    ecx: u32,
    edx: u32,
} {
    var eax_out: u32 = 0;
    var ebx: u32 = 0;
    var ecx_out: u32 = 0;
    var edx: u32 = 0;
    asm volatile (
        \\ cpuid
        : [eax] "={eax}" (eax_out),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx_out),
          [edx] "={edx}" (edx),
        : [eax] "{eax}" (eax),
          [ecx] "{ecx}" (ecx),
    );
    return .{ .eax = eax_out, .ebx = ebx, .ecx = ecx_out, .edx = edx };
}
