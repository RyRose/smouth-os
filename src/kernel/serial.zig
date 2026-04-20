//! Serial port communication for arch.x86 architecture.

const std = @import("std");
const builtin = @import("builtin");

const arch = @import("arch");

const sync = @import("sync.zig");

const log = std.log.scoped(.serial);

/// SpinLock to provide thread-safe access to the serial port.
/// Should be grabbed by any code wanting to write to the serial port.
pub var lock = sync.SpinLock(bool).init(false);

/// A writer that writes to the serial port. This is used for logging and debugging.
/// Not buffered to ensure that writes to the serial port are not delayed.
var writer = newWriter(null);

/// A terminal that writes to the serial port. This is used for logging and debugging.
/// Not buffered to ensure that writes to the serial port are not delayed.
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
    arch.x86.ioport.outb(.com1_ier, 0x00);

    // Enable DLAB
    arch.x86.ioport.outb(.com1_lcr, 0x80);

    // Set baud rate divisor to 3 (38400)
    arch.x86.ioport.outb(.com1_data, 0x03); // low byte
    arch.x86.ioport.outb(.com1_ier, 0x00); // high byte

    // 8 bits, no parity, one stop bit
    arch.x86.ioport.outb(.com1_lcr, 0x03);

    // Enable FIFO, clear, 14-byte threshold
    arch.x86.ioport.outb(.com1_iir_fcr, 0xC7);

    // IRQs enabled, RTS/DSR set
    arch.x86.ioport.outb(.com1_mcr, 0x0B);
}

/// Check if the transmit buffer is empty.
fn isTransmitEmpty() bool {
    return (arch.x86.ioport.inb(.com1_lsr) & 0x20) == 0;
}

/// Write a byte to the serial port.
fn writeByte(b: u8) void {
    while (isTransmitEmpty()) {}
    arch.x86.ioport.outb(.com1_data, b);
}

/// Write a string to the serial port.
pub fn write(s: []const u8) void {
    for (s) |c| writeByte(c);
}

/// Sends the buffered bytes and bytes provided in `data` to the serial port,
/// repeating the last slice `splat` times.
fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
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

/// Options for creating a serial writer.
pub const WriterOpts = struct {
    /// A buffer for the writer. Defaults to a zero-length slice, which means
    /// the writer is unbuffered and writes directly to the serial port.
    buffer: ?[]u8 = &[0]u8{},
    /// A flush function. Defaults to a function that repeatedly drains until
    /// the transmit buffer is empty, to ensure that all data is sent before
    /// returning from flush.
    flush: *const fn (w: *std.Io.Writer) std.Io.Writer.Error!void = std.Io.Writer.defaultFlush,
};

/// Returns a writer that writes to the serial port.
pub fn newWriter(options: ?WriterOpts) std.Io.Writer {
    const opts: WriterOpts = options orelse .{};
    return .{
        .vtable = &.{
            .drain = drain,
            .flush = opts.flush,
        },
        .buffer = opts.buffer.?,
    };
}

test "serial writer" {
    try arch.freestanding();

    var buffer: [100]u8 = undefined;
    var w = newWriter(.{ .buffer = &buffer });
    const data = "Hello, world!";
    const consumed = try w.write(data);
    try std.testing.expectEqual(consumed, data.len);
    try std.testing.expectEqualStrings(data, buffer[0..data.len]);
}
