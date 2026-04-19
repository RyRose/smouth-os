const std = @import("std");
const builtin = @import("builtin");

const log = @import("log.zig");

pub fn default() std.Options {
    return .{
        .logFn = if (builtin.os.tag == .freestanding) log.defaultLog else std.log.defaultLog,
    };
}
