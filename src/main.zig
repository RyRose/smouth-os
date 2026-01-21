const std = @import("std");

const ioport = @import("ioport.zig");
const serial = @import("serial.zig");
const log = @import("log.zig");
const gdt = @import("gdt.zig");
const sync = @import("sync.zig");

pub const panic = @import("panic.zig").panic;

export fn kmain() noreturn {
    main() catch |err| {
        std.debug.panic("Main failed: {}", .{err});
    };

    // Halt the CPU using QEMU shutdown port with a zero exit code
    // or an infinite loop.
    ioport.outw(0x604, 0x2000);
    while (true) {}
}

var gdt_buffer: [3]gdt.Descriptor = undefined;

fn main() !void {
    serial.init();

    try log.info("Instantiating GDT table.");
    var table = gdt.Table(3).init(&gdt_buffer);
    try log.info("Registering null segment.");
    try table.register(0, gdt.Descriptor{});
    try log.info("Registering code segment.");
    const code = try gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = 0xA, // Code segment
        .descriptor_type = true,
        .dpl = 0,
        .db = true,
        .granularity = true,
    });
    try table.register(1, code);
    try log.info("Registering data segment.");
    try table.register(2, try gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = 0x2, // Data segment
        .descriptor_type = true,
        .dpl = 0,
        .db = true,
        .granularity = true,
    }));
    try log.info("Installing and flushing GDT.");
    try table.installAndFlush();
    try log.info("GDT installed successfully.");
}
