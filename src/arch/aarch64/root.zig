//! Root module for the AArch64 architecture.

const std = @import("std");

pub const boot = @import("boot.zig");
pub const init = @import("init.zig");
pub const serial = @import("serial.zig");
pub const shutdown = @import("shutdown.zig");
pub const virtio = @import("virtio.zig");

comptime {
    @import("os").arch.util.assertFreestandingArch(.aarch64);
}

test {
    std.testing.refAllDecls(@This());
}
