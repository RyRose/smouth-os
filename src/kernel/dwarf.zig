//! This module provides DWARF (Debugging With Attributed Record Formats) debug
//! info for the kernel by implementing the root.debug.SelfInfo interface,
//! allowing std.debug stack trace machinery to resolve kernel addresses to
//! source locations.

const std = @import("std");
const builtin = @import("builtin");

const native_endian = builtin.cpu.arch.endian();

const log = std.log.scoped(.dwarf);

// Boundary symbols for each DWARF section, emitted by the linker script as
// pairs of labels at the start and end of each .debug_* output section.
// Taking the address of a symbol gives the section's load address; subtracting
// the two gives its byte length.
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

/// Returns a byte slice covering the DWARF section delimited by the linker
/// symbols `start` and `end`.  The symbols are treated as pointers to the
/// first and one-past-last bytes of the section respectively.
fn sectionSlice(start: *u8, end: *u8) []const u8 {
    const s: usize = @intFromPtr(start);
    const e: usize = @intFromPtr(end);
    return @as([*]const u8, @ptrFromInt(s))[0 .. e - s];
}

/// Implements the root.debug.SelfInfo interface for the freestanding kernel.
/// Wraps std.debug.Dwarf, populating sections lazily from the kernel's ELF
/// (Executable and Linkable Format) linker symbols on first use.
pub const SelfInfo = struct {
    /// The underlying DWARF parser populated lazily on first use.
    dwarf: std.debug.Dwarf = .{},

    /// Whether `dwarf` has been populated.  Set to `true` before parsing
    /// begins so that a panic triggered during initialization does not
    /// recurse back into `ensureOpened`.
    opened: bool = false,

    /// Zero value; satisfies the root.debug.SelfInfo interface requirement.
    pub const init: SelfInfo = .{};

    /// Unwinding is not supported for the freestanding kernel.
    pub const can_unwind = false;

    /// Release all memory owned by the DWARF parser.
    pub fn deinit(
        si: *SelfInfo,
        /// Unused; present to satisfy the root.debug.SelfInfo interface.
        io: std.Io,
    ) void {
        _ = io;
        si.dwarf.deinit(debugAllocator());
    }

    /// Resolve `address` to one or more source-level symbols by querying the
    /// kernel's DWARF debug info.  Initializes the DWARF parser on first call.
    pub fn getSymbols(
        si: *SelfInfo,
        /// Unused; present to satisfy the root.debug.SelfInfo interface.
        io: std.Io,
        /// Allocator used to allocate `std.debug.Symbol` entries appended to `symbols`.
        symbol_allocator: std.mem.Allocator,
        /// Allocator used to allocate symbol name strings; typically an arena
        /// whose lifetime exceeds the call.
        text_arena: std.mem.Allocator,
        address: usize,
        /// When true, walk the inline call chain and append one symbol per
        /// inlined frame in addition to the concrete function frame.
        resolve_inline_callers: bool,
        /// Output list; resolved symbols are appended in innermost-first order.
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

    /// Always returns "kernel"; the kernel is a single monolithic module.
    pub fn getModuleName(
        si: *SelfInfo,
        /// Unused; present to satisfy the root.debug.SelfInfo interface.
        io: std.Io,
        /// Unused; all addresses belong to the single "kernel" module.
        address: usize,
    ) std.debug.SelfInfoError![]const u8 {
        _ = .{ si, io, address };
        return "kernel";
    }

    /// Always returns 0; the kernel is loaded at a fixed address (no KASLR —
    /// Kernel Address Space Layout Randomization).
    pub fn getModuleSlide(
        si: *SelfInfo,
        /// Unused; present to satisfy the root.debug.SelfInfo interface.
        io: std.Io,
        /// Unused; the slide is zero for all addresses.
        address: usize,
    ) std.debug.SelfInfoError!usize {
        _ = .{ si, io, address };
        return 0;
    }

    /// Populate `dwarf` from the kernel's in-memory DWARF sections the first
    /// time it is called.  Subsequent calls return immediately.
    fn ensureOpened(si: *SelfInfo) !void {
        if (si.opened) return;
        // Set opened = true early to prevent recursive panics.
        si.opened = true;

        const gpa = debugAllocator();

        // The linker places .debug_* inside .rodata (an allocatable ELF LOAD
        // segment — a contiguous range of virtual memory mapped from the file)
        // so cross-section DWARF references are resolved to absolute virtual
        // memory addresses (VMAs) rather than section-relative offsets.
        // std.debug.Dwarf expects section-relative offsets.
        //
        // Because all debug sections share one LOAD segment the linker assigns
        // them consecutive addresses.  For example:
        //
        // .rodata           .debug_abbrev   .debug_str     .debug_info
        // |-----------------|----------------|----------------|----------------|
        // 0x1000            0x2000         0x3000         0x4000
        //
        // Fix: copy .debug_info and walk its DWARF structure, patching only the
        // fields that hold cross-section references (subtracting each section's
        // base VMA to convert to a section-relative offset):
        //   - debug_abbrev_offset in each CU (compile unit) header
        //   - DW_FORM_strp: 4-byte pointer into .debug_str
        //   - DW_FORM_sec_offset: 4-byte offset into .debug_line or .debug_ranges
        //   - DW_FORM_ref_addr: 4-byte cross-CU reference into .debug_info
        // All other sections are handed to std.debug.Dwarf as-is.
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

        errdefer log.debug("DWARF sections: info={d}B abbrev={d}B str={d}B line={d}B ranges={d}B", .{
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
    }
};

// ---------------------------------------------------------------------------
// DWARF .debug_info patcher
// ---------------------------------------------------------------------------
// When .debug_* sections share an ELF LOAD segment with .rodata the linker
// resolves cross-section references to absolute VMAs (virtual memory
// addresses).  We fix this by walking CU headers and the DIE tree,
// subtracting each section's base VMA from the appropriate reference fields.

/// Patch cross-section references in a copy of .debug_info so that they
/// become section-relative (0-based) as std.debug.Dwarf expects.
fn patchDwarfInfo(
    /// Mutable copy of .debug_info; cross-section references are patched in-place.
    info: []u8,
    /// Read-only .debug_abbrev section; used to look up attribute forms when
    /// walking the DIE tree.
    abbrev: []const u8,
    /// Base VMA of .debug_abbrev; subtracted from the raw debug_abbrev_offset in
    /// each CU header to convert it to a section-relative offset.
    abbrev_base: u32,
    /// Base VMA of .debug_str; passed to patchDies for DW_FORM_strp patching.
    str_base: u32,
    /// Base VMA of .debug_line; passed to patchDies for DW_AT_stmt_list patching.
    line_base: u32,
    /// Base VMA of .debug_ranges; passed to patchDies for DW_AT_ranges patching.
    ranges_base: u32,
    /// Base VMA of .debug_info; passed to patchDies for DW_FORM_ref_addr patching.
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

/// DWARF compile unit (CU) header information needed to parse and patch DIEs.
///
/// A CU header is followed by a tree of DIEs (debug information entries) that describe
/// a compilation unit (e.g. a source file). Each DIE has a code that references an
/// abbrev entry, which describes the DIE's tag and attribute forms. The attribute forms
/// determine how to parse the attribute values and whether they contain cross-section
/// references that need patching.
///
const CuHeader = struct {
    /// Number of bytes in the CU after the length field itself (i.e. the total
    /// CU size is unit_length + 4).
    unit_length: u32,
    /// Offset within the CU slice where the 4-byte debug_abbrev_offset lives.
    abbrev_offset_field_pos: usize,
    /// Size of an address or pointer in this CU, in bytes (typically 4 or 8).
    address_size: u8,
    /// Total byte length of the CU header (first DIE starts here).
    header_size: usize,
};

/// Parse a CU header from the start of `data`, returning null if the data is
/// too short or the version is unsupported.  DWARF v4 and v5 have different CU
/// header layouts, but both start with unit_length(4) version(2) so we can
/// parse those fields to determine the layout.
///
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

/// A single DWARF attribute descriptor read from the abbrev section.
/// Carries enough information to advance past—and optionally patch—the
/// corresponding value bytes in the .debug_info stream.
const Attr = struct {
    /// DW_AT_* attribute code identifying the attribute's semantic meaning.
    id: u64,
    /// DW_FORM_* form code describing how the attribute value is encoded.
    form: u64,
    /// For DW_FORM_implicit_const, the constant value stored in the abbrev
    /// section rather than the .debug_info stream.  Zero for all other forms.
    implicit_const: i64 = 0,
};

/// Walk all DIEs in `info[start..end]` and patch cross-section reference values.
/// `abbrev` is the DWARF abbreviation table sub-section for this CU.  The
/// abbreviation table maps each abbrev code (a compact integer stored in each
/// DIE) to a tag and an ordered list of (attribute id, form) pairs that
/// describe how the DIE's attribute values are encoded in .debug_info.  It is
/// scanned inline per DIE to avoid large on-stack tables.
fn patchDies(
    /// Mutable .debug_info buffer; attribute values are patched in-place.
    info: []u8,
    /// Byte offset in `info` where the first DIE of this CU begins.
    start: usize,
    /// Exclusive upper bound of this CU's DIE range in `info`.
    end: usize,
    /// Abbreviation table sub-slice for this CU (offset into .debug_abbrev).
    abbrev: []const u8,
    /// Pointer size in bytes for this CU, from the CU header.
    address_size: u8,
    /// Base VMA of .debug_str; subtracted from DW_FORM_strp values.
    str_base: u32,
    /// Base VMA of .debug_line; subtracted from DW_AT_stmt_list sec_offset values.
    line_base: u32,
    /// Base VMA of .debug_ranges; subtracted from DW_AT_ranges sec_offset values.
    ranges_base: u32,
    /// Base VMA of .debug_info; subtracted from DW_FORM_ref_addr values.
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

            // If this abbrev entry matches the DIE's code, patch the DIE's attributes as we
            // walk them. Otherwise just skip the attributes without parsing since we don't need
            // to patch them.
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

/// Advance past the attribute value at `info[pos..]`, patching it in-place if
/// it holds a cross-section reference, and return the new position.
///
/// The following forms are patched by subtracting the section's base VMA:
///   - DW_FORM_strp: 4-byte pointer into .debug_str; subtract `str_base`.
///   - DW_FORM_sec_offset: 4-byte section offset; subtract `line_base` for
///     DW_AT_stmt_list (line-number table) and `ranges_base` for DW_AT_ranges.
///   - DW_FORM_ref_addr: 4-byte cross-CU reference into .debug_info; subtract
///     `info_base`.
///
/// All other forms are advanced past without modification.
fn patchAttr(
    /// The entire .debug_info slice, needed to patch DW_FORM_ref_addr which
    /// can point anywhere in the CU.
    info: []u8,
    /// Current position in the CU where the attribute value starts.
    pos: usize,
    /// Exclusive upper bound of the current CU in `info`; the cursor must not
    /// advance beyond this point.
    end: usize,
    /// Attribute descriptor from the abbreviation table; its `form` field
    /// determines how many bytes to advance and whether to patch.
    attr: Attr,
    /// Pointer size in bytes for this CU; used to advance past DW_FORM_addr values.
    address_size: u8,
    /// Base VMA of .debug_str; subtracted from DW_FORM_strp values.
    str_base: u32,
    /// Base VMA of .debug_line; subtracted from DW_AT_stmt_list DW_FORM_sec_offset values.
    line_base: u32,
    /// Base VMA of .debug_ranges; subtracted from DW_AT_ranges DW_FORM_sec_offset values.
    ranges_base: u32,
    /// Base VMA of .debug_info; subtracted from DW_FORM_ref_addr values.
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

/// Reads an unsigned LEB128 value from the start of `data`, returning the
/// value and the number of bytes read. An LEB128 value is a variable-length
/// encoding of an integer where each byte contributes 7 bits of data and the
/// high bit indicates if more bytes follow.
///
/// https://en.wikipedia.org/wiki/LEB128
///
fn readUleb128(data: []const u8) ?struct { u64, usize } {
    var result: u64 = 0;
    var shift: u8 = 0;
    // A 64-bit value can be at most 10 bytes in LEB128 (9 bytes with 7 bits
    // each = 63 bits, plus a 10th byte for the final bit).
    for (data[0..@min(data.len, 10)], 0..) |byte, i| {
        // If the shift is already 63, then we are processing the 10th byte. It must be
        // either 0x00 (final byte with no value bits) or 0x01 (final byte with the 64th bit set).
        result |= @as(u64, byte & 0x7f) << @intCast(shift);
        // If the high bit is not set, this is the last byte of the value.
        if (byte & 0x80 == 0) return .{ result, i + 1 };
        // Otherwise, continue to the next byte.
        shift += 7;
    }
    return null;
}

/// Reads a signed LEB128 value from the start of `data`, returning the value
/// and the number of bytes read. A signed LEB128 is encoded in the same way as
/// unsigned, but the most significant bit of the last byte indicates the sign
/// of the value and is used for sign extension.
fn readSleb128(data: []const u8) ?struct { i64, usize } {
    var result: i64 = 0;
    var shift: u8 = 0;
    // A 64-bit value can be at most 10 bytes in LEB128 (9 bytes with 7 bits
    // each = 63 bits, plus a 10th byte for the final bit).
    for (data[0..@min(data.len, 10)], 0..) |byte, i| {
        // If the shift is already 63, then we are processing the 10th byte. It must be
        // either 0x00 (final byte with no value bits) or 0x01 (final byte with the 64th bit set).
        result |= @as(i64, byte & 0x7f) << @intCast(shift);
        // If the high bit is not set, this is the last byte of the value. Perform sign
        // extension if the most significant bit of the value is set.
        shift += 7;
        if (byte & 0x80 == 0) {
            // If the shift is less than 64 and the most significant bit of the value is set, sign-extend.
            if (shift < 64 and (byte & 0x40) != 0) result |= ~@as(i64, 0) << @intCast(shift);
            return .{ result, i + 1 };
        }
    }
    return null;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "readUleb128 zero" {
    const r = readUleb128(&.{0x00}).?;
    try std.testing.expectEqual(@as(u64, 0), r[0]);
    try std.testing.expectEqual(@as(usize, 1), r[1]);
}

test "readUleb128 single-byte max (127)" {
    const r = readUleb128(&.{0x7f}).?;
    try std.testing.expectEqual(@as(u64, 127), r[0]);
    try std.testing.expectEqual(@as(usize, 1), r[1]);
}

test "readUleb128 two-byte 128" {
    const r = readUleb128(&.{ 0x80, 0x01 }).?;
    try std.testing.expectEqual(@as(u64, 128), r[0]);
    try std.testing.expectEqual(@as(usize, 2), r[1]);
}

test "readUleb128 three-byte 624485" {
    // 624485 = 0x98765; canonical DWARF spec encoding example.
    const r = readUleb128(&.{ 0xe5, 0x8e, 0x26 }).?;
    try std.testing.expectEqual(@as(u64, 624485), r[0]);
    try std.testing.expectEqual(@as(usize, 3), r[1]);
}

test "readUleb128 stops at encoded value ignoring trailing bytes" {
    const r = readUleb128(&.{ 0x01, 0xff }).?;
    try std.testing.expectEqual(@as(u64, 1), r[0]);
    try std.testing.expectEqual(@as(usize, 1), r[1]);
}

test "readUleb128 empty slice returns null" {
    try std.testing.expectEqual(null, readUleb128(&.{}));
}

test "readUleb128 truncated multi-byte returns null" {
    try std.testing.expectEqual(null, readUleb128(&.{0x80}));
}

test "readSleb128 positive value 2" {
    const r = readSleb128(&.{0x02}).?;
    try std.testing.expectEqual(@as(i64, 2), r[0]);
    try std.testing.expectEqual(@as(usize, 1), r[1]);
}

test "readSleb128 negative value -2 via sign extension" {
    // 0x7e: continuation=0, value bits=0b1111110=126, bit 6 set → sign-extend
    const r = readSleb128(&.{0x7e}).?;
    try std.testing.expectEqual(@as(i64, -2), r[0]);
    try std.testing.expectEqual(@as(usize, 1), r[1]);
}

test "readSleb128 negative value -64" {
    // 0x40: continuation=0, bit 6 set → sign-extend to -64
    const r = readSleb128(&.{0x40}).?;
    try std.testing.expectEqual(@as(i64, -64), r[0]);
    try std.testing.expectEqual(@as(usize, 1), r[1]);
}

test "readSleb128 two-byte positive 128" {
    const r = readSleb128(&.{ 0x80, 0x01 }).?;
    try std.testing.expectEqual(@as(i64, 128), r[0]);
    try std.testing.expectEqual(@as(usize, 2), r[1]);
}

test "readSleb128 two-byte negative -128" {
    // -128 in SLEB128: 0x80 0x7f
    //   byte 0: 0x80 → value bits = 0, continuation set
    //   byte 1: 0x7f → value bits = 0x7f, bit 6 set → sign-extend
    //   result = (0x7f << 7) | sign_extension = 0x3f80 | 0xFFFFFFFFFFFFC000 = -128
    const r = readSleb128(&.{ 0x80, 0x7f }).?;
    try std.testing.expectEqual(@as(i64, -128), r[0]);
    try std.testing.expectEqual(@as(usize, 2), r[1]);
}

test "readSleb128 empty slice returns null" {
    try std.testing.expectEqual(null, readSleb128(&.{}));
}

test "readSleb128 truncated multi-byte returns null" {
    try std.testing.expectEqual(null, readSleb128(&.{0x80}));
}

test "readUleb128 max u64" {
    // Nine 0xff bytes (each carrying 7 bits of all-ones) followed by 0x01 (the 64th bit).
    const r = readUleb128(&.{ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01 }).?;
    try std.testing.expectEqual(std.math.maxInt(u64), r[0]);
    try std.testing.expectEqual(@as(usize, 10), r[1]);
}

test "readSleb128 three-byte negative -8193" {
    // -8193 encodes as [0xff, 0xbf, 0x7f]:
    //   byte 0: low 7 bits of -8193 = 0x7f, continuation → 0xff
    //   byte 1: low 7 bits of -65  = 0x3f, continuation → 0xbf
    //   byte 2: low 7 bits of -1   = 0x7f, bit 6 set → sign-extend, stop
    const r = readSleb128(&.{ 0xff, 0xbf, 0x7f }).?;
    try std.testing.expectEqual(@as(i64, -8193), r[0]);
    try std.testing.expectEqual(@as(usize, 3), r[1]);
}

test "parseCuHeader rejects version 1" {
    const data = [_]u8{ 100, 0, 0, 0, 1, 0, 8, 0, 0, 0, 4 };
    try std.testing.expectEqual(null, parseCuHeader(&data));
}

test "parseCuHeader parses DWARF v2 header (same layout as v4)" {
    const data = [_]u8{ 100, 0, 0, 0, 2, 0, 8, 0, 0, 0, 4 };
    const cu = parseCuHeader(&data).?;
    try std.testing.expectEqual(@as(u32, 100), cu.unit_length);
    try std.testing.expectEqual(@as(usize, 6), cu.abbrev_offset_field_pos);
    try std.testing.expectEqual(@as(u8, 4), cu.address_size);
    try std.testing.expectEqual(@as(usize, 11), cu.header_size);
}

test "parseCuHeader returns null for too-short v5 data" {
    // version=5 needs at least 12 bytes; supply only 11.
    const data = [_]u8{ 100, 0, 0, 0, 5, 0, 1, 4, 8, 0, 0 };
    try std.testing.expectEqual(null, parseCuHeader(&data));
}

test "patchAttr returns pos immediately when pos >= end" {
    var info = [_]u8{0x00};
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.data4 };
    try std.testing.expectEqual(@as(usize, 1), patchAttr(&info, 1, 1, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances by address_size for addr form" {
    var info = [_]u8{ 0xaa, 0xbb, 0xcc, 0xdd };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.addr };
    try std.testing.expectEqual(@as(usize, 4), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances by 1 for data1 form" {
    var info = [_]u8{0x42};
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.data1 };
    try std.testing.expectEqual(@as(usize, 1), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances by 2 for data2 form" {
    var info = [_]u8{ 0x42, 0x43 };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.data2 };
    try std.testing.expectEqual(@as(usize, 2), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances by 8 for data8 form" {
    var info = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.data8 };
    try std.testing.expectEqual(@as(usize, 8), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances past sdata (sleb128)" {
    var info = [_]u8{ 0x80, 0x01 }; // sleb128 value 128
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.sdata };
    try std.testing.expectEqual(@as(usize, 2), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances past udata (uleb128)" {
    var info = [_]u8{ 0x80, 0x01 }; // uleb128 value 128
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.udata };
    try std.testing.expectEqual(@as(usize, 2), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr does not advance for flag_present" {
    var info = [_]u8{0xaa};
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.flag_present };
    try std.testing.expectEqual(@as(usize, 0), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr does not advance for implicit_const" {
    var info = [_]u8{0xaa};
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.implicit_const };
    try std.testing.expectEqual(@as(usize, 0), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances past null-terminated string" {
    var info = [_]u8{ 'h', 'i', 0, 0xff };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.string };
    try std.testing.expectEqual(@as(usize, 3), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances past block1 (length byte + data)" {
    var info = [_]u8{ 3, 0xaa, 0xbb, 0xcc };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.block1 };
    try std.testing.expectEqual(@as(usize, 4), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances past block2 (u16 length + data)" {
    var info = [_]u8{ 2, 0, 0xaa, 0xbb };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.block2 };
    try std.testing.expectEqual(@as(usize, 4), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances past block4 (u32 length + data)" {
    var info = [_]u8{ 2, 0, 0, 0, 0xaa, 0xbb };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.block4 };
    try std.testing.expectEqual(@as(usize, 6), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances past block (uleb128 length + data)" {
    var info = [_]u8{ 2, 0xaa, 0xbb }; // uleb128 length = 2, then 2 data bytes
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.block };
    try std.testing.expectEqual(@as(usize, 3), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr advances past exprloc (uleb128 length + data)" {
    var info = [_]u8{ 3, 0x01, 0x02, 0x03 };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.exprloc };
    try std.testing.expectEqual(@as(usize, 4), patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0));
}

test "patchAttr sec_offset with unknown attr id advances without patching" {
    var info = [_]u8{ 0x20, 0x30, 0x00, 0x00 };
    const original = std.mem.readInt(u32, info[0..4], .little);
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.sec_offset }; // id=0 is neither stmt_list nor ranges
    _ = patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, 0);
    try std.testing.expectEqual(original, std.mem.readInt(u32, info[0..4], .little));
}

test "patchAttr ref_addr with address_size=8 advances by 8 without patching" {
    const info_base: u32 = 0x5000;
    var info = [_]u8{ 0x0c, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.ref_addr };
    const new_pos = patchAttr(&info, 0, info.len, attr, 8, 0, 0, 0, info_base);
    try std.testing.expectEqual(@as(usize, 8), new_pos);
    try std.testing.expectEqual(@as(u32, 0x0000500c), std.mem.readInt(u32, info[0..4], .little));
}

test "patchAttr indirect resolves inner form and applies patch" {
    const str_base: u32 = 0x1000;
    // DW_FORM_indirect: first byte is the actual form (DW_FORM_strp = 0x0e), then the strp value.
    var info = [_]u8{
        0x0e, // DW_FORM_strp as uleb128 (single byte since < 128)
        0x10, 0x10, 0x00, 0x00, // absolute VMA str_base + 0x10 = 0x1010
    };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.indirect };
    const new_pos = patchAttr(&info, 0, info.len, attr, 4, str_base, 0, 0, 0);
    try std.testing.expectEqual(@as(usize, 5), new_pos);
    try std.testing.expectEqual(@as(u32, 0x10), std.mem.readInt(u32, info[1..5], .little));
}

test "patchDies patches strp attribute in a single DIE" {
    const str_base: u32 = 0x1000;
    // Minimal abbrev: code=1, DW_TAG_compile_unit, no children, DW_AT_name/DW_FORM_strp.
    const abbrev = [_]u8{
        0x01, // abbrev code 1
        0x11, // DW_TAG_compile_unit
        0x00, // DW_CHILDREN_no
        0x03, // DW_AT_name
        0x0e, // DW_FORM_strp
        0x00, 0x00, // end of attributes
        0x00, // end of abbrev table
    };
    var info = [_]u8{
        0x01, // abbrev code = 1
        0x08, 0x10, 0x00, 0x00, // DW_FORM_strp: absolute VMA = str_base + 8 = 0x1008
    };
    patchDies(&info, 0, info.len, &abbrev, 4, str_base, 0, 0, 0);
    try std.testing.expectEqual(@as(u32, 8), std.mem.readInt(u32, info[1..5], .little));
}

test "patchDies null DIE (code=0) is skipped without crashing" {
    const abbrev = [_]u8{0x00};
    var info = [_]u8{0x00}; // null DIE
    patchDies(&info, 0, info.len, &abbrev, 4, 0, 0, 0, 0);
    try std.testing.expectEqual(@as(u8, 0x00), info[0]);
}

test "patchDwarfInfo patches abbrev_offset in two consecutive CUs" {
    const abbrev_base: u32 = 0x2000;
    // Two minimal DWARF v4 CUs: unit_length=7, version=4, absolute abbrev_offset, address_size=4.
    // die_start == cu_end for each, so no DIEs are walked.
    var info = [_]u8{
        // CU 1
        7, 0, 0, 0, // unit_length = 7
        4, 0, // version = 4
        0x10, 0x20, 0x00, 0x00, // abbrev_offset = abbrev_base + 0x10 = 0x2010
        4, // address_size = 4
        // CU 2
        7, 0, 0, 0, // unit_length = 7
        4, 0, // version = 4
        0x20, 0x20, 0x00, 0x00, // abbrev_offset = abbrev_base + 0x20 = 0x2020
        4, // address_size = 4
    };
    patchDwarfInfo(&info, &.{}, abbrev_base, 0x3000, 0x4000, 0x5000, 0x6000);
    try std.testing.expectEqual(@as(u32, 0x10), std.mem.readInt(u32, info[6..10], .little));
    try std.testing.expectEqual(@as(u32, 0x20), std.mem.readInt(u32, info[17..21], .little));
}

test "parseCuHeader returns null for too-short data" {
    try std.testing.expectEqual(null, parseCuHeader(&.{ 0, 0, 0, 0, 4, 0, 0, 0, 0, 0 }));
}

test "parseCuHeader parses DWARF v4 header" {
    // unit_length=100, version=4, abbrev_offset=8, address_size=4
    const data = [_]u8{ 100, 0, 0, 0, 4, 0, 8, 0, 0, 0, 4 };
    const cu = parseCuHeader(&data).?;
    try std.testing.expectEqual(@as(u32, 100), cu.unit_length);
    try std.testing.expectEqual(@as(usize, 6), cu.abbrev_offset_field_pos);
    try std.testing.expectEqual(@as(u8, 4), cu.address_size);
    try std.testing.expectEqual(@as(usize, 11), cu.header_size);
}

test "parseCuHeader parses DWARF v5 header" {
    // unit_length=100, version=5, unit_type=1, address_size=4, abbrev_offset=8
    const data = [_]u8{ 100, 0, 0, 0, 5, 0, 1, 4, 8, 0, 0, 0 };
    const cu = parseCuHeader(&data).?;
    try std.testing.expectEqual(@as(u32, 100), cu.unit_length);
    try std.testing.expectEqual(@as(usize, 8), cu.abbrev_offset_field_pos);
    try std.testing.expectEqual(@as(u8, 4), cu.address_size);
    try std.testing.expectEqual(@as(usize, 12), cu.header_size);
}

test "parseCuHeader rejects unsupported version" {
    // version=6 is not supported
    const data = [_]u8{ 100, 0, 0, 0, 6, 0, 8, 0, 0, 0, 4 };
    try std.testing.expectEqual(null, parseCuHeader(&data));
}

test "patchAttr advances position for data4 without modifying data" {
    var info = [_]u8{ 0xde, 0xad, 0xbe, 0xef };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.data4 };
    const new_pos = patchAttr(&info, 0, info.len, attr, 4, 0x1000, 0x2000, 0x3000, 0x4000);
    try std.testing.expectEqual(@as(usize, 4), new_pos);
    try std.testing.expectEqualSlices(u8, &.{ 0xde, 0xad, 0xbe, 0xef }, &info);
}

test "patchAttr patches strp by subtracting str_base" {
    const str_base: u32 = 0x1000;
    // absolute VMA = str_base + 8 = 0x1008
    var info = [_]u8{ 0x08, 0x10, 0x00, 0x00 };
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.strp };
    const new_pos = patchAttr(&info, 0, info.len, attr, 4, str_base, 0, 0, 0);
    try std.testing.expectEqual(@as(usize, 4), new_pos);
    try std.testing.expectEqual(@as(u32, 8), std.mem.readInt(u32, info[0..4], .little));
}

test "patchAttr leaves strp unchanged when already below str_base" {
    const str_base: u32 = 0x1000;
    var info = [_]u8{ 0x08, 0x00, 0x00, 0x00 }; // 8 < str_base, already relative
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.strp };
    _ = patchAttr(&info, 0, info.len, attr, 4, str_base, 0, 0, 0);
    try std.testing.expectEqual(@as(u32, 8), std.mem.readInt(u32, info[0..4], .little));
}

test "patchAttr patches sec_offset for stmt_list using line_base" {
    const line_base: u32 = 0x3000;
    // absolute VMA = line_base + 0x10 = 0x3010
    var info = [_]u8{ 0x10, 0x30, 0x00, 0x00 };
    const attr: Attr = .{ .id = std.dwarf.AT.stmt_list, .form = std.dwarf.FORM.sec_offset };
    const new_pos = patchAttr(&info, 0, info.len, attr, 4, 0, line_base, 0, 0);
    try std.testing.expectEqual(@as(usize, 4), new_pos);
    try std.testing.expectEqual(@as(u32, 0x10), std.mem.readInt(u32, info[0..4], .little));
}

test "patchAttr patches sec_offset for ranges using ranges_base" {
    const ranges_base: u32 = 0x4000;
    var info = [_]u8{ 0x20, 0x40, 0x00, 0x00 }; // ranges_base + 0x20
    const attr: Attr = .{ .id = std.dwarf.AT.ranges, .form = std.dwarf.FORM.sec_offset };
    _ = patchAttr(&info, 0, info.len, attr, 4, 0, 0, ranges_base, 0);
    try std.testing.expectEqual(@as(u32, 0x20), std.mem.readInt(u32, info[0..4], .little));
}

test "patchAttr patches ref_addr using info_base" {
    const info_base: u32 = 0x5000;
    var info = [_]u8{ 0x0c, 0x50, 0x00, 0x00 }; // info_base + 0x0c
    const attr: Attr = .{ .id = 0, .form = std.dwarf.FORM.ref_addr };
    _ = patchAttr(&info, 0, info.len, attr, 4, 0, 0, 0, info_base);
    try std.testing.expectEqual(@as(u32, 0x0c), std.mem.readInt(u32, info[0..4], .little));
}

test "patchDwarfInfo patches CU header abbrev_offset to section-relative" {
    const abbrev_base: u32 = 0x1000;
    // DWARF v4 CU: unit_length=7 means version(2)+abbrev_offset(4)+address_size(1).
    // With unit_length=7, cu_end = 4+7 = 11 = die_start, so no DIEs are walked.
    // abbrev_offset = abbrev_base + 8 = 0x1008
    var info = [_]u8{
        7, 0, 0, 0, // unit_length = 7
        4, 0, // version = 4
        0x08, 0x10, 0x00, 0x00, // abbrev_offset = 0x1008
        4, // address_size = 4
    };
    patchDwarfInfo(&info, &.{}, abbrev_base, 0x2000, 0x3000, 0x4000, 0x5000);
    const patched = std.mem.readInt(u32, info[6..10], .little);
    try std.testing.expectEqual(@as(u32, 8), patched);
}

test "patchDwarfInfo leaves already-relative abbrev_offset unchanged" {
    const abbrev_base: u32 = 0x1000;
    // abbrev_offset = 8, which is below abbrev_base, so no change expected
    var info = [_]u8{
        7, 0, 0, 0,
        4, 0, 8, 0,
        0, 0, 4,
    };
    patchDwarfInfo(&info, &.{}, abbrev_base, 0x2000, 0x3000, 0x4000, 0x5000);
    const patched = std.mem.readInt(u32, info[6..10], .little);
    try std.testing.expectEqual(@as(u32, 8), patched);
}

test "patchDwarfInfo handles empty info buffer" {
    var info = [_]u8{};
    // Should not crash on empty input.
    patchDwarfInfo(&info, &.{}, 0x1000, 0x2000, 0x3000, 0x4000, 0x5000);
}
