//! x86-specific IDT interrupt handlers.

const std = @import("std");

const kernel = @import("kernel");

const log = std.log.scoped(.x86);

/// Interrupt stack frame passed to x86 interrupt handlers.
const InterruptStackFrame = extern struct {
    instruction_pointer: usize,
    code_segment: u64,
    cpu_flags: u64,
    stack_pointer: u64,
    stack_segment: u64,
};

pub fn double_fault_handler(
    frame: *InterruptStackFrame,
    error_code: u32,
) callconv(.{ .x86_interrupt = .{} }) void {
    _ = error_code;
    var addrs = [_]usize{frame.instruction_pointer};

    const trace: std.debug.StackTrace = .{
        .return_addresses = addrs[0..],
        .skipped = .none,
    };
    log.err("Double fault occurred at:", .{});
    std.debug.writeStackTrace(&trace, kernel.serial.tty) catch |err| {
        log.err("Failed to print stack trace for double fault: {}", .{err});
    };
    std.debug.panic("Double fault occurred!", .{});
}
