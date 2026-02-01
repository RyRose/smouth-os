const std = @import("std");
const log = @import("log.zig");

pub fn default() std.Options {
    return .{
        .logFn = log.defaultLog,
    };
}
