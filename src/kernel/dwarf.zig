//! This module provides DWARF debug info for the kernel by implementing the
//! root.debug.SelfInfo interface, allowing std.debug stack trace machinery to
//! resolve kernel addresses to source locations.

const builtin = @import("builtin");
const std = @import("std");

const native_endian = builtin.cpu.arch.endian();

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

// 3 MiB fixed buffer for DWARF allocations (function/compile-unit tables, etc.)
var debug_buffer: [4000 * 1024]u8 = undefined;
var debug_fba: std.heap.FixedBufferAllocator = .init(&debug_buffer);

/// Returns the allocator backed by the kernel's fixed debug buffer.
/// Also used as root.debug.getDebugInfoAllocator.
pub fn debugAllocator() std.mem.Allocator {
    return debug_fba.allocator();
}

fn sectionSlice(start: *u8, end: *u8) []const u8 {
    const s: usize = @intFromPtr(start);
    const e: usize = @intFromPtr(end);
    return @as([*]const u8, @ptrFromInt(s))[0 .. e - s];
}

/// Implements the root.debug.SelfInfo interface for the freestanding kernel.
/// Wraps std.debug.Dwarf, populating sections lazily from the kernel's ELF
/// linker symbols on first use.
pub const SelfInfo = struct {
    dwarf: std.debug.Dwarf = .{},
    opened: bool = false,

    pub const init: SelfInfo = .{};
    pub const can_unwind = false;

    pub fn deinit(si: *SelfInfo, io: std.Io) void {
        _ = io;
        si.dwarf.deinit(debugAllocator());
    }

    pub fn getSymbols(
        si: *SelfInfo,
        io: std.Io,
        symbol_allocator: std.mem.Allocator,
        text_arena: std.mem.Allocator,
        address: usize,
        resolve_inline_callers: bool,
        symbols: *std.ArrayList(std.debug.Symbol),
    ) std.debug.SelfInfoError!void {
        _ = io;
        si.ensureOpened() catch |err| {
            log.err("ensureOpened failed: {}", .{err});
            return error.MissingDebugInfo;
        };
        si.dwarf.getSymbols(symbol_allocator, text_arena, native_endian, address, resolve_inline_callers, symbols) catch |err| {
            log.err("dwarf.getSymbols(0x{x}) failed: {}", .{ address, err });
            return err;
        };
    }

    pub fn getModuleName(si: *SelfInfo, io: std.Io, address: usize) std.debug.SelfInfoError![]const u8 {
        _ = .{ si, io, address };
        return "kernel";
    }

    pub fn getModuleSlide(si: *SelfInfo, io: std.Io, address: usize) std.debug.SelfInfoError!usize {
        _ = .{ si, io, address };
        return 0;
    }

    fn ensureOpened(si: *SelfInfo) !void {
        if (si.opened) return;
        // Set opened = true early to prevent recursive panics.
        si.opened = true;

        const gpa = debugAllocator();

        // The linker places .debug_* inside .rodata (an allocatable LOAD segment)
        // so cross-section DWARF references are resolved to absolute VMAs rather
        // than section-relative offsets.  std.debug.Dwarf expects section-relative
        // offsets.
        //
        // Fix: copy debug_info and walk the DWARF structure to patch only the
        // exact cross-section reference fields (debug_abbrev_offset in CU headers,
        // DW_FORM_strp, DW_FORM_sec_offset, DW_FORM_ref_addr in DIE attributes).
        // All other sections are provided as-is with their actual byte pointers.
        const info_raw = sectionSlice(&__debug_info_start, &__debug_info_end);
        const abbrev_raw = sectionSlice(&__debug_abbrev_start, &__debug_abbrev_end);
        const str_raw = sectionSlice(&__debug_str_start, &__debug_str_end);
        const line_raw = sectionSlice(&__debug_line_start, &__debug_line_end);
        const ranges_raw = sectionSlice(&__debug_ranges_start, &__debug_ranges_end);

        const abbrev_base: u32 = @intCast(@intFromPtr(&__debug_abbrev_start));
        const str_base: u32 = @intCast(@intFromPtr(&__debug_str_start));
        const line_base: u32 = @intCast(@intFromPtr(&__debug_line_start));
        const ranges_base: u32 = @intCast(@intFromPtr(&__debug_ranges_start));
        const info_base: u32 = @intCast(@intFromPtr(&__debug_info_start));

        log.debug("DWARF sections: info={d}B abbrev={d}B str={d}B line={d}B ranges={d}B", .{
            info_raw.len, abbrev_raw.len, str_raw.len, line_raw.len, ranges_raw.len,
        });

        const info_copy = try gpa.dupe(u8, info_raw);
        patchDwarfInfo(info_copy, abbrev_raw, abbrev_base, str_base, line_base, ranges_base, info_base);

        const Id = std.debug.Dwarf.Section.Id;
        si.dwarf.sections[@intFromEnum(Id.debug_info)] = .{ .data = info_copy, .owned = false };
        si.dwarf.sections[@intFromEnum(Id.debug_abbrev)] = .{ .data = abbrev_raw, .owned = false };
        si.dwarf.sections[@intFromEnum(Id.debug_str)] = .{ .data = str_raw, .owned = false };
        si.dwarf.sections[@intFromEnum(Id.debug_line)] = .{ .data = line_raw, .owned = false };
        si.dwarf.sections[@intFromEnum(Id.debug_ranges)] = .{ .data = ranges_raw, .owned = false };

        si.dwarf.open(gpa, native_endian) catch |err| {
            log.err("dwarf.open failed: {}", .{err});
            return err;
        };
        log.debug("DWARF opened successfully", .{});
    }
};

// ---------------------------------------------------------------------------
// DWARF v4 info patcher
// ---------------------------------------------------------------------------
// The linker emits absolute VMAs for cross-section refs inside .debug_info
// because .debug_info is in an allocatable section.  We fix this by walking
// CU headers and the DIE tree and subtracting each section's base VMA from
// the appropriate reference fields.

/// Patch cross-section references in a copy of .debug_info so that they
/// become section-relative (0-based) as std.debug.Dwarf expects.
fn patchDwarfInfo(
    info: []u8,
    abbrev: []const u8,
    abbrev_base: u32,
    str_base: u32,
    line_base: u32,
    ranges_base: u32,
    info_base: u32,
) void {
    var cu_off: usize = 0;
    while (cu_off < info.len) {
        const cu = parseCuHeader(info[cu_off..]) orelse break;
        if (cu.unit_length == 0) break;

        // Patch debug_abbrev_offset in the CU header.
        const abbrev_off_field = cu_off + cu.abbrev_offset_field_pos;
        const raw_abbrev_off = std.mem.readInt(u32, info[abbrev_off_field..][0..4], .little);
        const abbrev_section_off = if (raw_abbrev_off >= abbrev_base)
            raw_abbrev_off - abbrev_base
        else
            raw_abbrev_off;
        std.mem.writeInt(u32, info[abbrev_off_field..][0..4], abbrev_section_off, .little);

        // Walk the DIE tree and patch attribute values. Pass the abbrev sub-slice
        // so patchDies can scan it inline without allocating a table.
        const die_start = cu_off + cu.header_size;
        const cu_end = cu_off + 4 + @as(usize, cu.unit_length);
        if (abbrev_section_off < abbrev.len) {
            patchDies(info, die_start, cu_end, abbrev[abbrev_section_off..], cu.address_size, str_base, line_base, ranges_base, info_base);
        }

        cu_off = cu_end;
    }
}

const CuHeader = struct {
    unit_length: u32,
    /// Offset within the CU slice where the 4-byte debug_abbrev_offset lives.
    abbrev_offset_field_pos: usize,
    address_size: u8,
    /// Total byte length of the CU header (first DIE starts here).
    header_size: usize,
};

fn parseCuHeader(data: []const u8) ?CuHeader {
    if (data.len < 11) return null;
    const unit_length = std.mem.readInt(u32, data[0..4], .little);
    // DWARF v4 CU header layout (32-bit): unit_length(4) version(2) debug_abbrev_offset(4) address_size(1)
    const version = std.mem.readInt(u16, data[4..6], .little);
    if (version < 2 or version > 5) return null;
    if (version <= 4) {
        if (data.len < 11) return null;
        return .{
            .unit_length = unit_length,
            .abbrev_offset_field_pos = 6,
            .address_size = data[10],
            .header_size = 11,
        };
    } else {
        // DWARF v5: unit_length(4) version(2) unit_type(1) address_size(1) debug_abbrev_offset(4)
        if (data.len < 12) return null;
        return .{
            .unit_length = unit_length,
            .abbrev_offset_field_pos = 8,
            .address_size = data[7],
            .header_size = 12,
        };
    }
}

const Attr = struct {
    id: u64,
    form: u64,
    implicit_const: i64 = 0,
};

/// Walk all DIEs in `info[start..end]` and patch cross-section reference values.
/// `abbrev` is the abbrev sub-section for this CU; it is scanned inline per DIE
/// to avoid large on-stack tables.
fn patchDies(
    info: []u8,
    start: usize,
    end: usize,
    abbrev: []const u8,
    address_size: u8,
    str_base: u32,
    line_base: u32,
    ranges_base: u32,
    info_base: u32,
) void {
    var pos = start;
    while (pos < end) {
        const code, const code_len = readUleb128(info[pos..]) orelse break;
        pos += code_len;
        if (code == 0) continue; // null DIE (end-of-children marker)

        // Scan the abbrev section to find this code's attribute list.
        var apos: usize = 0;
        var found = false;
        while (apos < abbrev.len) {
            const acode, const alen = readUleb128(abbrev[apos..]) orelse break;
            apos += alen;
            if (acode == 0) break;
            const _tag, const tlen = readUleb128(abbrev[apos..]) orelse break;
            _ = _tag;
            apos += tlen;
            if (apos >= abbrev.len) break;
            apos += 1; // has_children byte

            if (acode == code) {
                found = true;
                while (apos < abbrev.len) {
                    const attr_id, const id_len = readUleb128(abbrev[apos..]) orelse break;
                    apos += id_len;
                    const form_id, const form_len = readUleb128(abbrev[apos..]) orelse break;
                    apos += form_len;
                    if (attr_id == 0 and form_id == 0) break;
                    var ic: i64 = 0;
                    if (form_id == std.dwarf.FORM.implicit_const) {
                        const val, const vlen = readSleb128(abbrev[apos..]) orelse break;
                        ic = val;
                        apos += vlen;
                    }
                    const attr: Attr = .{ .id = attr_id, .form = form_id, .implicit_const = ic };
                    pos = patchAttr(info, pos, end, attr, address_size, str_base, line_base, ranges_base, info_base);
                }
                break;
            } else {
                // Skip attrs for non-matching entry.
                while (apos < abbrev.len) {
                    const attr_id, const id_len = readUleb128(abbrev[apos..]) orelse break;
                    apos += id_len;
                    const form_id, const form_len = readUleb128(abbrev[apos..]) orelse break;
                    apos += form_len;
                    if (attr_id == 0 and form_id == 0) break;
                    if (form_id == std.dwarf.FORM.implicit_const) {
                        const _v, const vlen = readSleb128(abbrev[apos..]) orelse break;
                        _ = _v;
                        apos += vlen;
                    }
                }
            }
        }
        if (!found) break; // Can't parse further without abbrev info.
    }
}

/// Patch a single attribute value at `info[pos..]` and return the new pos.
fn patchAttr(
    info: []u8,
    pos: usize,
    end: usize,
    attr: Attr,
    address_size: u8,
    str_base: u32,
    line_base: u32,
    ranges_base: u32,
    info_base: u32,
) usize {
    const F = std.dwarf.FORM;
    const AT = std.dwarf.AT;
    var p = pos;
    if (p >= end) return p;
    switch (attr.form) {
        F.addr => p += address_size,
        F.data1, F.ref1, F.flag => p += 1,
        F.data2, F.ref2 => p += 2,
        F.data4, F.ref4 => p += 4,
        F.data8, F.ref8, F.ref_sig8 => p += 8,
        F.sdata => {
            const _v, const l = readSleb128(info[p..]) orelse return p;
            _ = _v;
            p += l;
        },
        F.udata, F.ref_udata => {
            const _v, const l = readUleb128(info[p..]) orelse return p;
            _ = _v;
            p += l;
        },
        F.flag_present => {},
        F.implicit_const => {},
        F.string => {
            while (p < info.len and info[p] != 0) : (p += 1) {}
            p += 1;
        },
        F.block1 => {
            if (p >= info.len) return p;
            const n: usize = info[p];
            p += 1 + n;
        },
        F.block2 => {
            if (p + 2 > info.len) return p;
            const n: usize = std.mem.readInt(u16, info[p..][0..2], .little);
            p += 2 + n;
        },
        F.block4 => {
            if (p + 4 > info.len) return p;
            const n: usize = std.mem.readInt(u32, info[p..][0..4], .little);
            p += 4 + n;
        },
        F.block => {
            const n, const l = readUleb128(info[p..]) orelse return p;
            p += l + @as(usize, @truncate(n));
        },
        F.exprloc => {
            const n, const l = readUleb128(info[p..]) orelse return p;
            p += l + @as(usize, @truncate(n));
        },
        F.strp => {
            if (p + 4 <= info.len) {
                const v = std.mem.readInt(u32, info[p..][0..4], .little);
                if (v >= str_base) std.mem.writeInt(u32, info[p..][0..4], v - str_base, .little);
            }
            p += 4;
        },
        F.sec_offset => {
            if (p + 4 <= info.len) {
                const v = std.mem.readInt(u32, info[p..][0..4], .little);
                const base: u32 = switch (attr.id) {
                    AT.stmt_list => line_base,
                    AT.ranges => ranges_base,
                    else => 0,
                };
                if (base > 0 and v >= base) {
                    std.mem.writeInt(u32, info[p..][0..4], v - base, .little);
                }
            }
            p += 4;
        },
        F.ref_addr => {
            if (p + 4 <= info.len and address_size == 4) {
                const v = std.mem.readInt(u32, info[p..][0..4], .little);
                if (v >= info_base) std.mem.writeInt(u32, info[p..][0..4], v - info_base, .little);
            }
            p += address_size;
        },
        F.indirect => {
            const form_id, const l = readUleb128(info[p..]) orelse return p;
            p += l;
            const indirect_attr: Attr = .{ .id = attr.id, .form = form_id };
            p = patchAttr(info, p, end, indirect_attr, address_size, str_base, line_base, ranges_base, info_base);
        },
        else => {},
    }
    return p;
}

fn readUleb128(data: []const u8) ?struct { u64, usize } {
    var result: u64 = 0;
    var shift: u8 = 0;
    for (data[0..@min(data.len, 10)], 0..) |byte, i| {
        result |= @as(u64, byte & 0x7f) << @intCast(shift);
        if (byte & 0x80 == 0) return .{ result, i + 1 };
        shift += 7;
    }
    return null;
}

fn readSleb128(data: []const u8) ?struct { i64, usize } {
    var result: i64 = 0;
    var shift: u8 = 0;
    for (data[0..@min(data.len, 10)], 0..) |byte, i| {
        result |= @as(i64, byte & 0x7f) << @intCast(shift);
        shift += 7;
        if (byte & 0x80 == 0) {
            if (shift < 64 and (byte & 0x40) != 0) result |= ~@as(i64, 0) << @intCast(shift);
            return .{ result, i + 1 };
        }
    }
    return null;
}
