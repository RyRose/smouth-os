//! Modern VirtIO PCI transport support for the x86 QEMU machine.

const builtin = @import("builtin");
const std = @import("std");

const pci = @import("pci.zig");
const virtio = @import("os").kernel.virtio;

const log = std.log.scoped(.virtio_pci);

/// PCI vendor ID assigned to VirtIO devices.
const virtio_vendor_id: u16 = 0x1AF4;
/// Modern PCI device ID for VirtIO sound.
const virtio_sound_device_id: u16 = 0x1059;

/// VirtIO PCI capability types (§4.1.4).
const CfgType = enum(u8) {
    /// Common configuration region.
    common_cfg = 1,
    /// Queue notification region.
    notify_cfg = 2,
    /// Interrupt status region.
    isr_cfg = 3,
    /// Device-specific configuration region.
    device_cfg = 4,
    /// PCI configuration access region.
    pci_cfg = 5,
    /// Shared-memory region.
    shared_memory_cfg = 8,
    /// Vendor-specific region.
    vendor_cfg = 9,
};

/// Modern VirtIO PCI common configuration layout (§4.1.4.3).
const CommonCfg = extern struct {
    /// Device feature bank selector.
    device_feature_select: virtio.FeatureBank,
    /// Device feature bits from the selected bank.
    device_feature: u32,
    /// Driver feature bank selector.
    driver_feature_select: virtio.FeatureBank,
    /// Driver feature bits for the selected bank.
    driver_feature: u32,
    /// Configuration MSI-X vector.
    config_msix_vector: u16,
    /// Number of device queues.
    num_queues: u16,
    /// Device status.
    device_status: virtio.DeviceStatus,
    /// Device configuration generation.
    config_generation: u8,
    /// Queue selector.
    queue_select: u16,
    /// Selected queue size.
    queue_size: u16,
    /// Queue MSI-X vector.
    queue_msix_vector: u16,
    /// Queue enable flag.
    queue_enable: u16,
    /// Queue notification offset.
    queue_notify_off: u16,
    /// Descriptor-table physical address.
    queue_desc: u64,
    /// Available-ring physical address.
    queue_driver: u64,
    /// Used-ring physical address.
    queue_device: u64,
};

comptime {
    std.debug.assert(@sizeOf(CommonCfg) == 56);
}

/// Resolved PCI capability addresses required by a modern VirtIO device.
const Caps = struct {
    /// Common configuration register block.
    common: *volatile CommonCfg,
    /// Queue notification base address.
    notify_base: usize,
    /// Notification stride in bytes.
    notify_mult: u32,
};

/// PCI-backed VirtIO transport supplied to generic device drivers.
pub const Transport = struct {
    /// Device PCI capabilities.
    caps: Caps,

    /// Resets the device and waits for the reset to finish.
    pub fn reset(self: *const Transport) void {
        self.caps.common.device_status = .{};
        while (@as(u8, @bitCast(@as(*volatile virtio.DeviceStatus, &self.caps.common.device_status).*)) != 0)
            std.atomic.spinLoopHint();
    }

    /// Returns device feature bits from `bank`.
    pub fn deviceFeatures(self: *const Transport, bank: virtio.FeatureBank) u32 {
        self.caps.common.device_feature_select = bank;
        return self.caps.common.device_feature;
    }

    /// Writes accepted driver feature bits to `bank`.
    pub fn driverFeatures(self: *const Transport, bank: virtio.FeatureBank, features: u32) void {
        self.caps.common.driver_feature_select = bank;
        self.caps.common.driver_feature = features;
    }

    /// Writes the device status register.
    pub fn setStatus(self: *const Transport, new_status: virtio.DeviceStatus) void {
        self.caps.common.device_status = new_status;
    }

    /// Reads the device status register.
    pub fn status(self: *const Transport) virtio.DeviceStatus {
        return self.caps.common.device_status;
    }

    /// Registers and enables a queue backed by identity-mapped physical memory.
    pub fn setupQueue(
        self: *const Transport,
        idx: u16,
        size: u16,
        desc_addr: usize,
        avail_addr: usize,
        used_addr: usize,
    ) !void {
        const common = self.caps.common;
        common.queue_select = idx;
        if (common.queue_size < size) return error.QueueTooSmall;
        common.queue_size = size;
        common.queue_msix_vector = 0xFFFF;
        common.queue_desc = desc_addr;
        common.queue_driver = avail_addr;
        common.queue_device = used_addr;
        common.queue_enable = 1;
    }

    /// Makes descriptor and ring writes visible before notifying the device.
    pub fn memoryBarrier(_: *const Transport) void {
        asm volatile ("mfence");
    }

    /// Notifies the device that queue `idx` has new available descriptors.
    pub fn notifyQueue(self: *const Transport, idx: u16) void {
        const common = self.caps.common;
        common.queue_select = idx;
        const addr = self.caps.notify_base + @as(usize, common.queue_notify_off) * self.caps.notify_mult;
        @as(*volatile u16, @ptrFromInt(addr)).* = idx;
    }
};

/// Finds and enables the QEMU VirtIO sound PCI function.
pub fn findSoundDevice() !Transport {
    const found = findDevice(virtio_vendor_id, virtio_sound_device_id) orelse return error.NoDevice;
    log.info("VirtIO sound at PCI bus={} dev={}", .{ found.bus, found.dev });

    const dev_addr = pci.ConfigurationAddress{ .bus = found.bus, .device = found.dev };
    var command_status: pci.CommandStatus = @bitCast(pci.configRead32(dev_addr.atOffset(.command)));
    command_status.command.memory_space = true;
    command_status.command.bus_master = true;
    pci.configWrite32(dev_addr.atOffset(.command), @bitCast(command_status));

    return .{ .caps = try walkCaps(found.bus, found.dev) };
}

/// Scans the PCI bus for a function matching `vendor_id` and `device_id`.
fn findDevice(vendor_id: u16, device_id: u16) ?struct { bus: u8, dev: u5 } {
    for (0..256) |bus| {
        for (0..32) |dev| {
            const vendor_device: pci.VendorDevice = @bitCast(pci.configRead32(.{
                .bus = @intCast(bus),
                .device = @intCast(dev),
                .register_offset = @intFromEnum(pci.ConfigurationOffset.vendor_device),
            }));
            if (vendor_device.vendor_id == vendor_id and vendor_device.device_id == device_id)
                return .{ .bus = @intCast(bus), .dev = @intCast(dev) };
        }
    }
    return null;
}

/// Resolves the common and notify capabilities of a modern VirtIO PCI function.
fn walkCaps(bus: u8, dev: u5) !Caps {
    const dev_addr = pci.ConfigurationAddress{ .bus = bus, .device = dev };
    const command_status: pci.CommandStatus = @bitCast(pci.configRead32(dev_addr.atOffset(.command)));
    if (!command_status.status.capabilities_list) return error.NoCaps;

    var common_addr: usize = 0;
    var notify_addr: usize = 0;
    var notify_mult: u32 = 0;
    var cap_offset = pci.configReadByte(dev_addr.atOffset(.capabilities_ptr));
    while (cap_offset != 0) {
        const next = pci.configReadByte(dev_addr.atOffsetRaw(cap_offset + 1));
        defer cap_offset = next;

        const capability = pci.configReadByte(dev_addr.atOffsetRaw(cap_offset));
        if (capability != @intFromEnum(pci.CapabilityId.vendor_specific)) continue;
        const cfg_type = std.enums.fromInt(CfgType, pci.configReadByte(dev_addr.atOffsetRaw(cap_offset + 3))) orelse continue;
        const bar_idx = pci.configReadByte(dev_addr.atOffsetRaw(cap_offset + 4));
        const bar: pci.Bar32 = @bitCast(pci.configRead32(dev_addr.atOffsetRaw(
            @intFromEnum(pci.ConfigurationOffset.bar0) + bar_idx * 4,
        )));
        if (bar.is_io) continue;

        const addr = @as(usize, bar.mmioBase()) + pci.configRead32(dev_addr.atOffsetRaw(cap_offset + 8));
        switch (cfg_type) {
            .common_cfg => common_addr = addr,
            .notify_cfg => {
                notify_addr = addr;
                notify_mult = pci.configRead32(dev_addr.atOffsetRaw(cap_offset + 16));
            },
            else => {},
        }
    }
    if (common_addr == 0 or notify_addr == 0 or notify_mult == 0) return error.MissingCaps;
    return .{
        .common = @ptrFromInt(common_addr),
        .notify_base = notify_addr,
        .notify_mult = notify_mult,
    };
}

test "findSoundDevice locates QEMU VirtIO sound" {
    if (builtin.os.tag != .freestanding) return error.SkipZigTest;
    _ = try findSoundDevice();
}
