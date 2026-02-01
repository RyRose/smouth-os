const std = @import("std");

pub fn printLineInfo(
    writer: *std.Io.Writer,
    source_location: ?std.debug.SourceLocation,
    address: usize,
    symbol_name: []const u8,
    compile_unit_name: []const u8,
    tty_config: std.io.tty.Config,
    comptime printLineFromFile: anytype,
) !void {
    try tty_config.setColor(writer, .bold);

    if (source_location) |*sl| {
        try writer.print("{s}:{d}:{d}", .{ sl.file_name, sl.line, sl.column });
    } else {
        try writer.writeAll("???:?:?");
    }

    try tty_config.setColor(writer, .reset);
    try writer.writeAll(": ");
    try tty_config.setColor(writer, .dim);
    try writer.print("0x{x} in {s} ({s})", .{ address, symbol_name, compile_unit_name });
    try tty_config.setColor(writer, .reset);
    try writer.writeAll("\n");

    // Show the matching source code line if possible
    if (source_location) |sl| {
        if (printLineFromFile(writer, sl)) {
            if (sl.column > 0) {
                // The caret already takes one char
                const space_needed = @as(usize, @intCast(sl.column - 1));

                try writer.splatByteAll(' ', space_needed);
                try tty_config.setColor(writer, .green);
                try writer.writeAll("^");
                try tty_config.setColor(writer, .reset);
            }
            try writer.writeAll("\n");
        } else |err| switch (err) {
            error.EndOfFile, error.FileNotFound => {},
            else => return err,
        }
    }
}
