//! Root module for the AArch64 architecture.

const std = @import("std");
const builtin = @import("builtin");

pub const boot = @import("boot.zig");
pub const init = @import("init.zig");
pub const serial = @import("serial.zig");
pub const shutdown = @import("shutdown.zig");
pub const virtio = @import("virtio.zig");

// Ensure this code is only compiled for x86 freestanding targets.
comptime {
    if (builtin.target.cpu.arch != .aarch64) {
        @compileError(std.fmt.comptimePrint(
            "This code is only supported on AArch64 architecture but found {}",
            .{builtin.target.cpu.arch},
        ));
    }
    if (builtin.os.tag != .freestanding) {
        @compileError(std.fmt.comptimePrint(
            "This code is only supported on freestanding targets but found {}",
            .{builtin.os.tag},
        ));
    }
}
