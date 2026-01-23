const std = @import("std");

pub const ConfigurationAddressPort: u16 = 0xCF8;
pub const ConfigurationDataPort: u16 = 0xCFC;

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
    reserved: u7 = 0,
    /// Enable bit. Must be set to true to indicate a valid address.
    enable: bool = false,

    pub fn init(args: struct {
        register_offset: ConfigurationOffset,
        function: u3,
        device: u5,
        bus: u8,
    }) ConfigurationAddress {
        return ConfigurationAddress{
            .register_offset = args.register_offset,
            .function = args.function,
            .device = args.device,
            .bus = args.bus,
            .enable = true,
        };
    }
};

comptime {
    std.debug.assert(@bitSizeOf(ConfigurationAddress) == 32);
}
