//! This module extracts DWARF debug info from the current executable.
//! This is useful for symbolication of stack traces in panics.
//!
const std = @import("std");
const builtin = @import("builtin");

pub const Dwarf = @import("stddwarf/Dwarf.zig");

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

fn dwarfSectionFromRange(start: *u8, end: *u8) Dwarf.Section {
    const len: usize = @intFromPtr(end) - @intFromPtr(start);
    const slice: [*]const u8 = @ptrCast(start);
    const section = Dwarf.Section{
        .data = slice[0..len],
        .owned = false,
    };
    return section;
}

fn dwarfSectionFromZero(end: *u8) Dwarf.Section {
    // HACK:
    // Trick to get a null pointer without the use of
    // allowzero. This minimizes the number of modifications
    // needed to stddwarf. This depends on undefined behavior and
    // may be broken at any time.
    @setRuntimeSafety(false);
    var zero: u8 = 0;
    _ = &zero;
    const start: [*]const u8 = @ptrFromInt(zero);
    @setRuntimeSafety(true);

    const len: usize = @intFromPtr(end);
    const section = Dwarf.Section{
        .data = start[0..len],
        .owned = false,
    };
    log.debug("dwarfSectionFromZero: start={*}, len={d}", .{
        section.data.ptr,
        section.data.len,
    });
    return section;
}

pub fn open(allocator: std.mem.Allocator) !Dwarf {
    var dwarf = Dwarf{
        .endian = builtin.cpu.arch.endian(),
        // Dwarf format is not Mach-O since it's targeting freestanding.
        // https://en.wikipedia.org/wiki/Mach-O
        .is_macho = false,
    };

    const debug_info = @intFromEnum(Dwarf.Section.Id.debug_info);
    dwarf.sections[debug_info] = dwarfSectionFromRange(&__debug_info_start, &__debug_info_end);
    log.debug("debug_info section: {p} - {p} (len={d})", .{
        &__debug_info_start,
        &__debug_info_end,
        dwarf.sections[debug_info].?.data.len,
    });

    const debug_abbrev = @intFromEnum(Dwarf.Section.Id.debug_abbrev);
    dwarf.sections[debug_abbrev] = dwarfSectionFromZero(&__debug_abbrev_end);
    log.debug("debug_abbrev section: {p} - {p} (null={})", .{
        &__debug_abbrev_start,
        &__debug_abbrev_end,
        dwarf.sections[debug_abbrev] == null,
    });

    const debug_str = @intFromEnum(Dwarf.Section.Id.debug_str);
    dwarf.sections[debug_str] = dwarfSectionFromZero(&__debug_str_end);
    log.debug("debug_str section: {p} - {p} (len={d})", .{
        &__debug_str_start,
        &__debug_str_end,
        dwarf.sections[debug_str].?.data.len,
    });

    const debug_line = @intFromEnum(std.debug.Dwarf.Section.Id.debug_line);
    dwarf.sections[debug_line] = dwarfSectionFromZero(&__debug_line_end);
    log.debug("debug_line section: {p} - {p} (len={d})", .{
        &__debug_line_start,
        &__debug_line_end,
        dwarf.sections[debug_line].?.data.len,
    });

    const debug_ranges = @intFromEnum(std.debug.Dwarf.Section.Id.debug_ranges);
    dwarf.sections[debug_ranges] = dwarfSectionFromZero(&__debug_ranges_end);
    log.debug("debug_ranges section: {p} - {p} (len={d})", .{
        &__debug_ranges_start,
        &__debug_ranges_end,
        dwarf.sections[debug_ranges].?.data.len,
    });

    const eh_frame = @intFromEnum(Dwarf.Section.Id.eh_frame);
    dwarf.sections[eh_frame] = dwarfSectionFromRange(&__eh_frame_start, &__eh_frame_end);
    log.debug("eh_frame section: {p} - {p} (len={d})", .{
        &__eh_frame_start,
        &__eh_frame_end,
        dwarf.sections[eh_frame].?.data.len,
    });

    try dwarf.open(allocator);
    return dwarf;
}
