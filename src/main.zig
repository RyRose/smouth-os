//! Entry point for the kernel. This is where the kernel starts executing after
//! boot. Also serves as the test runner when built with testing enabled.

const builtin = @import("builtin");
const std = @import("std");

const os = @import("os");
const arch = os.arch;
const kernel = os.kernel;

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
    try kernel.init.run();
    if (comptime builtin.is_test) return kernel.tests.run();
    try kernel.main.run();
}
