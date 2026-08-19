//! Semihosting-based QEMU termination for the AArch64 `virt` machine.

/// Semihosting application-exit reason from the ARM semihosting ABI.
const adp_stopped_application_exit: u64 = 0x20026;

/// Parameters consumed by QEMU's SYS_EXIT_EXTENDED handler.
export var aarch64_semihost_exit_parameters: [2]u64 align(16) = undefined;

/// Terminates QEMU through the enabled AArch64 semihosting interface.
///
/// A zero exit status reports success to the build runner; a nonzero status
/// makes `test-aarch64` fail if a source-module test fails.
pub fn run(success: bool) noreturn {
    aarch64_semihost_exit_parameters = .{
        adp_stopped_application_exit,
        if (success) 0 else 1,
    };
    asm volatile (
        \\ mov x0, #0x20
        \\ ldr x1, =aarch64_semihost_exit_parameters
        \\ hlt #0xf000
    );
    while (true) asm volatile ("wfe");
}
