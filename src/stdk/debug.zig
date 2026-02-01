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

pub fn printLine(writer: *std.io.Writer, source_location: std.debug.SourceLocation) !void {
    _ = writer;
    _ = source_location;
}

pub fn printLineFromFileAnyOs(writer: *std.io.Writer, source_location: std.debug.SourceLocation) !void {
    // Need this to always block even in async I/O mode, because this could potentially
    // be called from e.g. the event loop code crashing.
    var f = try std.fs.cwd().openFile(source_location.file_name, .{});
    defer f.close();

    var buf: [4096]u8 = undefined;
    var amt_read = try f.read(buf[0..]);
    const line_start = seek: {
        var current_line_start: usize = 0;
        var next_line: usize = 1;
        while (next_line != source_location.line) {
            const slice = buf[current_line_start..amt_read];
            if (std.mem.indexOfScalar(u8, slice, '\n')) |pos| {
                next_line += 1;
                if (pos == slice.len - 1) {
                    amt_read = try f.read(buf[0..]);
                    current_line_start = 0;
                } else current_line_start += pos + 1;
            } else if (amt_read < buf.len) {
                return error.EndOfFile;
            } else {
                amt_read = try f.read(buf[0..]);
                current_line_start = 0;
            }
        }
        break :seek current_line_start;
    };
    const slice = buf[line_start..amt_read];
    if (std.mem.indexOfScalar(u8, slice, '\n')) |pos| {
        const line = slice[0 .. pos + 1];
        std.mem.replaceScalar(u8, line, '\t', ' ');
        return writer.writeAll(line);
    } else { // Line is the last inside the buffer, and requires another read to find delimiter. Alternatively the file ends.
        std.mem.replaceScalar(u8, slice, '\t', ' ');
        try writer.writeAll(slice);
        while (amt_read == buf.len) {
            amt_read = try f.read(buf[0..]);
            if (std.mem.indexOfScalar(u8, buf[0..amt_read], '\n')) |pos| {
                const line = buf[0 .. pos + 1];
                std.mem.replaceScalar(u8, line, '\t', ' ');
                return writer.writeAll(line);
            } else {
                const line = buf[0..amt_read];
                std.mem.replaceScalar(u8, line, '\t', ' ');
                try writer.writeAll(line);
            }
        }
        // Make sure printing last line of file inserts extra newline
        try writer.writeByte('\n');
    }
}
