const builtin = @import("builtin");
const std = @import("std");

const arch = @import("arch");
const kernel = @import("kernel");

const log = std.log.scoped(.main);

// Standard options for the kernel.
// Must match this specific signature to be used by Zig's standard library.
pub const std_options: std.Options = kernel.std_options.default();

/// Panic handler for the kernel.
/// Must match this specific signature to be used by Zig's standard library.
pub const panic = kernel.panic.panic;

export fn kmain() noreturn {
    main() catch |err| {
        log.err("Kernel main failed: {}", .{err});
        @panic("Kernel main failed!");
    };

    // Halt the CPU using QEMU shutdown port with a zero exit code
    // or an infinite loop.
    arch.x86.insn.outw(0x604, 0x2000);
    while (true) {}
}

var gdt_table = kernel.gdt.Table(3).init();
var idt_table = kernel.idt.Table(256).init();

fn main() !void {
    // Link initial boot code.
    _ = arch.x86.boot;

    kernel.serial.init();
    kernel.serial.writeByte('\n');
    log.info("Zig version: {s}", .{builtin.zig_version_string});
    log.info("OS: {}", .{builtin.os.tag});
    log.info("CPU Arch: {}", .{builtin.cpu.arch});
    log.info("ABI: {}", .{builtin.abi});
    log.info("Object format: {}", .{builtin.object_format});
    log.info("Strip debug info: {}", .{builtin.strip_debug_info});
    log.info("Mode: {}", .{builtin.mode});
    log.info(
        "Position independent code: {}",
        .{builtin.position_independent_code},
    );
    log.info("Error return tracing: {}", .{builtin.have_error_return_tracing});
    log.info("Valgrind support: {}", .{builtin.valgrind_support});
    log.info("Fuzz: {}", .{builtin.fuzz});
    log.info("Code model: {}", .{builtin.code_model});
    log.info("Link libc: {}", .{builtin.link_libc});
    log.info("Link libcpp: {}", .{builtin.link_libcpp});
    log.info("Output mode: {}", .{builtin.output_mode});

    log.info("Initializing debug information.", .{});
    try kernel.debug.init();

    try gdt_table.register(1, kernel.gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = kernel.gdt.SegmentType.init(.{ .segment_class = .code }),
        .db = true,
        .granularity = true,
    }));
    try gdt_table.register(2, kernel.gdt.Descriptor.init(.{
        .base = 0,
        .limit = 0xFFFFF,
        .segment_type = kernel.gdt.SegmentType.init(.{ .segment_class = .data }),
        .db = true,
        .granularity = true,
    }));
    try gdt_table.installAndFlush();
    log.info("GDT installed.", .{});

    idt_table.register(.double_fault, kernel.idt.Descriptor.init(.{
        .offset = @intFromPtr(&arch.x86.double_fault_handler),
        .segment_selector = kernel.idt.SegmentSelector{ .index = 1 },
    }));
    try idt_table.load();
    log.info("IDT loaded", .{});

    const msr_platform_info = arch.x86.insn.rdmsr(0x1);
    log.info("MSR Platform Info (0xCE): 0x{x}", .{msr_platform_info});

    for (0..256) |bus| {
        for (0..8) |device| {
            const address = kernel.pci.ConfigurationAddress.init(.{
                .bus = @intCast(bus),
                .device = @intCast(device),
                .function = 0,
                .register_offset = .vendor_device,
            });
            arch.x86.insn.outl(kernel.pci.ConfigurationAddressPort, @bitCast(address));
            const raw = arch.x86.insn.inl(kernel.pci.ConfigurationDataPort);

            if (raw == 0xFFFF_FFFF) continue;
            log.info("PCI Device found at bus {d}, device {d}", .{
                bus,
                device,
            });

            const value: *const packed struct {
                vendor: u16,
                device: u16,
            } = @ptrCast(&raw);
            log.info("  Vendor ID: 0x{x}", .{value.vendor});
            log.info("  Device ID: 0x{x}", .{value.device});

            if (raw != 0x1059_1AF4) {
                continue;
            }
            log.info("VirtIO sound card detected.", .{});
        }
    }
}
