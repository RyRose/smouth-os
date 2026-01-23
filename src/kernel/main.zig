const std = @import("std");

const ioport = @import("ioport.zig");
const serial = @import("serial.zig");
const log = @import("log.zig");
const gdt = @import("gdt.zig");
const sync = @import("sync.zig");
const idt = @import("idt.zig");

pub const panic = @import("panic.zig").panic;

export fn kmain() noreturn {
    main() catch |err| {
        log.fatalF("Kernel main failed: {}", .{err});
    };

    // Halt the CPU using QEMU shutdown port with a zero exit code
    // or an infinite loop.
    ioport.outw(0x604, 0x2000);
    while (true) {}
}

fn double_fault_handler() callconv(.{ .x86_interrupt = .{} }) void {
    log.fatal("Double fault occurred!");
}

var gdt_table = gdt.Table(3).init();
var idt_table = idt.Table(256).init();

fn main() !void {
    serial.init();

    try gdt_table.register(1, gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = gdt.SegmentType.init(.{ .segment_class = .code }),
        .db = true,
        .granularity = true,
    }));
    try gdt_table.register(2, gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = gdt.SegmentType.init(.{ .segment_class = .data }),
        .db = true,
        .granularity = true,
    }));
    try gdt_table.installAndFlush();
    try log.info("GDT installed and flushed.");

    idt_table.register(.double_fault, idt.Descriptor.init(.{
        .offset = @intFromPtr(&double_fault_handler),
        .segment_selector = idt.SegmentSelector{ .index = 1 },
    }));
    try idt_table.load();
    try log.info("IDT loaded.");
}
