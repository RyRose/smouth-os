//! Global Descriptor Table (GDT) code for i386 architecture.
//!

const std = @import("std");

const arch = @import("arch");

const log = std.log.scoped(.gdt);

/// Privilege Levels (DPL) for i386 segments and gates.
/// Ring 0 is the most privileged, Ring 3 the least.
pub const PrivilegeLevel = enum(u2) {
    /// Kernel level privilege.
    ring0 = 0,
    ring1 = 1,
    ring2 = 2,
    /// User level privilege.
    ring3 = 3,
};

/// DescriptorType indicates whether the segment is a system segment or a
/// code/data segment.
pub const DescriptorType = enum(u1) {
    system = 0,
    code_data = 1,
};

/// Bit64 indicates whether the segment contains 64-bit code.
/// Since this is for i386 processors, this is always disabled.
pub const Bit64 = enum(u1) {
    disabled = 0,
    enabled = 1,
};

/// SegmentClass indicates whether the segment is a data or code segment.
pub const SegmentClass = enum(u1) {
    data = 0,
    code = 1,
};

/// ExpandDownConforming indicates whether the segment is an expand-down data
/// segment or a conforming code segment.
pub const ExpandDownConforming = enum(u1) {
    disabled = 0,
    enabled = 1,
};

pub const Accessed = enum(u1) {
    disabled = 0,
    enabled = 1,
};

/// Permission indicates the read/write or execute/read permissions of the
/// segment.
pub const Permission = enum(u1) {
    /// For data segments: read-only. For code segments: execute-only.
    read_or_execute_only = 0,
    /// For data segments: read-write. For code segments: execute-read.
    readwrite_or_readexecute = 1,
};

/// SegmentType encapsulates the type and permissions of a GDT segment.
/// Defaults to zeroed struct.
pub const SegmentType = packed struct {
    accessed: Accessed = .disabled,
    permission: Permission = .read_or_execute_only,
    expand_down_conforming: ExpandDownConforming = .disabled,
    segment_class: SegmentClass = .data,

    pub fn init(args: struct {
        accessed: Accessed = .disabled,
        permission: Permission = .readwrite_or_readexecute,
        expand_down_conforming: ExpandDownConforming = .disabled,
        segment_class: SegmentClass,
    }) SegmentType {
        return SegmentType{
            .accessed = args.accessed,
            .permission = args.permission,
            .expand_down_conforming = args.expand_down_conforming,
            .segment_class = args.segment_class,
        };
    }
};

comptime {
    // SegmentType must be exactly 4 bits.
    const size = @bitSizeOf(SegmentType);
    if (size != 4) {
        @compileError(std.fmt.comptimePrint(
            "SegmentType must be 4 bits, but found {} bits",
            .{size},
        ));
    }
}

test SegmentType {
    const code_segment_type: u4 = @bitCast(SegmentType.init(.{
        .segment_class = .code,
    }));
    try std.testing.expectEqual(0xA, code_segment_type);

    const data_segment_type: u4 = @bitCast(SegmentType.init(.{
        .segment_class = .data,
    }));
    try std.testing.expectEqual(0x2, data_segment_type);
}

/// Descriptor is a class that represents a Global Descriptor Table (GDT)
/// segment descriptor. It provides the processor with size, location, access,
/// and status information about a segment. It is correctly packed and thus
/// usable directly in the GDT. It is formatted as follows:
///
///  31          24 23 22 21  20 19 16 15 14 13 12 11   8 7               0
/// |----------------------------------------------------------------------|
/// |  base 31:24  |G |DB|L |AVL|limit|P | DPL |S | type |   base 23:16    | 4
/// |----------------------------------------------------------------------|
///  31                              16 15                                0
/// |----------------------------------------------------------------------|
/// |          base 15:00              |            limit 15:00            | 0
/// |----------------------------------------------------------------------|
///
/// Where each map to the following:
/// limit => limit0, limit1
///    limit is the max number of (4-kilo)bytes the segment described addresses.
///    If granularity is true, then the unit is 4-kilobytes. Else, bytes. It is
///    20 bits.
/// base => base0, base1
///    base is the base linear memory address for which the segment described
///    addresses.
/// type => segment_type
///    type corresponds whether the segment is for data or code along with read,
///    write, execute permissions.
///
///            Bit Index
///    Hex Dec 11 10 9 8
///    0   0   0  0  0 0 Data Read-Only
///    1   1   0  0  0 1 Data Read-Only, accessed
///    2   2   0  0  1 0 Data Read/Write
///    3   3   0  0  1 1 Data Read/Write, accessed
///    4   4   0  1  0 0 Data Read-Only, expand-down
///    5   5   0  1  0 1 Data Read-Only, expand-down, accessed
///    6   6   0  1  1 0 Data Read/Write, expand-down
///    7   7   0  1  1 1 Data Read/Write, expand-down, accessed
///    8   8   1  0  0 0 Code Execute-Only
///    9   9   1  0  0 1 Code Execute-Only, accessed
///    A   10  1  0  1 0 Code Execute/Read
///    B   11  1  0  1 1 Code Execute/Read, accessed
///    C   12  1  1  0 0 Code Execute-Only, conforming
///    D   13  1  1  0 1 Code Execute-Only, conforming, accessed
///    E   14  1  1  1 0 Code Execute/Read, conforming
///    F   15  1  1  1 1 Code Execute/Read, conforming, accessed
///
/// S => descriptor_type
///   True if the segment is a code/data segment. Else, it's a system segment.
/// DPL => dpl
///   DPL is the descriptor privilege level.
/// P => present
///   P indicates whether the segment should be considered present by the
///   processor.
/// AVL => available
///   AVL is set when the descriptor should be used for system software.
///   Always set to false. Should only be used by the processor.
///   TODO(RyRose): Why would this ever be true?
/// L => bit64
///   If set, the segment type must be a code segment and it indicates the
///   segment contains 64-bit code. Since we don't use IA-32e mode and this is
///   for i386 processors, this is always set to false.
/// DB => db
///   db stands for for Default/Big and has different meanings based on the
///   segment and descriptor type. Should always be set for 32-bit code/data
///   segments and never set for 16-bit code/data segments.
/// G => granularity
///   G determines the scaling of the limit field as described above.
///
pub const Descriptor = packed struct {
    /// Lower 16 bits of the segment limit.
    limit0: u16 = 0,

    /// Lower 24 bits of the segment base address.
    base0: u24 = 0,

    segment_type: SegmentType = .{},

    descriptor_type: DescriptorType = .system,

    /// Descriptor Privilege Level.
    dpl: PrivilegeLevel = .ring0,

    /// Segment present flag.
    present: bool = false,

    /// Upper 4 bits of the segment limit.
    limit1: u4 = 0,

    /// Available for use by system software.
    available: bool = false,

    /// 64-bit code segment flag.
    bit64: Bit64 = Bit64.disabled,

    db: bool = false,

    granularity: bool = false,

    /// Upper 8 bits of the segment base address.
    base1: u8 = 0,

    /// Creates a present GDT segment Descriptor with the provided values.
    pub fn init(args: struct {
        base: u32,
        limit: u20,
        segment_type: SegmentType,
        descriptor_type: DescriptorType = .code_data,
        dpl: PrivilegeLevel = .ring0,
        db: bool,
        granularity: bool,
    }) Descriptor {
        var d = Descriptor{};

        d.base0 = @intCast(args.base & 0x00FF_FFFF);
        d.base1 = @intCast((args.base >> 24) & 0xFF);

        d.limit0 = @intCast(args.limit & 0xFFFF);
        d.limit1 = @intCast((args.limit >> 16) & 0xF);

        d.segment_type = args.segment_type;
        d.descriptor_type = args.descriptor_type;
        d.dpl = args.dpl;
        d.present = true;
        d.db = args.db;
        d.granularity = args.granularity;

        return d;
    }
};

comptime {
    // i386 GDT segment descriptors must be exactly 8 bytes!
    const size = @bitSizeOf(Descriptor);
    if (size != 64) {
        @compileError(std.fmt.comptimePrint(
            "GDT Descriptor must be 64 bits, but found {} bits",
            .{size},
        ));
    }
}

test Descriptor {
    const desc: u64 = @bitCast(Descriptor.init(.{
        .base = 0x12_345678,
        .limit = 0xA_BCDE,
        .segment_type = SegmentType.init(.{ .segment_class = .code }),
        .descriptor_type = .code_data,
        .dpl = .ring0,
        .db = true,
        .granularity = true,
    }));
    try std.testing.expectEqual(0x12_C_A_9_A_345678_BCDE, desc);
    //                            --   -   - ------ ----
    //                            |    |   | |      \-- limit0 (0xBCDE)
    //                            |    |   | \-- base0 (0x345678)
    //                            |    |   \-- segment type (0xA)
    //                            |    \-- limit1 (0xA)
    //                            \-- base1 (0x12)
    //
    // Remaining fields are an exercise to the reader. I manually
    // inspected the bits to verify correctness but was too lazy to
    // write it all out here.
}

/// Table is a generic Global Descriptor Table (GDT) that can hold N
/// descriptors.
pub fn Table(comptime N: usize) type {
    return struct {
        table: [N]Descriptor = [_]Descriptor{.{}} ** N,

        const Self = @This();

        pub fn init() Self {
            return Self{};
        }

        /// Registers a descriptor at the given index in the GDT table.
        pub fn register(
            self: *Self,
            comptime index: usize,
            descriptor: Descriptor,
        ) void {
            if (index >= N)
                @compileError(std.fmt.comptimePrint(
                    "GDT index must be less than {}, but found {}",
                    .{ N, index },
                ));

            self.table[index] = descriptor;
        }

        /// Returns the pointer to the GDT table in the format required by LGDT.
        pub fn pointer(self: *Self) u64 {
            var gdt_ptr: u64 = @intFromPtr(&self.table);
            gdt_ptr <<= 16;
            gdt_ptr |= (3 * @sizeOf(u64)) & 0xFFFF;
            return gdt_ptr;
        }

        /// Installs and flushes the GDT table to the processor.
        /// code_index and data_index are the indices of the code and data
        /// segments in the GDT, respectively. They must be greater than 0 and
        /// less than N.
        pub fn installAndFlush(
            self: *Self,
            comptime code_index: u16,
            comptime data_index: u16,
        ) !void {
            const ptr = self.pointer();
            const addr = ptr >> 16;
            log.debug("Installing GDT at address: 0x{x}", .{addr});

            if (addr == 0)
                return error.GdtPointerNull;
            if (code_index >= N or code_index <= 0)
                @compileError(std.fmt.comptimePrint(
                    "Code segment index must be between 1 and {}, inclusive, but found {}",
                    .{ N - 1, code_index },
                ));
            if (data_index >= N or data_index <= 0)
                @compileError(std.fmt.comptimePrint(
                    "Data segment index must be between 1 and {}, inclusive, but found {}",
                    .{ N - 1, data_index },
                ));

            const gdt_usize_addr: usize = @intCast(addr);
            const first_entry = @as(*const u64, @ptrFromInt(gdt_usize_addr));
            if (first_entry.* != 0)
                return error.FirstGdtEntryNotNull;

            log.debug("Flushing GDT...", .{});
            arch.x86.installAndFlushGDT(ptr, 8 * code_index, 8 * data_index);
        }
    };
}
