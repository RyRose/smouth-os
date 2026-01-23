//! Root module for x86 architecture.

/// Install and flush the Global Descriptor Table (GDT).
/// Defined in assembly at installAndFlushGDTInternal.S
pub extern fn installAndFlushGDT(gdt_ptr: u64) void;
