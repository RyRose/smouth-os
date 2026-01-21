//! Serial port communication for x86 architecture.

const ioport = @import("ioport.zig");
const sync = @import("sync.zig");

// COM1 base port
const base: u16 = 0x3F8;

var initialized = sync.SpinLock(bool).init(false);

/// Initialize the serial port.
pub fn init() void {
    initialized.lock();
    defer initialized.unlock();
    if (initialized.value) {
        writeString("SERIAL: Serial port already initialized.\n");
        return;
    }
    initialized.value = true;

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
    ioport.outb(base + 0, b);
}

/// Write a string to the serial port.
pub fn writeString(s: []const u8) void {
    for (s) |c| {
        writeByte(c);
    }
}
