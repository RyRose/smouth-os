//! AArch64 bootstrap for QEMU's `virt` machine.

const root = @import("root");
const std = @import("std");

const arch = @import("os").arch;

/// Level-one translation table for the QEMU `virt` identity map.
export var aarch64_l1_table: [512]u64 align(4096) linksection(".bss") = undefined;
/// Level-two table mapping QEMU peripherals as device memory.
export var aarch64_device_l2_table: [512]u64 align(4096) linksection(".bss") = undefined;
/// Level-two table mapping QEMU RAM as normal memory.
export var aarch64_ram_l2_table: [512]u64 align(4096) linksection(".bss") = undefined;

/// Enters the shared kernel root and reports its result to QEMU.
export fn arch_main() noreturn {
    root.main() catch |err| {
        std.log.err("Kernel main failed: {}", .{err});
        arch.self.shutdown.run(false);
    };
    arch.self.shutdown.run(true);
}

/// Installs the QEMU `virt` identity map, initializes an early stack, and
/// enters the shared architecture bootstrap.
export fn _start() linksection(".text.boot") callconv(.naked) noreturn {
    asm volatile (
        \\ ldr x1, =aarch64_l1_table
        \\ ldr x2, =aarch64_device_l2_table
        \\ orr x3, x2, #3
        \\ str x3, [x1]
        \\ ldr x2, =aarch64_ram_l2_table
        \\ orr x3, x2, #3
        \\ str x3, [x1, #8]
        \\
        \\ ldr x1, =aarch64_device_l2_table
        \\ mov x2, #0
        \\ mov x3, #0x200
        \\ mov x4, #0x601
        \\ 1:
        \\ orr x5, x2, x4
        \\ str x5, [x1]
        \\ add x1, x1, #8
        \\ add x2, x2, #0x200, lsl #12
        \\ subs x3, x3, #1
        \\ b.ne 1b
        \\
        \\ ldr x1, =aarch64_ram_l2_table
        \\ mov x2, #0x40000000
        \\ mov x3, #0x200
        \\ mov x4, #0x705
        \\ 2:
        \\ orr x5, x2, x4
        \\ str x5, [x1]
        \\ add x1, x1, #8
        \\ add x2, x2, #0x200, lsl #12
        \\ subs x3, x3, #1
        \\ b.ne 2b
        \\
        \\ dsb sy
        \\ ldr x0, =0xff04
        \\ msr mair_el1, x0
        \\ ldr x0, =0x803520
        \\ msr tcr_el1, x0
        \\ ldr x0, =aarch64_l1_table
        \\ msr ttbr0_el1, x0
        \\ isb
        \\ mrs x0, sctlr_el1
        \\ orr x0, x0, #1
        \\ msr sctlr_el1, x0
        \\ isb
        \\
        \\ mrs x0, cpacr_el1
        \\ orr x0, x0, #0x300000
        \\ msr cpacr_el1, x0
        \\ isb
        \\ ldr x0, =__stack_top
        \\ mov sp, x0
        \\ bl arch_main
        \\ b .
    );
}
