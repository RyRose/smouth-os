const std = @import("std");

pub const kernel = @import("kernel");

pub const x86 = @import("x86/root.zig");

test {
    std.testing.refAllDecls(@This());
}
