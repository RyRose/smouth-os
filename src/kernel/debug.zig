const std = @import("std");
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

    log("Error return trace ({d} frames, {d} elements):", .{
        stackTrace.instruction_addresses.len,
        stackTrace.index,
    });
    const allocator = debug_allocator.allocator();
    for (stackTrace.instruction_addresses) |addr| {
        if (addr == 0) continue;
        const symbols = try debug_data.getSymbol(allocator, addr);
        try stdk.debug.printLineInfo(
            &serial_writer,
            symbols.source_location,
            addr,
            symbols.name,
            symbols.compile_unit_name,
            .escape_codes,
            stdk.debug.printLine,
        );
    }
}
