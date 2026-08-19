//! QEMU PC shutdown operations for x86.

const ioport = @import("ioport.zig");

/// Stops QEMU with a status that matches `success`.
pub fn run(success: bool) noreturn {
    if (success) {
        ioport.outw(.qemu_acpi_shutdown, 0x2000);
    } else {
        ioport.outw(.qemu_debug_exit, 0);
    }
    while (true) {}
}
