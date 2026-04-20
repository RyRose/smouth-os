const std = @import("std");
const builtin = @import("builtin");

pub const x86 = @import("x86/root.zig");

/// Returns error.SkipZigTest if the current target is not a freestanding
/// target, otherwise returns void. Inlined to allow compile-time evaluation
/// and optimization out of the check on non-freestanding targets.
pub inline fn freestanding() !void {
    if (builtin.os.tag != .freestanding) return error.SkipZigTest;
}

test {
    std.testing.refAllDecls(@This());
}
