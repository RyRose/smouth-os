//! Debug utilities for the kernel, including support for embedded source files
//! in debug info. This module provides a custom implementation of
//! `std.debug.SelfInfo` that retrieves source lines from embedded files
//! instead of the filesystem, which is necessary in a freestanding environment
//! like a kernel.
//!

const std = @import("std");

const embed = @import("embed");

const dwarf = @import("dwarf.zig");
const serial = @import("serial.zig");

pub const self = struct {
    pub const SelfInfo = dwarf.SelfInfo;
    pub fn getDebugInfoAllocator() std.mem.Allocator {
        return dwarf.debugAllocator();
    }

    /// Override std.debug's printLineFromFile to use embedded source files
    /// instead of Dir.cwd() (which doesn't exist on freestanding).
    pub fn printLineFromFile(
        io: std.Io,
        writer: *std.Io.Writer,
        source_location: std.debug.SourceLocation,
    ) !void {
        _ = io;
        const data = embed.srcFiles.get(source_location.file_name) orelse
            return error.MissingDebugInfo;

        var line: usize = 1;
        var start: usize = 0;
        while (line < source_location.line) {
            if (std.mem.indexOfScalar(u8, data[start..], '\n')) |pos| {
                start += pos + 1;
                line += 1;
            } else return error.MissingDebugInfo;
        }
        const rest = data[start..];
        if (std.mem.indexOfScalar(u8, rest, '\n')) |pos| {
            try writer.writeAll(rest[0 .. pos + 1]);
        } else {
            try writer.writeAll(rest);
            try writer.writeByte('\n');
        }
    }
};
