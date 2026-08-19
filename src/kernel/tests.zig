const builtin = @import("builtin");
const std = @import("std");
const kernel = @import("os").kernel;

const log = std.log.scoped(.tests);

pub fn run() !void {
    const tty = kernel.serial.tty;
    try tty.setColor(.dim);
    try tty.writer.writeAll("start\n");
    try tty.writer.print("└─ {d} tests\n", .{builtin.test_functions.len});
    try tty.setColor(.reset);

    var failed: usize = 0;
    var skipped: usize = 0;
    for (builtin.test_functions) |t| {
        t.func() catch |err| {
            if (err == error.SkipZigTest) {
                skipped += 1;
                continue;
            }
            try tty.setColor(.bright_red);
            try tty.writer.writeAll("error:");
            try tty.setColor(.reset);
            try tty.writer.writeAll(" '");
            try tty.writer.writeAll(t.name);
            try tty.writer.writeAll("' failed: ");
            try tty.writer.writeAll(kernel.io.writer.buffer);
            kernel.io.writer.end = 0;
            try tty.writer.writeAll("\n");
            if (@errorReturnTrace()) |trace| {
                std.debug.writeErrorReturnTrace(trace, tty) catch |err2| {
                    log.warn("Failed to write test error trace: {}.", .{err2});
                };
            }
            failed += 1;
        };
    }
    try tty.setColor(.dim);
    try tty.writer.writeAll("end\n");
    try tty.writer.print("└─ {d}/{d} passed", .{
        builtin.test_functions.len - failed - skipped,
        builtin.test_functions.len,
    });

    if (failed > 0) {
        try tty.writer.writeAll(", ");
        try tty.setColor(.red);
        try tty.writer.print("{d} failed", .{failed});
        try tty.setColor(.reset);
    }

    if (skipped > 0) {
        try tty.writer.writeAll(", ");
        try tty.setColor(.yellow);
        try tty.writer.print("{d} skipped", .{skipped});
        try tty.setColor(.reset);
    }
    try tty.setColor(.reset);
    try tty.writer.writeAll("\n");
    if (failed > 0) return error.TestFailed;
}
