//! Panic handling for the kernel.
//! Dumps panic information to the log and halts the system.
//! Terminates the active QEMU platform with a failure status.
//!

const std = @import("std");
const arch = @import("os").arch;

const serial = @import("serial.zig");

const log = std.log.scoped(.PANIC);

/// Panic handler for the kernel. Logs the panic message and stack trace, then
/// halts the system.
pub const handler = std.debug.FullPanic(innerPanic);

fn innerPanic(msg: []const u8, return_address: ?usize) noreturn {
    log.err("{s}", .{msg});

    if (return_address) |addr| {
        log.err("Panic stack trace: {x}", .{addr});
    } else {
        log.err("Panic stack trace:", .{});
    }
    std.debug.writeCurrentStackTrace(
        .{ .allow_unsafe_unwind = true },
        serial.tty,
    ) catch |err| {
        log.err("Failed to log stack trace: {}", .{err});
    };

    if (@errorReturnTrace()) |trace| {
        log.err("Panic return trace:", .{});
        std.debug.writeErrorReturnTrace(trace, serial.tty) catch |err| {
            log.warn("Failed to write error trace: {}.", .{err});
        };
    }
    log.err("System is shutting down.", .{});
    badShutdown();
}

/// Terminates the active QEMU platform with a nonzero status.
fn badShutdown() noreturn {
    arch.self.shutdown.run(false);
}
