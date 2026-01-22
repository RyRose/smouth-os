//! TODO: Get this working!
//! This module extracts DWARF debug info from the current executable.
//! This is useful for symbolication of stack traces in panics.
//!
//! Does not currently work sadly. Fails when parsing the
//! debug abbrev section.
//!
const std = @import("std");
const builtin = @import("builtin");

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

fn dwarfSectionFromRange(start: *u8, end: *u8) std.debug.Dwarf.Section {
    const len: usize = @intFromPtr(end) - @intFromPtr(start);
    const slice: [*]const u8 = @ptrCast(start);
    const section = std.debug.Dwarf.Section{
        .data = slice[0..len],
        .owned = false,
    };
    return section;
}

fn getSelfDwarfInfo() std.debug.Dwarf {
    var sections = std.debug.Dwarf.null_section_array;

    const debug_info = @intFromEnum(std.debug.Dwarf.Section.Id.debug_info);
    sections[debug_info] = dwarfSectionFromRange(&__debug_info_start, &__debug_info_end);

    const debug_abbrev = @intFromEnum(std.debug.Dwarf.Section.Id.debug_abbrev);
    sections[debug_abbrev] = dwarfSectionFromRange(&__debug_abbrev_start, &__debug_abbrev_end);

    const debug_str = @intFromEnum(std.debug.Dwarf.Section.Id.debug_str);
    sections[debug_str] = dwarfSectionFromRange(&__debug_str_start, &__debug_str_end);

    const debug_line = @intFromEnum(std.debug.Dwarf.Section.Id.debug_line);
    sections[debug_line] = dwarfSectionFromRange(&__debug_line_start, &__debug_line_end);

    const debug_ranges = @intFromEnum(std.debug.Dwarf.Section.Id.debug_ranges);
    sections[debug_ranges] = dwarfSectionFromRange(&__debug_ranges_start, &__debug_ranges_end);

    return std.debug.Dwarf{
        .endian = builtin.cpu.arch.endian(),
        .sections = sections,
        // Dwarf format is not Mach-O since it's targeting freestanding.
        // https://en.wikipedia.org/wiki/Mach-O
        .is_macho = false,
    };
}

// // Log all debug extern variables.
// var len = @intFromPtr(&__debug_info_end) - @intFromPtr(&__debug_info_start);
// logF("Debug info   = {p} -> {p} (len={d})", .{ &__debug_info_start, &__debug_info_end, len });
// len = @intFromPtr(&__debug_abbrev_end) - @intFromPtr(&__debug_abbrev_start);
// logF("Debug abbrev = {p} -> {p} (len={d})", .{ &__debug_abbrev_start, &__debug_abbrev_end, len });
// len = @intFromPtr(&__debug_str_end) - @intFromPtr(&__debug_str_start);
// logF("Debug str    = {p} -> {p} (len={d})", .{ &__debug_str_start, &__debug_str_end, len });
// len = @intFromPtr(&__debug_line_end) - @intFromPtr(&__debug_line_start);
// logF("Debug line   = {p} -> {p} (len={d})", .{ &__debug_line_start, &__debug_line_end, len });
// len = @intFromPtr(&__debug_ranges_end) - @intFromPtr(&__debug_ranges_start);
// logF("Debug ranges = {p} -> {p} (len={d})", .{ &__debug_ranges_start, &__debug_ranges_end, len });

// var dwarf = getSelfDwarfInfo();
// std.debug.Dwarf.open(&dwarf, panic_allocator.allocator()) catch |err| {
//     logF("DWARF open error: {}", .{err});
//     logErrorReturnTrace();
//     shutdown();
// };
// defer std.debug.Dwarf.deinit(&dwarf, panic_allocator.allocator());
// const symbol = std.debug.Dwarf.getSymbolName(&dwarf, first_trace_addr.?) orelse "Unknown";
// logF("First trace symbol: {s}", .{symbol});
