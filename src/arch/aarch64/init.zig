//! AArch64 platform initialization for QEMU's `virt` machine.

/// Completes platform setup after the bootstrap configures the MMU and PL011.
///
/// Current AArch64 drivers poll their devices, so they do not require generic
/// timer or interrupt-controller setup yet.
pub fn run() !void {
}
