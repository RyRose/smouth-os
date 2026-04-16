const arch = @import("arch");

// Standard options for the kernel.
// Must match this specific signature to be used by Zig's standard library.
pub const std_options = arch.x86.testboot.std_options;

/// Panic handler for the kernel.
/// Must match this specific signature to be used by Zig's standard library.
pub const panic = arch.x86.testboot.panic;

comptime {
    // Link initial boot code.
    _ = arch.x86.testboot;
}
