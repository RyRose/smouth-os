//! VirtIO MMIO version-2 transport for QEMU's AArch64 `virt` machine.

const std = @import("std");

const virtio = @import("os").kernel.virtio;

const log = std.log.scoped(.virtio_mmio);

/// QEMU `virt` maps 32 fixed VirtIO MMIO transport slots here.
const first_mmio_base: usize = 0x0A00_0000;
/// Distance between adjacent QEMU `virt` VirtIO MMIO transports.
const mmio_stride: usize = 0x200;
/// Number of QEMU `virt` VirtIO MMIO transports to scan.
const mmio_slots: usize = 32;

/// VirtIO MMIO register offsets (§4.2.2).
const Register = enum(usize) {
    /// Magic value register.
    magic_value = 0x000,
    /// Transport version register.
    version = 0x004,
    /// Device identifier register.
    device_id = 0x008,
    /// Device feature bits register.
    device_features = 0x010,
    /// Device feature bank selector.
    device_features_sel = 0x014,
    /// Driver feature bits register.
    driver_features = 0x020,
    /// Driver feature bank selector.
    driver_features_sel = 0x024,
    /// Queue selector.
    queue_sel = 0x030,
    /// Maximum size of selected queue.
    queue_num_max = 0x034,
    /// Requested size of selected queue.
    queue_num = 0x038,
    /// Selected queue ready flag.
    queue_ready = 0x044,
    /// Queue notification register.
    queue_notify = 0x050,
    /// Device status register.
    status = 0x070,
    /// Descriptor-table address low word.
    queue_desc_low = 0x080,
    /// Descriptor-table address high word.
    queue_desc_high = 0x084,
    /// Available-ring address low word.
    queue_avail_low = 0x090,
    /// Available-ring address high word.
    queue_avail_high = 0x094,
    /// Used-ring address low word.
    queue_used_low = 0x0A0,
    /// Used-ring address high word.
    queue_used_high = 0x0A4,
};

/// VirtIO MMIO magic value, the little-endian encoding of `virt`.
const magic_value: u32 = 0x7472_6976;
/// Modern VirtIO MMIO transport version.
const transport_version: u32 = 2;
/// VirtIO device ID for sound.
const sound_device_id: u32 = 25;

/// Modern VirtIO MMIO transport supplied to generic device drivers.
pub const Transport = struct {
    /// Base physical address of this transport's register window.
    base: usize,

    /// Returns a volatile register pointer.
    fn reg(self: *const Transport, comptime offset: Register) *volatile u32 {
        return @ptrFromInt(self.base + @intFromEnum(offset));
    }

    /// Writes a 64-bit physical address to consecutive low/high registers.
    fn writeAddress(self: *const Transport, comptime low: Register, comptime high: Register, address: usize) void {
        self.reg(low).* = @truncate(address);
        self.reg(high).* = @truncate(address >> 32);
    }

    /// Resets the device and waits until the reset completes.
    pub fn reset(self: *const Transport) void {
        self.reg(.status).* = 0;
        while (self.reg(.status).* != 0) std.atomic.spinLoopHint();
    }

    /// Reads device feature bits from `bank`.
    pub fn deviceFeatures(self: *const Transport, bank: virtio.FeatureBank) u32 {
        self.reg(.device_features_sel).* = @intFromEnum(bank);
        return self.reg(.device_features).*;
    }

    /// Writes accepted feature bits to `bank`.
    pub fn driverFeatures(self: *const Transport, bank: virtio.FeatureBank, features: u32) void {
        self.reg(.driver_features_sel).* = @intFromEnum(bank);
        self.reg(.driver_features).* = features;
    }

    /// Writes the device status register.
    pub fn setStatus(self: *const Transport, new_status: virtio.DeviceStatus) void {
        self.reg(.status).* = @as(u32, @as(u8, @bitCast(new_status)));
    }

    /// Reads the device status register.
    pub fn status(self: *const Transport) virtio.DeviceStatus {
        return @bitCast(@as(u8, @truncate(self.reg(.status).*)));
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
        self.reg(.queue_sel).* = idx;
        if (self.reg(.queue_num_max).* < size) return error.QueueTooSmall;
        self.reg(.queue_num).* = size;
        self.writeAddress(.queue_desc_low, .queue_desc_high, desc_addr);
        self.writeAddress(.queue_avail_low, .queue_avail_high, avail_addr);
        self.writeAddress(.queue_used_low, .queue_used_high, used_addr);
        self.reg(.queue_ready).* = 1;
    }

    /// Orders DMA-visible queue memory accesses around device notifications.
    pub fn memoryBarrier(_: *const Transport) void {
        asm volatile ("dmb osh");
    }

    /// Notifies the device of available descriptors on queue `idx`.
    pub fn notifyQueue(self: *const Transport, idx: u16) void {
        self.reg(.queue_notify).* = idx;
    }
};

/// Scans QEMU's fixed VirtIO MMIO slots and returns the VirtIO sound transport.
pub fn findSoundDevice() !Transport {
    for (0..mmio_slots) |slot| {
        const transport = Transport{ .base = first_mmio_base + slot * mmio_stride };
        if (transport.reg(.magic_value).* != magic_value) continue;
        if (transport.reg(.version).* != transport_version) continue;
        if (transport.reg(.device_id).* != sound_device_id) continue;
        log.info("VirtIO sound MMIO at 0x{X}", .{transport.base});
        return transport;
    }
    return error.NoDevice;
}
