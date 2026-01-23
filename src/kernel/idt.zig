const std = @import("std");

/// Gate types for i386 IDT entries.
pub const GateType = enum(u8) {
    empty = 0,
    task = 0x5,
    interrupt_32bit = 0xE,
    trap_32bit = 0xF,
};

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

/// A struct representing a 32-bit descriptor to be stored in the Interrupt
/// Descriptor Table (IDT). Packed such that it can be directly used as elements
/// in the i386 IDT.
pub const Descriptor = packed struct {
    /// The first 2 bytes of offset to the interrupt procedure entry point.
    /// Basically, a pointer to the function that handles this interrupt.
    offset_first: u16 = 0,

    /// The segment selector for the code segment that contains the interrupt
    /// handler. This is usually the kernel's code segment. It is a 16-bit
    /// value where the first 13 bits are the index into the GDT/LDT and the
    /// last 3 bits are the Requested Privilege Level (RPL) and Table
    /// Indicator (TI) bits.
    segment_selector: u16 = 0,

    /// A byte that should always be zero.
    zeroes: u8 = 0,

    /// Four bits that determine the gate type (Interrupt/Task/Trap) and 16/32
    /// bitness.
    gate_type: u4 = @intCast(GateType.empty),

    /// Whether this descriptor points to a code/data segment. Else, it points
    /// to some other system segment. We consider interrupt handlers some other
    /// system segment and thus this bit should always be false.
    segment: bool = false,

    /// Two bits that correspond to the 2-bit Descriptor Privilege Level (DPL)
    /// field in the descriptor. This determines which privilege levels can access
    /// this segment/gate. Ring 0 is the most privileged, Ring 3 the least.
    /// For interrupt gates, this determines the lowest privilege level that
    /// can invoke the interrupt via the INT instruction.
    dpl: u2 = @intCast(PrivilegeLevel.ring0),

    /// Whether or not the segment is present.
    present: bool = false,

    /// The last 2 bytes of the offset.
    offset_second: u16 = 0,

    /// Creates a present interrupt GateDescriptor with the provided values.
    pub fn init(args: struct {
        offset: u32,
        segment_selector: struct { index: u13, rpl: PrivilegeLevel = .ring0 },
        gate_type: GateType = .interrupt_32bit,
        dpl: PrivilegeLevel = .ring0,
    }) Descriptor {
        const rpl: u16 = @intCast(args.segment_selector.rpl);
        return .{
            .offset_first = @intCast(args.offset & 0xFFFF),
            .segment_selector = (args.segment_selector.index << 3) | rpl,
            .gate_type = @intCast(args.gate_type),
            .dpl = @intCast(args.dpl),
            .present = true,
            .offset_second = @intCast((args.offset >> 16) & 0xFFFF),
        };
    }
};

comptime {
    // i386 IDT gate descriptors must be 8 bytes!
    std.debug.assert(@sizeOf(Descriptor) == 8, "GateDescriptor must be 8 bytes!");
}

/// Table represents the i386 IDT.
pub fn Table(comptime N: usize) type {
    return packed struct {
        /// The interrupt descriptor table.
        table: [N]Descriptor = undefined,

        const Self = @This();

        /// Registers the interrupt gate descriptor at the given index.
        pub fn register(self: *Self, index: usize, descriptor: Descriptor) void {
            self.table[index] = descriptor;
        }

        /// Returns a 48-bit value to be stored in the IDTR.
        pub fn idtr(self: *Self) u64 {
            var ret: u64 = @intFromPtr(&self.table);
            ret <<= 16;
            ret |= 8 * N - 1;
            return ret;
        }
    };
}
