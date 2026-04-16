const std = @import("std");

pub const arch = @import("arch/root.zig");
pub const kernel = @import("kernel/root.zig");

test "include all code for testing" {
    std.testing.refAllDeclsRecursive(@This());
}
