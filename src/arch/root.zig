const std = @import("std");

pub const x86 = @import("x86/root.zig");

test "include all code for testing" {
    std.testing.refAllDecls(@This());
}
