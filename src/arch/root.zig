//! This file is the root of the architecture-specific code. It re-exports the
//! architecture-specific modules based on the target architecture.

const std = @import("std");
const builtin = @import("builtin");

pub const util = @import("util.zig");

/// Re-export the AArch64 architecture modules.
pub const aarch64 = @import("aarch64/root.zig");

/// Re-export the x86 architecture modules.
pub const x86 = @import("x86/root.zig");

/// Re-export the architecture-specific modules based on the target architecture.
/// This allows the rest of the kernel code to use `arch` as a single entry
/// point for architecture-specific functionality.
pub const self = switch (builtin.cpu.arch) {
    .aarch64 => aarch64,
    .x86 => x86,
    else => @compileError("Unsupported architecture: " ++ @tagName(builtin.cpu.arch)),
};

test {
    std.testing.refAllDecls(util);
    if (builtin.os.tag != .freestanding) return error.SkipZigTest;
    std.testing.refAllDecls(self);
}
