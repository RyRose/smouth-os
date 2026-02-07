//! Serial port communication for x86 architecture.

const std = @import("std");

const arch = @import("arch");
const ioport = arch.x86.ioport;

const sync = @import("sync.zig");

// COM1 base port
const base: u16 = 0x3F8;

// SpinLock to provide thread-safe access to the serial port.
// Should be grabbed by any code wanting to write to the serial port.
pub var lock = sync.SpinLock(bool).init(false);

/// Initialize the serial port.
pub fn init() void {
    lock.lock();
    defer lock.unlock();
    if (lock.value) {
        writeString("SERIAL: Serial port already initialized.\n");
        return;
    }
    lock.value = true;

    // Disable interrupts
    ioport.outb(base + 1, 0x00);

    // Enable DLAB
    ioport.outb(base + 3, 0x80);

    // Set baud rate divisor to 3 (38400)
    ioport.outb(base + 0, 0x03); // low byte
    ioport.outb(base + 1, 0x00); // high byte

    // 8 bits, no parity, one stop bit
    ioport.outb(base + 3, 0x03);

    // Enable FIFO, clear, 14-byte threshold
    ioport.outb(base + 2, 0xC7);

    // IRQs enabled, RTS/DSR set
    ioport.outb(base + 4, 0x0B);
}

fn isTransmitEmpty() bool {
    return (ioport.inb(base + 5) & 0x20) == 0;
}

/// Write a byte to the serial port.
pub fn writeByte(b: u8) void {
    while (isTransmitEmpty()) {}
    ioport.outb(base, b);
}

/// Write a string to the serial port.
pub fn writeString(s: []const u8) void {
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
        writeString(w.buffer[0..w.end]);
        w.end = 0;
    }

    var consumed: usize = 0;
    for (data, 0..) |slice, i| {
        const repeat = if (i + 1 == data.len) splat else 1;
        for (0..repeat) |_| {
            writeString(slice);
            consumed += slice.len;
        }
    }
    return consumed;
}

/// Get a writer that writes to the serial port.
pub fn writer(buffer: []u8) std.io.Writer {
    return .{
        .vtable = &.{
            .drain = drain,
            .flush = std.io.Writer.defaultFlush,
            .rebase = std.io.Writer.failingRebase,
        },
        .buffer = buffer,
    };
}
