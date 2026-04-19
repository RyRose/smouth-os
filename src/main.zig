//! Entry point for the kernel. This is where the kernel starts executing after
//! boot. Also serves as the test runner when built with testing enabled.

const builtin = @import("builtin");
const std = @import("std");

const arch = @import("arch");
const kernel = @import("kernel");

const log = std.log.scoped(.main);

// Standard options for the kernel.
pub const std_options: std.Options = kernel.std_options.default();

/// Route std.debug / std.log output to the serial port in normal builds,
/// or to the capture buffer in test builds.
pub const std_options_debug_io: std.Io = kernel.io.make(if (builtin.is_test) .buffer else .serial);

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
    if (builtin.is_test) {
        try runTests();
        return;
    }

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

fn runTests() !void {
    const tty = kernel.serial.tty;
    try tty.setColor(.dim);
    try tty.writer.writeAll("start\n");
    try tty.writer.print("└─ {d} tests\n", .{builtin.test_functions.len});
    try tty.setColor(.reset);

    var failed: usize = 0;
    var skipped: usize = 0;
    for (builtin.test_functions) |t| {
        kernel.log.test_name = t.name;
        t.func() catch |err| {
            if (err == error.SkipZigTest) {
                skipped += 1;
                continue;
            }
            try tty.setColor(.bright_red);
            try tty.writer.writeAll("error:");
            try tty.setColor(.reset);
            try tty.writer.writeAll(" '");
            try tty.writer.writeAll(t.name);
            try tty.writer.writeAll("' failed: ");
            try tty.writer.writeAll(kernel.io.writer.buffer);
            kernel.io.writer.end = 0;
            try tty.writer.writeAll("\n");
            if (@errorReturnTrace()) |trace| {
                std.debug.writeErrorReturnTrace(trace, tty) catch |err2| {
                    log.warn("Failed to write test error trace: {}.", .{err2});
                };
            }
            failed += 1;
        };
    }
    try tty.setColor(.dim);
    try tty.writer.writeAll("end\n");
    try tty.writer.print("└─ {d}/{d} passed", .{
        builtin.test_functions.len - failed - skipped,
        builtin.test_functions.len,
    });

    if (failed > 0) {
        try tty.writer.writeAll(", ");
        try tty.setColor(.red);
        try tty.writer.print("{d} failed", .{failed});
        try tty.setColor(.reset);
    }

    if (skipped > 0) {
        try tty.writer.writeAll(", ");
        try tty.setColor(.yellow);
        try tty.writer.print("{d} skipped", .{skipped});
        try tty.setColor(.reset);
    }
    try tty.setColor(.reset);
    kernel.serial.write("\n");
    if (failed > 0) {
        return error.TestFailed;
    }
}
