//! Test runner for the kernel. This is a freestanding Zig program that
//! links against the kernel's code and runs tests in a simulated environment.

const arch = @import("arch");
const builtin = @import("builtin");
const std = @import("std");
const kernel = arch.kernel;

// Standard options for the kernel.
pub const std_options: std.Options = kernel.std_options.default();

/// Route std.debug / std.log output to the capture buffer.
pub const std_options_debug_io: std.Io = kernel.io.make(.buffer);

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
