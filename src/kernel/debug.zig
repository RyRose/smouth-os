const std = @import("std");

const embed = @import("embed");
const stdk = @import("stdk");

const dwarf = @import("dwarf.zig");
const serial = @import("serial.zig");

const serial_buffer: [0]u8 = undefined;
var serial_writer = serial.writer(&serial_buffer);

// 2 MiB buffer for debug info
var debug_buffer: [2000 * 1024]u8 = undefined;
var debug_allocator = std.heap.FixedBufferAllocator.init(&debug_buffer);
var debug_data: dwarf.Dwarf = undefined;

pub fn init() !void {
    debug_data = try dwarf.open(debug_allocator.allocator());
}

pub fn logErrorReturnTrace(comptime level: std.log.Level, comptime scope: @Type(.enum_literal)) !void {
    const trace: ?*std.builtin.StackTrace = @errorReturnTrace();
    if (trace == null) {
        return;
    }
    const stackTrace = trace.?;
    const log = struct {
        fn log(comptime format: []const u8, args: anytype) void {
            std.options.logFn(level, scope, format, args);
        }
    }.log;

    const frames = @min(stackTrace.instruction_addresses.len, stackTrace.index);
    log("Error return trace [{d} frame(s)]:", .{frames});

    const allocator = debug_allocator.allocator();
    for (stackTrace.instruction_addresses, 0..) |addr, idx| {
        if (idx >= frames) break;
        const symbols = try debug_data.getSymbol(allocator, addr);
        try stdk.debug.printLineInfo(
            &serial_writer,
            symbols.source_location,
            addr,
            symbols.name,
            symbols.compile_unit_name,
            .escape_codes,
            printLine,
        );
    }
}

pub fn printLine(
    writer: *std.io.Writer,
    source_location: std.debug.SourceLocation,
) !void {
    const data = embed.srcFiles.get(source_location.file_name) orelse return error.FileNotFound;

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
