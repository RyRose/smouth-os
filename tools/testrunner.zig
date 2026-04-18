//! Test runner for the x86 kernel. This is a freestanding Zig program that
//! links against the kernel's code and runs tests in a simulated environment.

const arch = @import("arch");
const std = @import("std");

// Standard options for the kernel.
// Must match this specific signature to be used by Zig's standard library.
pub const std_options = arch.kernel.std_options.default();

/// Route std.debug / std.log output to the capture buffer.
pub const std_options_debug_io: std.Io = arch.kernel.io.make(.buffer);

/// Panic handler for the kernel.
/// Must match this specific signature to be used by Zig's standard library.
pub const panic = arch.kernel.panic.panic;

/// Overrides std.debug.SelfInfo for freestanding kernel DWARF stack traces.
pub const debug = arch.kernel.debug.self;

comptime {
    // Link initial boot code.
    _ = arch.x86.boot;
}
