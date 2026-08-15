//! Top-level source module for smouth OS.

const builtin = @import("builtin");
const std = @import("std");

pub const arch = @import("arch/root.zig");
pub const embed = @import("embed.zig");
pub const kernel = @import("kernel/root.zig");

test {
    std.testing.refAllDecls(@This());
}
