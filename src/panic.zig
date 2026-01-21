const std = @import("std");
const serial = @import("serial.zig");
const ioport = @import("ioport.zig");

var panic_buffer: [1024]u8 = undefined;
var panic_allocator_buffer: [1024]u8 = undefined;
var panic_allocator = std.heap.FixedBufferAllocator.init(&panic_allocator_buffer);

pub fn panic(msg: []const u8, trace: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    serial.writeString("PANIC: ");
    serial.writeString(msg);
    serial.writeString("\n");
    serial.writeString("----- Stack Trace -----\n");
    serial.writeString("Use addr2line or a similar tool to decode addresses.\n");

    var writer = std.Io.Writer.fixed(&panic_buffer);

    if (trace) |stackTrace| {
        writer.print("Stack trace ({d} frames, {d} index):\n", .{
            stackTrace.instruction_addresses.len,
            stackTrace.index,
        }) catch {
            serial.writeString("Failed to write stack trace header.\n");
        };

        for (stackTrace.instruction_addresses) |addr| {
            if (addr == 0) continue;
            writer.print("0x{x}\n", .{addr}) catch {
                serial.writeString("Failed to write stack trace address.\n");
            };
        }
    }

    serial.writeString(writer.buffered());
    serial.writeString("System halted.\n");

    // Halt the CPU using QEMU shutdown port with a non-zero exit code
    // or an infinite loop.
    ioport.outw(0xF4, 0);
    while (true) {}
}
