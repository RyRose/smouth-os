//! Thin wrappers for AArch64 CPU instructions.

/// Orders DMA-visible loads and stores around device interaction.
pub fn memoryBarrier() void {
    asm volatile ("dmb osh");
}
