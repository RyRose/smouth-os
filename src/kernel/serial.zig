//! Architecture-neutral serial-console facade.

const os = @import("os");
const std = @import("std");

/// Lock shared by serial logging and direct console writes.
pub const lock: *os.kernel.sync.SpinLock(bool) = @constCast(&os.arch.self.serial.lock);

/// Terminal used by logging, diagnostics, and test output.
pub const tty: std.Io.Terminal = os.arch.self.serial.tty;

/// Serial writer construction options.
pub const WriterOpts = os.arch.serial.WriterOpts;

/// Initializes the active architecture's serial console.
pub fn init() void {
    os.arch.self.serial.init();
}

/// Writes `data` to the active architecture's serial console.
pub fn write(data: []const u8) void {
    os.arch.self.serial.write(data);
}

/// Returns a writer backed by the active architecture's serial console.
pub fn newWriter(options: ?WriterOpts) @import("std").Io.Writer {
    return os.arch.self.serial.newWriter(options);
}
