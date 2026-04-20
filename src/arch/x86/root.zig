//! Root module for x86 architecture.

const std = @import("std");
const builtin = @import("builtin");

pub const boot = @import("boot.zig");
pub const gdt = @import("gdt.zig");
pub const idt = @import("idt.zig");
pub const insn = @import("insn.zig");
pub const ioport = @import("ioport.zig");

// Ensure this code is only compiled for x86 freestanding targets.
comptime {
    if (builtin.target.cpu.arch != .x86) {
        @compileError(std.fmt.comptimePrint(
            "This code is only supported on x86 architecture but found {}",
            .{builtin.target.cpu.arch},
        ));
    }
    if (builtin.os.tag != .freestanding) {
        @compileError(std.fmt.comptimePrint(
            "This code is only supported on freestanding targets but found {}",
            .{builtin.os.tag},
        ));
    }
}
