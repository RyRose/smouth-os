//! x86-specific GDT operations.

/// Installs the GDT using the provided pointer and segment selectors, then flushes it by
/// performing a far jump and updating all segment registers.
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
