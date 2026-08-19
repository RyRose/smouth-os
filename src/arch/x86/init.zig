//! x86 kernel platform initialization for the QEMU PC machine.

const std = @import("std");

const gdt = @import("gdt_table.zig");
const idt = @import("idt_table.zig");
const pci = @import("pci.zig");
const time = @import("time.zig");
const handlers = @import("idt.zig");

const log = std.log.scoped(.x86_init);

/// Global descriptor table installed during x86 initialization.
var gdt_table = gdt.Table(3).init();
/// Interrupt descriptor table installed during x86 initialization.
var idt_table = idt.Table(256).init();

/// Initializes x86 segmentation, interrupt descriptors, timing, and PCI logging.
pub fn run() !void {
    gdt_table.register(1, gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = gdt.SegmentType.init(.{ .segment_class = .code }),
        .db = true,
        .granularity = true,
    }));
    gdt_table.register(2, gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = gdt.SegmentType.init(.{ .segment_class = .data }),
        .db = true,
        .granularity = true,
    }));
    try gdt_table.installAndFlush(1, 2);

    idt_table.register(.double_fault, idt.Descriptor.init(.{
        .offset = @intFromPtr(&handlers.double_fault_handler),
        .segment_selector = .{ .index = 1 },
    }));
    idt_table.load();

    time.calibrate();
    logPciDevices();
}

/// Logs every PCI function visible on the QEMU PC bus.
fn logPciDevices() void {
    for (0..256) |bus| {
        for (0..32) |device| {
            const address = pci.ConfigurationAddress{
                .bus = @intCast(bus),
                .device = @intCast(device),
                .register_offset = @intFromEnum(pci.ConfigurationOffset.vendor_device),
            };
            const vendor_device: pci.VendorDevice = @bitCast(pci.configRead32(address));
            if (vendor_device.vendor_id == 0xFFFF) continue;
            log.info("PCI device bus={} dev={} vendor=0x{x} device=0x{x}", .{
                bus,
                device,
                vendor_device.vendor_id,
                vendor_device.device_id,
            });
        }
    }
}
