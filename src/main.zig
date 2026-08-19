//! Entry point for the kernel. This is where the kernel starts executing after
//! boot. Also serves as the test runner when built with testing enabled.

const builtin = @import("builtin");
const os = @import("os");
const std = @import("std");

// Standard options for the kernel.
pub const std_options: std.Options = os.kernel.std_options.default();

/// Route std.debug / std.log output to the serial port in normal builds,
/// or to the capture buffer in test builds.
pub const std_options_debug_io: std.Io = os.kernel.io.make(if (builtin.is_test) .buffer else .serial);

/// Overrides std.debug.SelfInfo for freestanding kernel DWARF stack traces.
pub const debug = os.kernel.debug.self;

/// Panic handler for the kernel.
pub const panic = os.kernel.panic.handler;

// Link arch-specific boot code at compile time to load initial entrypoint.
comptime {
    _ = os.arch.self.boot;
}

pub fn main() anyerror!void {
    try os.kernel.init.run();
    if (comptime builtin.is_test) return os.kernel.tests.run();
    try os.kernel.main.run();
}
