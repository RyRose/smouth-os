const std = @import("std");

const embed = @import("embed");
const stdk = @import("stdk");

const dwarf = @import("dwarf.zig");
const serial = @import("serial.zig");

// 3 MiB buffer for debug info
var debug_buffer: [3000 * 1024]u8 = undefined;
var debug_allocator = std.heap.FixedBufferAllocator.init(&debug_buffer);
var debug_data: stdk.Dwarf = undefined;

pub fn init() !void {
    debug_data = try dwarf.open(debug_allocator.allocator());
}

pub fn printStackTrace(frame_address: ?usize) !void {
    var rbp: usize = frame_address orelse @frameAddress();
    while (rbp != 0) {
        const frame: *[2]usize = @ptrFromInt(rbp);

        const prev_rbp = frame[0];
        const addr = frame[1];
        if (addr == 0) {
            break;
        }

        try printLineInfo(addr);
        rbp = prev_rbp;
    }
}

pub fn printErrorReturnTrace() !bool {
    const trace: ?*std.builtin.StackTrace = @errorReturnTrace();
    if (trace == null) {
        return false;
    }
    const stackTrace = trace.?;

    const frames = @min(stackTrace.instruction_addresses.len, stackTrace.index);
    if (frames == 0) {
        return false;
    }

    for (stackTrace.instruction_addresses, 0..) |addr, idx| {
        if (idx >= frames) break;
        try printLineInfo(addr);
    }
    return true;
}

pub fn printLineInfo(addr: usize) !void {
    var arena = std.heap.ArenaAllocator.init(debug_allocator.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();
    const symbols = try debug_data.getSymbol(allocator, addr);
    try stdk.debug.printLineInfo(
        &serial.writer,
        symbols.source_location,
        addr,
        symbols.name,
        symbols.compile_unit_name,
        .escape_codes,
        printLine,
    );
}

/// Prints the source line corresponding to the given source location to the provided writer.
pub fn printLine(
    writer: *std.io.Writer,
    source_location: std.debug.SourceLocation,
) !void {
    const data = embed.srcFiles.get(source_location.file_name) orelse
        return error.FileNotFound;

    var current_line: usize = 1;
    var line_start: usize = 0;

    // Seek to the start of the requested line
    while (current_line < source_location.line) {
        if (std.mem.indexOfScalar(u8, data[line_start..], '\n')) |pos| {
            line_start += pos + 1;
            current_line += 1;
        } else {
            return error.EndOfFile;
        }
    }

    const rest = data[line_start..];

    if (std.mem.indexOfScalar(u8, rest, '\n')) |pos| {
        try writeWithTabsReplaced(writer, rest[0 .. pos + 1]);
    } else {
        try writeWithTabsReplaced(writer, rest);
        try writer.writeByte('\n');
    }
}

/// Writes the given string to the writer, replacing tabs with spaces for better
/// formatting in serial output.
fn writeWithTabsReplaced(writer: *std.io.Writer, s: []const u8) !void {
    var i: usize = 0;
    while (i < s.len) {
        if (s[i] == '\t') {
            try writer.writeByte(' ');
            i += 1;
        } else {
            const start = i;
            while (i < s.len and s[i] != '\t') : (i += 1) {}
            try writer.writeAll(s[start..i]);
        }
    }
}
