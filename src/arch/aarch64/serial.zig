//! PL011 UART support for QEMU's AArch64 `virt` machine.

const std = @import("std");

const sync = @import("os").kernel.sync;

/// PL011 data register.
const data_register: *volatile u32 = @ptrFromInt(0x0900_0000);
/// PL011 flag register.
const flag_register: *volatile const u32 = @ptrFromInt(0x0900_0018);
/// PL011 integer baud divisor register.
const integer_baud_register: *volatile u32 = @ptrFromInt(0x0900_0024);
/// PL011 fractional baud divisor register.
const fractional_baud_register: *volatile u32 = @ptrFromInt(0x0900_0028);
/// PL011 line-control register.
const line_control_register: *volatile u32 = @ptrFromInt(0x0900_002C);
/// PL011 control register.
const control_register: *volatile u32 = @ptrFromInt(0x0900_0030);
/// PL011 interrupt-mask register.
const interrupt_mask_register: *volatile u32 = @ptrFromInt(0x0900_0038);
/// PL011 interrupt-clear register.
const interrupt_clear_register: *volatile u32 = @ptrFromInt(0x0900_0044);

/// PL011 transmit FIFO full flag.
const transmit_fifo_full: u32 = 1 << 5;
/// Eight-bit words in PL011 line control.
const word_length_8: u32 = 0b11 << 5;
/// PL011 FIFO enable flag.
const fifo_enable: u32 = 1 << 4;
/// PL011 UART enable flag.
const uart_enable: u32 = 1;
/// PL011 transmit enable flag.
const transmit_enable: u32 = 1 << 8;
/// PL011 receive enable flag.
const receive_enable: u32 = 1 << 9;

/// Serial lock and initialization state.
pub var lock = sync.SpinLock(bool).init(false);

/// Writer routed to the PL011 UART.
var writer = newWriter(null);

/// Terminal used by logging and stack traces.
pub const tty = std.Io.Terminal{
    .writer = &writer,
    .mode = .escape_codes,
};

/// Configures QEMU's 24 MHz PL011 UART for 115200-bit/s serial output.
pub fn init() void {
    lock.lock();
    defer lock.unlock();
    if (lock.value) return;
    lock.value = true;

    control_register.* = 0;
    interrupt_mask_register.* = 0;
    interrupt_clear_register.* = 0x7FF;
    integer_baud_register.* = 13;
    fractional_baud_register.* = 2;
    line_control_register.* = word_length_8 | fifo_enable;
    control_register.* = uart_enable | transmit_enable | receive_enable;
}

/// Writes a byte once the PL011 transmit FIFO has space.
fn writeByte(byte: u8) void {
    while ((flag_register.* & transmit_fifo_full) != 0) {}
    data_register.* = byte;
}

/// Writes UTF-8 data to the PL011 UART.
pub fn write(data: []const u8) void {
    for (data) |byte| writeByte(byte);
}

/// Drains an `std.Io.Writer` into the UART.
fn drain(writer_interface: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
    if (writer_interface.end > 0) {
        write(writer_interface.buffer[0..writer_interface.end]);
        writer_interface.end = 0;
    }
    var consumed: usize = 0;
    for (data, 0..) |slice, index| {
        const repeat = if (index + 1 == data.len) splat else 1;
        for (0..repeat) |_| {
            write(slice);
            consumed += slice.len;
        }
    }
    return consumed;
}

/// Options for constructing a PL011-backed writer.
pub const WriterOpts = struct {
    /// Writer buffer; zero length means writes drain immediately.
    buffer: ?[]u8 = &[0]u8{},
    /// Flush implementation used by the writer.
    flush: *const fn (writer_interface: *std.Io.Writer) std.Io.Writer.Error!void = std.Io.Writer.defaultFlush,
};

/// Returns a writer that emits data through the PL011 UART.
pub fn newWriter(options: ?WriterOpts) std.Io.Writer {
    const opts = options orelse WriterOpts{};
    return .{
        .vtable = &.{ .drain = drain, .flush = opts.flush },
        .buffer = opts.buffer.?,
    };
}
