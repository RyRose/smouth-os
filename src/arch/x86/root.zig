//! Root module for x86 architecture.

const std = @import("std");

pub const boot = @import("boot.zig");
pub const gdt = @import("gdt.zig");
pub const gdt_table = @import("gdt_table.zig");
pub const idt = @import("idt.zig");
pub const idt_table = @import("idt_table.zig");
pub const init = @import("init.zig");
pub const insn = @import("insn.zig");
pub const ioport = @import("ioport.zig");
pub const pci = @import("pci.zig");
pub const pcspeaker = @import("pcspeaker.zig");
pub const serial = @import("serial.zig");
pub const shutdown = @import("shutdown.zig");
pub const time = @import("time.zig");
pub const virtio = @import("virtio.zig");

comptime {
    @import("os").arch.util.assertFreestandingArch(.x86);
}

test {
    std.testing.refAllDecls(@This());
}
