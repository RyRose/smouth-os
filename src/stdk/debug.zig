const std = @import("std");

pub fn printLineInfo(
    writer: *std.Io.Writer,
    source_location: ?std.debug.SourceLocation,
    address: usize,
    symbol_name: []const u8,
    compile_unit_name: []const u8,
    tty_mode: std.Io.Terminal.Mode,
    comptime printLineFromFile: anytype,
) !void {
    const terminal: std.Io.Terminal = .{ .writer = writer, .mode = tty_mode };
    try terminal.setColor(.bold);

    if (source_location) |*sl| {
        try writer.print("{s}:{d}:{d}", .{ sl.file_name, sl.line, sl.column });
    } else {
        try writer.writeAll("???:?:?");
    }

    try terminal.setColor(.reset);
    try writer.writeAll(": ");
    try terminal.setColor(.dim);
    try writer.print("0x{x} in {s} ({s})", .{ address, symbol_name, compile_unit_name });
    try terminal.setColor(.reset);
    try writer.writeAll("\n");

    // Show the matching source code line if possible
    if (source_location) |sl| {
        if (printLineFromFile(terminal, sl)) {
            if (sl.column > 0) {
                // The caret already takes one char
                const space_needed = @as(usize, @intCast(sl.column - 1));

                try writer.splatByteAll(' ', space_needed);
                try terminal.setColor(.green);
                try writer.writeAll("^");
                try terminal.setColor(.reset);
            }
            try writer.writeAll("\n");
        } else |err| switch (err) {
            error.EndOfFile, error.FileNotFound => {},
            else => return err,
        }
    }
}
