//! x86-specific IDT interrupt handlers.

const builtin = @import("builtin");
const os = @import("os");
const std = @import("std");

const log = std.log.scoped(.x86);

/// Whether the test breakpoint handler has executed.
export var arch_x86_idt_breakpoint_handler_called: u8 = 0;

/// Interrupt stack frame passed to x86 interrupt handlers.
const InterruptStackFrame = extern struct {
    instruction_pointer: usize,
    code_segment: u64,
    cpu_flags: u64,
    stack_pointer: u64,
    stack_segment: u64,
};

/// Records invocation of the test breakpoint interrupt handler.
fn breakpoint_handler() callconv(.naked) noreturn {
    asm volatile (
        \\ movb $1, arch_x86_idt_breakpoint_handler_called
        \\ iret
    );
}

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
    std.debug.writeStackTrace(&trace, os.kernel.serial.tty) catch |err| {
        log.err("Failed to print stack trace for double fault: {}", .{err});
    };
    std.debug.panic("Double fault occurred!", .{});
}

test "breakpoint interrupt invokes its handler" {
    if (builtin.os.tag != .freestanding) return error.SkipZigTest;

    var original_idtr: u64 = 0;
    asm volatile ("sidt (%[idtr])"
        :
        : [idtr] "rax" (&original_idtr),
    );
    defer asm volatile ("lidt (%[idtr])"
        :
        : [idtr] "rax" (&original_idtr),
    );

    arch_x86_idt_breakpoint_handler_called = 0;
    const idt = @import("idt_table.zig");
    var table = idt.Table(256).init();
    table.register(.breakpoint, idt.Descriptor.init(.{
        .offset = @intCast(@intFromPtr(&breakpoint_handler)),
        .segment_selector = .{ .index = 1 },
    }));
    table.load();

    asm volatile ("int $3");
    try std.testing.expectEqual(@as(u8, 1), arch_x86_idt_breakpoint_handler_called);
}
