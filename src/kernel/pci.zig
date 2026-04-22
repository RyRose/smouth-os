const std = @import("std");
const arch = @import("arch");

/// IO port for addressing PCI configuration space.
pub const ConfigurationAddressPort: u16 = arch.x86.ioport.Port.pci_config_addr.addr();

/// IO port for accessing PCI configuration space.
pub const ConfigurationDataPort: u16 = arch.x86.ioport.Port.pci_config_data.addr();

/// PCIConfigOffset represents offsets within the PCI configuration space.
/// https://en.wikipedia.org/wiki/PCI_configuration_space#Standardized_registers
pub const ConfigurationOffset = enum(u8) {
    vendor_device = 0x00,
};

/// ConfigurationAddress represents a PCI configuration address to
/// access PCI configuration space registers.
pub const ConfigurationAddress = packed struct {
    /// The offset within the PCI configuration space.
    register_offset: ConfigurationOffset = .vendor_device,

    /// The PCI function number (0-7).
    function: u3 = 0,

    /// The PCI device number (0-31).
    device: u5 = 0,

    /// The PCI bus number (0-255).
    bus: u8 = 0,

    /// Reserved bits. Must be set to 0.
    reserved: u7 = 0,

    /// Enable bit. Must be set to true to indicate a valid address.
    enable: bool = false,

    /// Initializes a ConfigurationAddress with the given parameters.
    pub fn init(args: struct {
        /// The offset within the PCI configuration space.
        register_offset: ConfigurationOffset,
        /// The PCI function number (0-7).
        function: u3,
        /// The PCI device number (0-31).
        device: u5,
        /// The PCI bus number (0-255).
        bus: u8,
    }) ConfigurationAddress {
        return .{
            .register_offset = args.register_offset,
            .function = args.function,
            .device = args.device,
            .bus = args.bus,
            .enable = true,
        };
    }
};

/// Read a 32-bit value from PCI configuration space.
pub fn configRead32(bus: u8, device: u5, function: u3, offset: u8) u32 {
    const addr: u32 = (1 << 31) |
        (@as(u32, bus) << 16) |
        (@as(u32, device) << 11) |
        (@as(u32, function) << 8) |
        (offset & 0xFC);
    arch.x86.ioport.outl(.pci_config_addr, addr);
    return arch.x86.ioport.inl(.pci_config_data);
}

/// Read a single byte from PCI configuration space at an arbitrary byte offset.
/// PCI config reads are 32-bit aligned; the byte is extracted by masking and shifting.
pub fn configReadByte(bus: u8, device: u5, function: u3, offset: u8) u8 {
    const dword = configRead32(bus, device, function, offset & 0xFC);
    const shift: u5 = @intCast((offset & 3) * 8);
    return @truncate(dword >> shift);
}

/// Write a 32-bit value to PCI configuration space.
pub fn configWrite32(bus: u8, device: u5, function: u3, offset: u8, value: u32) void {
    const addr: u32 = (1 << 31) |
        (@as(u32, bus) << 16) |
        (@as(u32, device) << 11) |
        (@as(u32, function) << 8) |
        (offset & 0xFC);
    arch.x86.ioport.outl(.pci_config_addr, addr);
    arch.x86.ioport.outl(.pci_config_data, value);
}

test ConfigurationAddress {
    const size = @bitSizeOf(ConfigurationAddress);
    try std.testing.expectEqual(size, 32);
}
