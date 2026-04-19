//! Entry point for the kernel. This is where the kernel starts executing after
//! boot.
//!

const builtin = @import("builtin");
const std = @import("std");

const arch = @import("arch");
const kernel = @import("kernel");

const log = std.log.scoped(.main);

// Standard options for the kernel.
pub const std_options: std.Options = kernel.std_options.default();

/// Route std.debug / std.log output to the serial port.
pub const std_options_debug_io: std.Io = kernel.io.make(.serial);

/// Overrides std.debug.SelfInfo for freestanding kernel DWARF stack traces.
pub const debug = kernel.debug.self;

/// Panic handler for the kernel.
pub const panic = kernel.panic.handler;

comptime {
    // Link initial boot code.
    switch (builtin.cpu.arch) {
        .x86 => _ = arch.x86.boot,
        else => @compileError("Unsupported architecture: " ++ @tagName(builtin.cpu.arch)),
    }
}

pub fn main() anyerror!void {
    try kernel.init.init();

    for (0..256) |bus| {
        for (0..8) |device| {
            const address = kernel.pci.ConfigurationAddress.init(.{
                .bus = @intCast(bus),
                .device = @intCast(device),
                .function = 0,
                .register_offset = .vendor_device,
            });
            arch.x86.insn.outl(
                kernel.pci.ConfigurationAddressPort,
                @bitCast(address),
            );
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
