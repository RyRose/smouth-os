//! This module extracts DWARF debug info from the current executable.
//! This is useful for symbolication of stack traces in panics.
//!

const builtin = @import("builtin");
const std = @import("std");

const stdk = @import("stdk");

const log = std.log.scoped(.dwarf);

extern var __debug_info_start: u8;
extern var __debug_info_end: u8;
extern var __debug_abbrev_start: u8;
extern var __debug_abbrev_end: u8;
extern var __debug_str_start: u8;
extern var __debug_str_end: u8;
extern var __debug_line_start: u8;
extern var __debug_line_end: u8;
extern var __debug_ranges_start: u8;
extern var __debug_ranges_end: u8;
extern var __eh_frame_start: u8;
extern var __eh_frame_end: u8;

/// Constructs a Dwarf.Section from the given start and end pointers. If the
/// start is null, it creates a section starting from zero to the end pointer.
fn dwarfSection(maybeStart: ?*u8, end: *u8) stdk.Dwarf.Section {
    var slice: [*]const u8 = undefined;
    var len: usize = undefined;
    if (maybeStart) |start| {
        slice = @ptrCast(start);
        len = @intFromPtr(end) - @intFromPtr(start);
    } else {
        // HACK:
        // Trick to get a null pointer without the use of
        // allowzero. This minimizes the number of modifications
        // needed to stdk.Dwarf. This depends on undefined behavior and
        // may be broken at any time.
        @setRuntimeSafety(false);
        var zero: u8 = 0;
        _ = &zero;
        slice = @ptrFromInt(zero);
        @setRuntimeSafety(true);
        len = @intFromPtr(end);
    }

    return .{
        .data = slice[0..len],
        .owned = false,
    };
}

pub fn open(allocator: std.mem.Allocator) !stdk.Dwarf {
    var dwarf = stdk.Dwarf{
        .endian = builtin.cpu.arch.endian(),
        // Dwarf format is not Mach-O since it's targeting freestanding.
        // https://en.wikipedia.org/wiki/Mach-O
        .is_macho = false,
    };

    const debug_info = @intFromEnum(std.debug.Dwarf.Section.Id.debug_info);
    dwarf.sections[debug_info] = dwarfSection(
        &__debug_info_start,
        &__debug_info_end,
    );
    log.debug("debug_info section: {p} - {p} (len={d})", .{
        &__debug_info_start,
        &__debug_info_end,
        @intFromPtr(&__debug_info_end) - @intFromPtr(&__debug_info_start),
    });

    const debug_abbrev = @intFromEnum(std.debug.Dwarf.Section.Id.debug_abbrev);
    dwarf.sections[debug_abbrev] = dwarfSection(null, &__debug_abbrev_end);
    log.debug("debug_abbrev section: {p} - {p} (len={d})", .{
        &__debug_abbrev_start,
        &__debug_abbrev_end,
        @intFromPtr(&__debug_abbrev_end) - @intFromPtr(&__debug_abbrev_start),
    });

    const debug_str = @intFromEnum(std.debug.Dwarf.Section.Id.debug_str);
    dwarf.sections[debug_str] = dwarfSection(null, &__debug_str_end);
    log.debug("debug_str section: {p} - {p} (len={d})", .{
        &__debug_str_start,
        &__debug_str_end,
        @intFromPtr(&__debug_str_end) - @intFromPtr(&__debug_str_start),
    });

    const debug_line = @intFromEnum(std.debug.Dwarf.Section.Id.debug_line);
    dwarf.sections[debug_line] = dwarfSection(null, &__debug_line_end);
    log.debug("debug_line section: {p} - {p} (len={d})", .{
        &__debug_line_start,
        &__debug_line_end,
        @intFromPtr(&__debug_line_end) - @intFromPtr(&__debug_line_start),
    });

    const debug_ranges = @intFromEnum(std.debug.Dwarf.Section.Id.debug_ranges);
    dwarf.sections[debug_ranges] = dwarfSection(null, &__debug_ranges_end);
    log.debug("debug_ranges section: {p} - {p} (len={d})", .{
        &__debug_ranges_start,
        &__debug_ranges_end,
        @intFromPtr(&__debug_ranges_end) - @intFromPtr(&__debug_ranges_start),
    });

    const eh_frame = @intFromEnum(std.debug.Dwarf.Section.Id.eh_frame);
    dwarf.sections[eh_frame] = dwarfSection(
        &__eh_frame_start,
        &__eh_frame_end,
    );
    log.debug("eh_frame section: {p} - {p} (len={d})", .{
        &__eh_frame_start,
        &__eh_frame_end,
        @intFromPtr(&__eh_frame_end) - @intFromPtr(&__eh_frame_start),
    });
    log.debug("all sections: {p} - {p} (len={d})", .{
        &__debug_info_start,
        &__eh_frame_end,
        @intFromPtr(&__eh_frame_end) - @intFromPtr(&__debug_info_start),
    });

    try dwarf.open(allocator);
    return dwarf;
}
