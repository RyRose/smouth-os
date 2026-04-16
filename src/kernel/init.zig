const std = @import("std");

const arch = @import("arch");
const kernel = @import("root.zig");

const log = std.log.scoped(.kinit);

var gdt_table = kernel.gdt.Table(3).init();
var idt_table = kernel.idt.Table(256).init();

pub fn init() !void {
    kernel.serial.init();
    kernel.serial.write("\n");
    try kernel.debug.init();
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

    idt_table.register(.double_fault, kernel.idt.Descriptor.init(.{
        .offset = @intFromPtr(&arch.x86.double_fault_handler),
        .segment_selector = kernel.idt.SegmentSelector{ .index = 1 },
    }));
    idt_table.load();
}
