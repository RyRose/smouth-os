const std = @import("std");

const arch = @import("arch");
const kernel = @import("root.zig");

const log = std.log.scoped(.kinit);

var gdt_table = kernel.gdt.Table(3).init();
var idt_table = kernel.idt.Table(256).init();

/// Initializes the kernel subsystems. This should be called as early as
/// possible in the boot process.
pub fn init() !void {
    kernel.serial.init();
    kernel.serial.write("\n");

    // Set up the GDT with a code segment and a data segment, both covering the
    // entire 4 GiB address space. The code segment is executable and readable,
    // while the data segment is writable. Both segments use 32-bit protected
    // mode and 4 KiB granularity. The first entry (index 0) is the null
    // descriptor, which is required by the x86 architecture. The second entry
    // (index 1) is the code segment descriptor, and the third entry (index 2)
    // is the data segment descriptor. After setting up the GDT, we load it
    // into the CPU using the LGDT instruction, which also flushes the old GDT
    // and updates the segment registers to use the new GDT.
    gdt_table.register(1, kernel.gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = kernel.gdt.SegmentType.init(
            .{ .segment_class = .code },
        ),
        .db = true,
        .granularity = true,
    }));
    gdt_table.register(2, kernel.gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = kernel.gdt.SegmentType.init(
            .{ .segment_class = .data },
        ),
        .db = true,
        .granularity = true,
    }));
    try gdt_table.installAndFlush(1, 2);

    // Set up the IDT with a handler for the double fault exception. The
    // handler is registered at the index corresponding to the double fault
    // exception (8), and it uses the code segment selector (index 1) from the
    // GDT. The handler is defined in the architecture-specific code and is
    // responsible for handling double fault exceptions, which occur when the
    // CPU encounters a critical error while trying to call an exception
    // handler. After registering the handler, we load the IDT into the CPU
    // using the LIDT instruction, which also flushes the old IDT and updates
    // the CPU's interrupt handling to use the new IDT.
    idt_table.register(.double_fault, kernel.idt.Descriptor.init(.{
        .offset = @intFromPtr(&arch.x86.double_fault_handler),
        .segment_selector = kernel.idt.SegmentSelector{ .index = 1 },
    }));
    idt_table.load();

    kernel.time.calibrate();
}
