const builtin = @import("builtin");
const std = @import("std");

pub fn assertFreestandingArch(comptime arch: std.Target.Cpu.Arch) void {
    if (builtin.target.cpu.arch != arch) {
        @compileError(std.fmt.comptimePrint(
            "This code is only supported on {} architecture but found {}",
            .{ arch, builtin.target.cpu.arch },
        ));
    }
    if (builtin.os.tag != .freestanding) {
        @compileError(std.fmt.comptimePrint(
            "This code is only supported on freestanding targets but found {}",
            .{builtin.os.tag},
        ));
    }
}
