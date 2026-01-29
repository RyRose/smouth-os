const std = @import("std");

const arch = @import("arch");
const ioport = arch.x86.ioport;

const kernel = @import("kernel");
const gdt = kernel.gdt;
const idt = kernel.idt;
const log = kernel.log;
const panic = kernel.panic;
const pci = kernel.pci;
const serial = kernel.serial;

export fn kmain() noreturn {
    main() catch |err| {
        log.fatalF("Kernel main failed: {}", .{err});
    };

    // Halt the CPU using QEMU shutdown port with a zero exit code
    // or an infinite loop.
    ioport.outw(0x604, 0x2000);
    while (true) {}
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
        .offset = @intFromPtr(&arch.x86.double_fault_handler),
        .segment_selector = idt.SegmentSelector{ .index = 1 },
    }));
    try idt_table.load();
    try log.info("IDT loaded.");

    const msr_platform_info = arch.x86.rdmsr(0x1);
    try log.infoF("MSR Platform Info (0xCE): 0x{x}", .{msr_platform_info});

    for (0..256) |bus| {
        for (0..8) |device| {
            const address = pci.ConfigurationAddress.init(.{
                .bus = @intCast(bus),
                .device = @intCast(device),
                .function = 0,
                .register_offset = .vendor_device,
            });
            ioport.outl(pci.ConfigurationAddressPort, @bitCast(address));
            const raw = ioport.inl(pci.ConfigurationDataPort);

            if (raw == 0xFFFF_FFFF) continue;
            try log.infoF("PCI Device found at bus {d}, device {d}", .{ bus, device });

            const value: *const packed struct {
                vendor: u16,
                device: u16,
            } = @ptrCast(&raw);
            try log.infoF("  Vendor ID: 0x{x}", .{value.vendor});
            try log.infoF("  Device ID: 0x{x}", .{value.device});

            if (raw != 0x1059_1AF4) {
                continue;
            }
            try log.info("VirtIO sound card detected.");
        }
    }
}
