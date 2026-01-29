//! Panic handling for the kernel.
//! Logs panic messages to the serial port and halts the system.
//! Uses a fixed-size buffer for formatting panic messages.
//! Does not allocate memory dynamically during panic handling.
//! Includes error return trace logging if available.
//! Halts the system by writing to the appropriate I/O port.
//!

const builtin = @import("builtin");
const std = @import("std");

const arch = @import("arch");

const ioport = arch.x86.ioport;
const serial = @import("serial.zig");

var panic_buffer: [1024]u8 = undefined;
var panic_allocator_buffer: [1024]u8 = undefined;
var panic_allocator = std.heap.FixedBufferAllocator.init(&panic_allocator_buffer);

pub const panic = std.debug.FullPanic(innerPanic);

fn log(msg: []const u8) void {
    serial.writeString("PANIC: ");
    serial.writeString(msg);
    serial.writeString("\n");
}

fn logF(comptime fmt: []const u8, args: anytype) void {
    tryLogF(fmt, args) catch {
        log(fmt);
    };
}

fn tryLogF(comptime fmt: []const u8, args: anytype) !void {
    const buf = try std.fmt.bufPrint(&panic_buffer, fmt, args);
    serial.writeString("PANIC: ");
    serial.writeString(buf);
    serial.writeString("\n");
}

fn innerPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    log(msg);

    logF("First trace address = 0x{x}", .{first_trace_addr.?});

    logErrorReturnTrace();
    log("System halted.");
    shutdown();
}

fn logErrorReturnTrace() void {
    const trace: ?*std.builtin.StackTrace = @errorReturnTrace();
    if (trace == null) {
        return;
    }

    const stackTrace: *std.builtin.StackTrace = trace.?;
    if (stackTrace.index <= 0) {
        return;
    }

    logF("Error return trace ({d} frames, {d} elements):", .{
        stackTrace.instruction_addresses.len,
        stackTrace.index,
    });
    for (stackTrace.instruction_addresses) |addr| {
        if (addr == 0) continue;
        logF("0x{x}", .{addr});
    }
}

fn shutdown() noreturn {
    ioport.outw(0xF4, 0);
    while (true) {}
}
