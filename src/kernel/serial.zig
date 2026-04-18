//! Serial port communication for arch.x86 architecture.

const builtin = @import("builtin");
const std = @import("std");

const arch = @import("arch");

const sync = @import("sync.zig");

const log = std.log.scoped(.serial);

// COM1 base port
const base: u16 = 0x3F8;

/// SpinLock to provide thread-safe access to the serial port.
/// Should be grabbed by any code wanting to write to the serial port.
pub var lock = sync.SpinLock(bool).init(false);

// A buffer for the serial writer. This is used to store data before it is
const serial_buffer: [0]u8 = undefined;

/// A writer that writes to the serial port. This is used for logging and debugging.
pub var writer = newWriter(&serial_buffer);

pub const tty = std.Io.Terminal{
    .writer = &writer,
    .mode = .escape_codes,
};

/// Initialize the serial port.
/// This should be called once during kernel initialization before any writes
/// to the serial port are made. This function is thread-safe and can be called
/// multiple times, but only the first call will have an effect. Subsequent
/// calls will print a warning message to the serial port.
pub fn init() void {
    lock.lock();
    defer lock.unlock();
    if (lock.value) {
        log.warn("SERIAL: Serial port already initialized.", .{});
        return;
    }
    lock.value = true;

    // Disable interrupts
    arch.x86.insn.outb(base + 1, 0x00);

    // Enable DLAB
    arch.x86.insn.outb(base + 3, 0x80);

    // Set baud rate divisor to 3 (38400)
    arch.x86.insn.outb(base + 0, 0x03); // low byte
    arch.x86.insn.outb(base + 1, 0x00); // high byte

    // 8 bits, no parity, one stop bit
    arch.x86.insn.outb(base + 3, 0x03);

    // Enable FIFO, clear, 14-byte threshold
    arch.x86.insn.outb(base + 2, 0xC7);

    // IRQs enabled, RTS/DSR set
    arch.x86.insn.outb(base + 4, 0x0B);
}

/// Check if the transmit buffer is empty.
fn isTransmitEmpty() bool {
    return (arch.x86.insn.inb(base + 5) & 0x20) == 0;
}

/// Write a byte to the serial port.
fn writeByte(b: u8) void {
    while (isTransmitEmpty()) {}
    arch.x86.insn.outb(base, b);
}

/// Write a string to the serial port.
pub fn write(s: []const u8) void {
    for (s) |c| {
        writeByte(c);
    }
}

fn drain(
    w: *std.Io.Writer,
    data: []const []const u8,
    splat: usize,
) std.Io.Writer.Error!usize {
    if (w.end > 0) {
        write(w.buffer[0..w.end]);
        w.end = 0;
    }

    var consumed: usize = 0;
    for (data, 0..) |slice, i| {
        const repeat = if (i + 1 == data.len) splat else 1;
        for (0..repeat) |_| {
            write(slice);
            consumed += slice.len;
        }
    }
    return consumed;
}

/// Get a writer that writes to the serial port.
pub fn newWriter(buffer: []u8) std.Io.Writer {
    return .{
        .vtable = &.{
            .drain = drain,
            .flush = std.Io.Writer.defaultFlush,
            .rebase = std.Io.Writer.failingRebase,
        },
        .buffer = buffer,
    };
}

test "serial writer" {
    try arch.freestanding();

    var buffer: [100]u8 = undefined;
    var w = newWriter(&buffer);
    const data = "Hello, world!";
    const consumed = try w.write(data);
    try std.testing.expectEqual(consumed, data.len);
    try std.testing.expectEqualStrings(data, buffer[0..data.len]);
}
