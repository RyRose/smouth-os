const kernel = @import("kernel");

// Standard options for the kernel.
// Must match this specific signature to be used by Zig's standard library.
pub const std_options = kernel.std_options.default();

/// Panic handler for the kernel.
/// Must match this specific signature to be used by Zig's standard library.
pub const panic = kernel.panic.panic;

comptime {
    // Link initial boot code.
    _ = kernel.arch.x86.testboot;
}
