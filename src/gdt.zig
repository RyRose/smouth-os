const std = @import("std");

/// Descriptor is a class that represents a Global Descriptor Table (GDT) segment
/// descriptor. It provides the processor with size, location, access, and status
/// information about a segment. It is correctly packed and thus usable directly
/// in the GDT. It is formatted as follows:
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
    // Lower 32 bits
    limit0: u16 = 0, // bits 0..15
    base0: u24 = 0, // bits 16..39

    // Access byte + flags
    segment_type: u4 = 0, // type
    descriptor_type: u1 = 0, // S
    dpl: u2 = 0, // DPL
    present: u1 = 0, // P

    limit1: u4 = 0, // limit 16..19
    available: u1 = 0, // AVL
    bit64: u1 = 0, // L
    db: u1 = 0, // DB
    granularity: u1 = 0, // G

    base1: u8 = 0, // base 24..31

    pub fn init(args: struct {
        base: u32,
        limit: u32,
        segment_type: u8,
        descriptor_type: bool,
        dpl: u8,
        db: bool,
        granularity: bool,
    }) !Descriptor {
        if ((args.limit >> 20) != 0)
            return error.LimitHighBitsNonZero;

        if ((args.dpl & 0xFC) != 0)
            return error.DplHighBitsNonZero;

        if ((args.segment_type & 0xF0) != 0)
            return error.SegmentTypeHighBitsNonZero;

        var d = Descriptor{};

        d.base0 = @intCast(args.base & 0x00FF_FFFF);
        d.base1 = @intCast((args.base >> 24) & 0xFF);

        d.limit0 = @intCast(args.limit & 0xFFFF);
        d.limit1 = @intCast((args.limit >> 16) & 0xF);

        d.segment_type = @intCast(args.segment_type);
        d.descriptor_type = @intFromBool(args.descriptor_type);
        d.dpl = @intCast(args.dpl);
        d.present = 1;
        d.db = @intFromBool(args.db);
        d.granularity = @intFromBool(args.granularity);

        return d;
    }
};

comptime {
    std.debug.assert(@sizeOf(Descriptor) == 8);
}

/// Installs and flushes the GDT pointed to by gdt_ptr to the processor.
/// Defined in assembly at installAndFlushGDTInternal.S
extern fn installAndFlushGDTInternal(gdt_ptr: u64) void;

/// Table is a generic Global Descriptor Table (GDT) that can hold N descriptors.
pub fn Table(comptime N: usize) type {
    return packed struct {
        table: *[N]Descriptor,

        const Self = @This();

        /// Initializes a GDT table with the provided buffer.
        pub fn init(buffer: *[N]Descriptor) Self {
            return Self{
                .table = buffer,
            };
        }

        /// Registers a descriptor at the given index in the GDT table.
        pub fn register(self: *Self, index: usize, descriptor: Descriptor) !void {
            if (index >= self.table.len)
                return error.IndexOutOfBounds;

            self.table[index] = descriptor;
        }

        /// Returns the pointer to the GDT table in the format required by LGDT.
        pub fn pointer(self: *Self) u64 {
            var gdt_ptr: u64 = @intFromPtr(self.table);
            gdt_ptr <<= 16;
            gdt_ptr |= (3 * @sizeOf(u64)) & 0xFFFF;
            return gdt_ptr;
        }

        /// Installs and flushes the GDT table to the processor.
        pub fn installAndFlush(self: *Self) !void {
            const ptr = self.pointer();
            const addr = ptr >> 16;

            if (addr == 0)
                return error.GdtPointerNull;

            const gdt_usize_addr: usize = @intCast(addr);
            const first_entry = @as(*const u64, @ptrFromInt(gdt_usize_addr));
            if (first_entry.* != 0)
                return error.FirstGdtEntryNotNull;

            installAndFlushGDTInternal(ptr);
        }
    };
}
