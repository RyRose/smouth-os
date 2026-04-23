const std = @import("std");
const arch = @import("arch");

/// Well-known offsets within the PCI configuration space header.
/// https://en.wikipedia.org/wiki/PCI_configuration_space#Standardized_registers
pub const ConfigurationOffset = enum(u8) {
    /// Vendor ID and Device ID (32 bits at offset 0x00).
    vendor_device = 0x00,
    /// 16-bit Command and Status registers (combined as a 32-bit word at offset 0x04).
    command = 0x04,
    /// Base Address Register 0 (32 bits at offset 0x10).
    bar0 = 0x10,
    /// Capabilities pointer (8 bits at offset 0x34, valid if Status bit 4 is set).
    capabilities_ptr = 0x34,
};

/// PCI Command register (lower 16 bits of the 32-bit word at config offset 0x04).
pub const PciCommand = packed struct(u16) {
    /// Allows the device to respond to I/O port accesses.
    io_space: bool = false,
    /// Allows the device to respond to memory-mapped accesses.
    memory_space: bool = false,
    /// Allows the device to act as a bus master (required for DMA).
    bus_master: bool = false,
    _reserved: u13 = 0,
};

/// PCI Status register (upper 16 bits of the 32-bit word at config offset 0x04).
pub const PciStatus = packed struct(u16) {
    _reserved: u3 = 0,
    /// Asserted while the device has a pending interrupt (INTx).
    interrupt_status: bool = false,
    /// Set when the device has a PCI capability list at offset 0x34.
    capabilities_list: bool = false,
    _rest: u11 = 0,
};

/// Combined Command and Status registers read as a single 32-bit value at config offset 0x04.
pub const CommandStatus = packed struct(u32) {
    /// PCI Command register (offset 0x04).
    command: PciCommand,
    /// PCI Status register (offset 0x06).
    status: PciStatus,
};

/// Vendor and Device ID read as a single 32-bit value at config offset 0x00.
pub const VendorDevice = packed struct(u32) {
    /// PCI vendor ID; 0xFFFF means no device present.
    vendor_id: u16,
    /// PCI device ID.
    device_id: u16,
};

/// 32-bit Base Address Register (BAR) value as returned from PCI configuration space.
pub const Bar32 = packed struct(u32) {
    /// Set when this is an I/O space BAR; clear for MMIO.
    is_io: bool,
    /// MMIO type: 0 = 32-bit, 2 = 64-bit (only valid when `is_io` is false).
    mmio_type: u2,
    /// Set if the MMIO region is prefetchable (only valid when `is_io` is false).
    prefetchable: bool,
    /// Upper 28 bits of the base address; shift left 4 to get the byte address.
    base: u28,

    /// Returns the MMIO base address (lower 4 bits are always zero).
    pub fn mmioBase(self: Bar32) u32 {
        return @as(u32, self.base) << 4;
    }
};

/// ConfigurationAddress represents a PCI configuration address written to the
/// address port (0xCF8) before reading or writing the data port (0xCFC).
/// All fields default to zero (or `true` for `enable`), so callers can use a
/// struct literal and specify only the fields that differ: e.g.
/// `.{ .bus = 0, .device = 3, .register_offset = 0x34 }`.
///
/// The full byte offset (including bits 1:0) is stored so that `configReadByte`
/// can extract the correct byte within the dword. `configRead32` and
/// `configWrite32` align the offset to a 4-byte boundary internally before
/// writing to the port.
pub const ConfigurationAddress = packed struct(u32) {
    /// Byte offset within the configuration space register. The hardware ignores
    /// the bottom 2 bits for the dword access; they are preserved here so that
    /// `configReadByte` can extract the correct byte within the dword.
    register_offset: u8 = 0,

    /// The PCI function number (0-7).
    function: u3 = 0,

    /// The PCI device number (0-31).
    device: u5 = 0,

    /// The PCI bus number (0-255).
    bus: u8 = 0,

    /// Reserved bits. Must be set to 0.
    reserved: u7 = 0,

    /// Enable bit. Must be 1 for the address to be valid.
    enable: bool = true,

    /// Returns a copy of this address with the register offset replaced.
    pub fn atOffsetRaw(self: ConfigurationAddress, offset: u8) ConfigurationAddress {
        var copy = self;
        copy.register_offset = offset;
        return copy;
    }

    /// Returns a copy of this address with the register offset replaced.
    pub fn atOffset(self: ConfigurationAddress, offset: ConfigurationOffset) ConfigurationAddress {
        var copy = self;
        copy.register_offset = @intFromEnum(offset);
        return copy;
    }
};

/// Read a 32-bit value from PCI configuration space.
/// The register offset is aligned down to the nearest 4-byte boundary before
/// writing to the address port; bits 1:0 of `addr.register_offset` are preserved
/// for use by `configReadByte` to select the correct byte within the dword.
pub fn configRead32(addr: ConfigurationAddress) u32 {
    var aligned = addr;
    aligned.register_offset &= 0xFC;
    arch.x86.ioport.outl(.pci_config_addr, @bitCast(aligned));
    return arch.x86.ioport.inl(.pci_config_data);
}

/// Read a single byte from PCI configuration space.
/// The address byte offset is preserved in `addr` for byte extraction within the dword.
pub fn configReadByte(addr: ConfigurationAddress) u8 {
    const dword = configRead32(addr);
    const shift: u5 = @intCast((addr.register_offset & 3) * 8);
    return @truncate(dword >> shift);
}

/// Write a 32-bit value to PCI configuration space.
/// The register offset is aligned down to the nearest 4-byte boundary before
/// writing to the address port.
pub fn configWrite32(addr: ConfigurationAddress, value: u32) void {
    var aligned = addr;
    aligned.register_offset &= 0xFC;
    arch.x86.ioport.outl(.pci_config_addr, @bitCast(aligned));
    arch.x86.ioport.outl(.pci_config_data, value);
}

test ConfigurationAddress {
    try std.testing.expectEqual(32, @bitSizeOf(ConfigurationAddress));

    // bus=1, dev=2, fn=0, offset=0x10 → bit31=enable, bits23-16=bus, bits15-11=dev, bits7-2=offset
    const addr = ConfigurationAddress{ .bus = 1, .device = 2, .register_offset = 0x10 };
    const raw: u32 = @bitCast(addr);
    try std.testing.expectEqual((1 << 31) | (1 << 16) | (2 << 11) | 0x10, raw);
}

test "PciCommand layout" {
    try std.testing.expectEqual(16, @bitSizeOf(PciCommand));
    const cmd = PciCommand{ .memory_space = true, .bus_master = true };
    try std.testing.expectEqual(@as(u16, 0x0006), @as(u16, @bitCast(cmd)));
}

test "CommandStatus layout" {
    try std.testing.expectEqual(32, @bitSizeOf(CommandStatus));
    // Status capabilities_list is bit 4 of the upper 16 bits → bit 20 of the 32-bit word.
    const cs = CommandStatus{ .command = .{}, .status = .{ .capabilities_list = true } };
    try std.testing.expectEqual(@as(u32, 1 << 20), @as(u32, @bitCast(cs)));
}

test "VendorDevice layout" {
    try std.testing.expectEqual(32, @bitSizeOf(VendorDevice));
    const vd: VendorDevice = @bitCast(@as(u32, 0x1059_1AF4));
    try std.testing.expectEqual(@as(u16, 0x1AF4), vd.vendor_id);
    try std.testing.expectEqual(@as(u16, 0x1059), vd.device_id);
}

test "Bar32 mmioBase" {
    try std.testing.expectEqual(32, @bitSizeOf(Bar32));
    // MMIO BAR with base=0xFE000000: raw = 0xFE000000 (is_io=0, type=0, prefetch=0, base=0xFE00000).
    const bar: Bar32 = @bitCast(@as(u32, 0xFE000000));
    try std.testing.expectEqual(false, bar.is_io);
    try std.testing.expectEqual(@as(u32, 0xFE000000), bar.mmioBase());
}
