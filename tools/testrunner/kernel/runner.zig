//! Test runner for the kernel. This is a freestanding Zig program that links
//! against the kernel's code and runs tests in a simulated environment.

const kernel = @import("kernel");
const std = @import("std");

// Standard options for the kernel.
// Must match this specific signature to be used by Zig's standard library.
pub const std_options = kernel.std_options.default();

/// Route std.debug / std.log output to the serial port.
pub const std_options_debug_io: std.Io = kernel.io.io;

/// Panic handler for the kernel.
/// Must match this specific signature to be used by Zig's standard library.
pub const panic = kernel.panic.panic;

/// Overrides std.debug.SelfInfo for freestanding kernel DWARF stack traces.
pub const debug = kernel.debug.self;

comptime {
    // Link initial boot code.
    _ = kernel.arch.x86.testboot;
}
