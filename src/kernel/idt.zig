//! i386 Interrupt Descriptor Table (IDT) definitions.
//!

const std = @import("std");

const log = std.log.scoped(.idt);

/// Interrupt types for i386 architecture.
pub const InterruptType = enum(u8) {
    /// Divide by Zero Exception
    /// Raised when the processor detects a division by zero condition.
    divide_by_zero = 0,
    debug = 1,
    /// Non-Maskable Interrupt (NMI)
    /// A high-priority interrupt that cannot be ignored by the processor.
    non_maskable_interrupt = 2,
    breakpoint = 3,
    overflow = 4,
    bound_range_exceeded = 5,
    invalid_opcode = 6,
    device_not_available = 7,
    /// Double Fault Exception
    /// Occurs when the processor encounters a second exception while trying to
    /// service a prior exception.
    /// This is a critical error that typically indicates a serious problem
    /// with the system.
    double_fault = 8,
    coprocessor_segment_overrun = 9,
    invalid_tss = 10,
    segment_not_present = 11,
    stack_segment_fault = 12,
    general_protection_fault = 13,
    page_fault = 14,
    x87_floating_point_exception = 16,
    alignment_check = 17,
    machine_check = 18,
    simd_floating_point_exception = 19,
    virtualization_exception = 20,
};

/// Gate types for i386 IDT entries.
pub const GateType = enum(u4) {
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

pub const TableIndicator = enum(u1) {
    /// Global Descriptor Table
    gdt = 0,
    /// Local Descriptor Table
    ldt = 1,
};

/// A struct representing a segment selector in i386 architecture.
/// Packed such that it can be directly used in segment selector fields.
pub const SegmentSelector = packed struct {
    /// The Requested Privilege Level (RPL) bits.
    rpl: PrivilegeLevel = .ring0,
    /// The Table Indicator (TI) bit. Specifies whether the selector refers to
    /// the GDT or LDT.
    ti: TableIndicator = .gdt,
    /// The index into the GDT or LDT. This is a 13-bit value.
    index: u13 = 0,
};

comptime {
    // SegmentSelector must be exactly 16 bits (2 bytes).
    const size = @bitSizeOf(SegmentSelector);
    if (size != 16) {
        @compileError(std.fmt.comptimePrint(
            "SegmentSelector must be 16 bits, but found {} bits",
            .{size},
        ));
    }
}

test SegmentSelector {
    const code_segment: u16 = @bitCast(SegmentSelector{ .index = 1 });
    try std.testing.expectEqual(0x8, code_segment);
}

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
    segment_selector: SegmentSelector = .{},

    /// A byte that should always be zero.
    zeroes: u8 = 0,

    /// Four bits that determine the gate type (Interrupt/Task/Trap) and 16/32
    /// bitness.
    gate_type: GateType = GateType.empty,

    /// Whether this descriptor points to a code/data segment. Else, it points
    /// to some other system segment. We consider interrupt handlers some other
    /// system segment and thus this bit should always be false.
    segment: bool = false,

    /// Two bits that correspond to the 2-bit Descriptor Privilege Level (DPL)
    /// field in the descriptor. This determines which privilege levels can
    /// access
    /// this segment/gate. Ring 0 is the most privileged, Ring 3 the least.
    /// For interrupt gates, this determines the lowest privilege level that
    /// can invoke the interrupt via the INT instruction.
    dpl: PrivilegeLevel = PrivilegeLevel.ring0,

    /// Whether or not the segment is present.
    present: bool = false,

    /// The last 2 bytes of the offset.
    offset_second: u16 = 0,

    /// Creates a present interrupt GateDescriptor with the provided values.
    pub fn init(args: struct {
        offset: u32,
        segment_selector: SegmentSelector,
        gate_type: GateType = .interrupt_32bit,
        dpl: PrivilegeLevel = .ring0,
    }) Descriptor {
        return .{
            .offset_first = @intCast(args.offset & 0xFFFF),
            .segment_selector = args.segment_selector,
            .gate_type = args.gate_type,
            .dpl = args.dpl,
            .present = true,
            .offset_second = @intCast((args.offset >> 16) & 0xFFFF),
        };
    }
};

comptime {
    // i386 IDT gate descriptors must be exactly 8 bytes!
    const size = @bitSizeOf(Descriptor);
    if (size != 64) {
        @compileError(std.fmt.comptimePrint(
            "IDT Descriptor must be 64 bits, but found {} bits",
            .{size},
        ));
    }
}

/// Table represents the i386 IDT.
pub fn Table(comptime N: usize) type {
    return struct {
        /// The interrupt descriptor table.
        table: [N]Descriptor = [_]Descriptor{.{}} ** N,

        const Self = @This();

        pub fn init() Self {
            return Self{};
        }

        /// Registers the interrupt gate descriptor at the given index.
        pub fn register(
            self: *Self,
            index: InterruptType,
            descriptor: Descriptor,
        ) void {
            log.debug("Registering IDT entry for interrupt type {}", .{index});
            self.table[@intFromEnum(index)] = descriptor;
        }

        /// Returns a 48-bit value to be stored in the IDTR.
        pub fn idtr(self: *Self) u64 {
            var ret: u64 = @intFromPtr(&self.table);
            ret <<= 16;
            if (N > 0) {
                ret |= 8 * N - 1;
            }
            return ret;
        }

        pub fn load(self: *Self) !void {
            const idtr_desc = self.idtr();
            log.debug("Loading IDT with IDTR value: 0x{x}", .{idtr_desc});
            asm volatile ("LIDT (%[idtr])"
                :
                : [idtr] "rax" (&idtr_desc),
            );
        }
    };
}

comptime {
    const table1 = @bitSizeOf(Table(1));
    if (table1 != 64) {
        @compileError(std.fmt.comptimePrint(
            "Table(1) must be 64 bits, but found {} bits",
            .{table1},
        ));
    }

    const table4 = @bitSizeOf(Table(4));
    if (table4 != 256) {
        @compileError(std.fmt.comptimePrint(
            "Table(4) must be 256 bits, but found {} bits",
            .{table4},
        ));
    }
}

test "IDT Descriptor Initialization" {
    const desc = Descriptor.init(.{
        .offset = 0x12345678,
        .segment_selector = SegmentSelector{ .index = 1 },
        .gate_type = .interrupt_32bit,
        .dpl = .ring0,
    });
    try std.testing.expectEqual(0x5678, desc.offset_first);
    try std.testing.expectEqual(0x1234, desc.offset_second);
    try std.testing.expectEqual(1, desc.segment_selector.index);
    try std.testing.expectEqual(true, desc.present);
    try std.testing.expectEqual(GateType.interrupt_32bit, desc.gate_type);
    try std.testing.expectEqual(PrivilegeLevel.ring0, desc.dpl);
}
