const gdt = @import("gdt.zig");
const idt = @import("idt.zig");
const ioport = @import("ioport.zig");
const log = @import("log.zig");
const panic = @import("panic.zig");
const serial = @import("serial.zig");
const sync = @import("sync.zig");

test "include modules for tests" {
    _ = gdt;
    _ = idt;
    _ = ioport;
    _ = log;
    _ = panic;
    _ = serial;
    _ = sync;
}
