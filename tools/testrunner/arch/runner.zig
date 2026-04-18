const arch = @import("arch");

// Standard options for the kernel.
// Must match this specific signature to be used by Zig's standard library.
pub const std_options = arch.kernel.std_options.default();

/// Panic handler for the kernel.
/// Must match this specific signature to be used by Zig's standard library.
pub const panic = arch.kernel.panic.panic;

comptime {
    // Link initial boot code.
    _ = arch.x86.testboot;
}
