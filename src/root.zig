//! Top-level namespace for the smouth OS source module.

const builtin = @import("builtin");
const std = @import("std");

pub const arch = @import("arch/root.zig");
pub const kernel = @import("kernel/root.zig");

test {
    if (builtin.os.tag == .freestanding) {
        std.testing.refAllDecls(@This());
    } else {
        std.testing.refAllDecls(kernel);
    }
}
