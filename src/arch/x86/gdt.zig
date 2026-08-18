//! x86-specific GDT operations.

/// Segment selectors currently loaded into the CPU.
pub const SegmentSelectors = struct {
    /// Code segment selector.
    cs: u16,
    /// Data segment selector.
    ds: u16,
    /// Extra segment selector.
    es: u16,
    /// F segment selector.
    fs: u16,
    /// G segment selector.
    gs: u16,
    /// Stack segment selector.
    ss: u16,
};

/// Returns the GDT pointer currently loaded into the CPU.
pub fn currentTablePointer() u64 {
    var gdt_ptr: u64 = 0;
    asm volatile (
        \\ sgdt (%[gdt_ptr])
        :
        : [gdt_ptr] "r" (&gdt_ptr),
    );
    return gdt_ptr;
}

/// Returns the segment selectors currently loaded into the CPU.
pub fn currentSegmentSelectors() SegmentSelectors {
    var cs: u16 = undefined;
    var ds: u16 = undefined;
    var es: u16 = undefined;
    var fs: u16 = undefined;
    var gs: u16 = undefined;
    var ss: u16 = undefined;
    asm volatile (
        \\ mov %%cs, %[cs]
        \\ mov %%ds, %[ds]
        \\ mov %%es, %[es]
        \\ mov %%fs, %[fs]
        \\ mov %%gs, %[gs]
        \\ mov %%ss, %[ss]
        : [cs] "={ax}" (cs),
          [ds] "={bx}" (ds),
          [es] "={cx}" (es),
          [fs] "={dx}" (fs),
          [gs] "={si}" (gs),
          [ss] "={di}" (ss),
    );
    return .{ .cs = cs, .ds = ds, .es = es, .fs = fs, .gs = gs, .ss = ss };
}

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
