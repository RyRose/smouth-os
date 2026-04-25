//! General VirtIO PCI helpers: capability discovery, common configuration,
//! and virtqueue types shared by all VirtIO device drivers.

const std = @import("std");
const pci = @import("pci.zig");

const log = std.log.scoped(.virtio);

// ── Device status bits (§2.1) ────────────────────────────────────────────────

/// VirtIO device status register (§2.1).
pub const DeviceStatus = packed struct(u8) {
    /// Driver has noticed the device.
    acknowledge: bool = false,
    /// Driver knows how to drive the device.
    driver: bool = false,
    /// Driver is ready to drive the device.
    driver_ok: bool = false,
    /// Driver has accepted the negotiated feature set.
    features_ok: bool = false,
    _reserved: u4 = 0,
};

// ── Feature bits ─────────────────────────────────────────────────────────────

/// Feature bit 32 (driver_feature_select=1, bit 0): required for modern VirtIO.
pub const virtio_f_version_1: u32 = 1;

// ── PCI capability identifiers ───────────────────────────────────────────────

/// PCI capability vendor ID identifying a VirtIO vendor-specific capability.
pub const pci_cap_vndr: u8 = 0x09;
/// VirtIO capability type for the common configuration region.
pub const cap_common_cfg: u8 = 1;
/// VirtIO capability type for the queue notify region.
pub const cap_notify_cfg: u8 = 2;

// ── VirtIO PCI CommonCfg MMIO layout (§4.1.4.3) ──────────────────────────────

/// MMIO layout of the VirtIO PCI common configuration structure (§4.1.4.3).
/// Mapped directly from the BAR region identified by the CommonCfg capability.
pub const CommonCfg = extern struct {
    /// Selects which 32-bit bank of device feature bits to read via `device_feature`.
    device_feature_select: u32, // +0
    /// Device feature bits for the bank selected by `device_feature_select`.
    device_feature: u32, // +4
    /// Selects which 32-bit bank of driver feature bits to write via `driver_feature`.
    driver_feature_select: u32, // +8
    /// Driver feature bits accepted for the bank selected by `driver_feature_select`.
    driver_feature: u32, // +12
    /// MSI-X vector for configuration change events (0xFFFF = disabled).
    config_msix_vector: u16, // +16
    /// Number of virtqueues supported by the device.
    num_queues: u16, // +18
    /// Device status register; written by driver to progress the init handshake.
    device_status: DeviceStatus, // +20
    /// Incremented by the device whenever its configuration space changes.
    config_generation: u8, // +21
    /// Selects which queue subsequent queue_* fields apply to.
    queue_select: u16, // +22
    /// Maximum (or negotiated) size of the selected queue.
    queue_size: u16, // +24
    /// MSI-X vector for the selected queue (0xFFFF = disabled).
    queue_msix_vector: u16, // +26
    /// Write 1 to activate the selected queue after populating its addresses.
    queue_enable: u16, // +28
    /// Per-queue multiplier index into the notify region for the selected queue.
    queue_notify_off: u16, // +30
    /// Physical address of the descriptor table for the selected queue.
    queue_desc: u64, // +32
    /// Physical address of the driver (available) ring for the selected queue.
    queue_driver: u64, // +40
    /// Physical address of the device (used) ring for the selected queue.
    queue_device: u64, // +48
};

comptime {
    std.debug.assert(@offsetOf(CommonCfg, "device_status") == 20);
    std.debug.assert(@offsetOf(CommonCfg, "queue_notify_off") == 30);
    std.debug.assert(@offsetOf(CommonCfg, "queue_desc") == 32);
    std.debug.assert(@offsetOf(CommonCfg, "queue_driver") == 40);
    std.debug.assert(@offsetOf(CommonCfg, "queue_device") == 48);
}

// ── Virtqueue types ───────────────────────────────────────────────────────────

/// A single virtqueue descriptor table entry.
pub const Desc = extern struct {
    /// Physical address of the buffer.
    addr: u64,
    /// Length of the buffer in bytes.
    len: u32,
    /// Descriptor flags (NEXT, WRITE, etc.).
    flags: DescFlags,
    /// Index of the next descriptor in a chained sequence (valid when NEXT is set).
    next: u16,
};

/// Virtqueue descriptor flags (§2.7.5).
pub const DescFlags = packed struct(u16) {
    /// Descriptor chains to the next (`.next` is valid).
    next: bool = false,
    /// Buffer is writable by the device (otherwise read-only).
    write: bool = false,
    _reserved: u14 = 0,
};

/// Returns the type for a driver-side (available) ring with `size` descriptor slots.
pub fn AvailRing(comptime size: u16) type {
    return extern struct {
        /// Ring flags (e.g. VIRTQ_AVAIL_F_NO_INTERRUPT).
        flags: u16,
        /// Index of the next slot the driver will write; wraps at 65535.
        idx: u16,
        /// Circular array of descriptor head indices made available to the device.
        ring: [size]u16,
    };
}

/// One entry in the device-side (used) ring, written by the device on completion.
pub const UsedElem = extern struct {
    /// Index of the descriptor chain head that was consumed.
    id: u32,
    /// Total bytes written into writable descriptors in the chain.
    len: u32,
};

/// Returns the type for a device-side (used) ring with `size` descriptor slots.
pub fn UsedRing(comptime size: u16) type {
    return extern struct {
        /// Ring flags (e.g. VIRTQ_USED_F_NO_NOTIFY).
        flags: u16,
        /// Index of the next slot the device will write; wraps at 65535.
        idx: u16,
        /// Circular array of completed descriptor entries written by the device.
        ring: [size]UsedElem,
    };
}

// ── Capability discovery ──────────────────────────────────────────────────────

/// Resolved MMIO locations needed to drive a VirtIO PCI device.
pub const Caps = struct {
    /// Pointer to the CommonCfg MMIO region for queue and feature negotiation.
    common: *volatile CommonCfg,
    /// Base address of the notify region; individual queue doorbells are at
    /// `notify_base + queue_notify_off * notify_mult`.
    notify_base: usize,
    /// Per-queue byte stride within the notify region.
    notify_mult: u32,
};

/// Walk the PCI capability list for a VirtIO device and locate the CommonCfg
/// and Notify MMIO regions. Returns null if either capability is missing.
pub fn walkCaps(bus: u8, dev: u5) ?Caps {
    const dev_addr = pci.ConfigurationAddress{ .bus = bus, .device = dev };

    // PCI status register bit 4 indicates a capability list is present.
    const cs: pci.CommandStatus = @bitCast(pci.configRead32(dev_addr.atOffset(.command)));
    if (!cs.status.capabilities_list) {
        log.err("device has no PCI capability list", .{});
        return null;
    }

    var common_addr: usize = 0;
    var notify_addr: usize = 0;
    var notify_mult: u32 = 0;

    var cap_offset = pci.configReadByte(dev_addr.atOffset(.capabilities_ptr));
    while (cap_offset != 0) {
        // cap_vndr is the PCI capability ID.
        const cap_vndr = pci.configReadByte(dev_addr.atOffsetRaw(cap_offset));
        // cap_next is the offset of the next capability in the list (0 if this is the last one).
        const cap_next = pci.configReadByte(dev_addr.atOffsetRaw(cap_offset + 1));

        if (cap_vndr == pci_cap_vndr) {
            // cfg_type is the VirtIO capability type (e.g. common_cfg, notify_cfg).
            const cfg_type = pci.configReadByte(dev_addr.atOffsetRaw(cap_offset + 3));
            // bar_idx is which BAR (0–5) the capability's MMIO region is located in.
            const bar_idx = pci.configReadByte(dev_addr.atOffsetRaw(cap_offset + 4));
            // cap_bar_offset is the offset within the BAR where the capability's MMIO region starts.
            const cap_bar_offset = pci.configRead32(dev_addr.atOffsetRaw(cap_offset + 8));

            // Read the BAR to find the MMIO base address for this capability. Skip if it's an I/O BAR.
            const bar: pci.Bar32 = @bitCast(pci.configRead32(dev_addr.atOffsetRaw(
                @intFromEnum(pci.ConfigurationOffset.bar0) + @as(u8, bar_idx) * 4,
            )));
            if (bar.is_io) {
                cap_offset = cap_next;
                continue;
            }
            const mmio = bar.mmioBase() + cap_bar_offset;

            switch (cfg_type) {
                cap_common_cfg => {
                    common_addr = mmio;
                    log.debug("common_cfg MMIO=0x{X}", .{mmio});
                },
                cap_notify_cfg => {
                    notify_addr = mmio;
                    notify_mult = pci.configRead32(dev_addr.atOffsetRaw(cap_offset + 16));
                    log.debug("notify MMIO=0x{X} mult={}", .{ mmio, notify_mult });
                },
                else => {},
            }
        }

        cap_offset = cap_next;
    }

    if (common_addr == 0 or notify_addr == 0) {
        log.err("missing common_cfg or notify capability", .{});
        return null;
    }

    return .{
        .common = @ptrFromInt(common_addr),
        .notify_base = notify_addr,
        .notify_mult = notify_mult,
    };
}

// ── Device discovery ──────────────────────────────────────────────────────────

/// PCI bus and device slot of a discovered PCI device.
pub const DeviceAddr = struct {
    /// PCI bus number (0–255).
    bus: u8,
    /// PCI device slot number (0–31).
    dev: u5,
};

/// Scan all PCI buses and slots for a device matching `vendor_id` and `device_id`.
/// Returns the bus and device number on success, null if not found.
pub fn findDevice(vendor_id: u16, device_id: u16) ?DeviceAddr {
    for (0..256) |bus| {
        for (0..32) |dev| {
            const vd: pci.VendorDevice = @bitCast(pci.configRead32(.{
                .bus = @intCast(bus),
                .device = @intCast(dev),
                .register_offset = @intFromEnum(pci.ConfigurationOffset.vendor_device),
            }));
            if (vd.vendor_id == 0xFFFF) continue;
            if (vd.vendor_id == vendor_id and vd.device_id == device_id)
                return .{ .bus = @intCast(bus), .dev = @intCast(dev) };
        }
    }
    return null;
}

// ── Virtqueue abstraction ─────────────────────────────────────────────────────

/// A complete virtqueue: descriptor table, available ring, used ring, and the
/// device-assigned notify offset. `size` must be a power of two and match the
/// value negotiated with the device.
pub fn Virtqueue(comptime size: u16) type {
    return struct {
        /// Descriptor table; holds the buffer list exposed to the device.
        descs: [size]Desc align(16) = undefined,
        /// Driver (available) ring; driver writes head indices here.
        avail: AvailRing(size) align(2) = undefined,
        /// Device (used) ring; device writes completed chain indices here.
        used: UsedRing(size) align(4) = undefined,
        /// Per-queue notify offset returned by the device during setup.
        notify_off: u16 = 0,
        /// Queue index registered with the device.
        q_idx: u16 = 0,

        const Self = @This();

        /// Zero all DMA-visible queue memory (descriptor table, available ring,
        /// used ring). Call this before handing queue addresses to the device.
        pub fn zero(self: *Self) void {
            self.descs = std.mem.zeroes([size]Desc);
            self.avail = std.mem.zeroes(AvailRing(size));
            self.used = std.mem.zeroes(UsedRing(size));
        }

        /// Register this queue with the device via `common` and record the
        /// notify offset. Call `zero` first, then `setup`, then mark the device
        /// DRIVER_OK.
        pub fn setup(self: *Self, common: *volatile CommonCfg, q_idx: u16) void {
            self.q_idx = q_idx;
            self.notify_off = setupQueue(
                common,
                q_idx,
                size,
                @intFromPtr(&self.descs),
                @intFromPtr(&self.avail),
                @intFromPtr(&self.used),
            );
        }

        /// Copy `chain` into the descriptor table starting at index 0, enqueue
        /// the head, notify the device, and spin-poll the used ring until the
        /// device marks the chain complete. The caller must set each descriptor's
        /// `next` field to form the correct chain.
        pub fn submit(self: *Self, caps: *const Caps, chain: []const Desc) void {
            std.debug.assert(chain.len <= size);
            for (chain, 0..) |desc, i| {
                self.descs[i] = desc;
            }
            const idx = self.avail.idx;
            self.avail.ring[idx % size] = 0;
            @as(*volatile u16, &self.avail.idx).* = idx +% 1;
            kickQueue(caps, self.notify_off, self.q_idx);
            while (@as(*volatile u16, &self.used.idx).* != idx +% 1)
                std.atomic.spinLoopHint();
        }
    };
}

// ── Queue helpers ─────────────────────────────────────────────────────────────

/// Register a virtqueue with the device via CommonCfg and enable it.
/// Accepts the physical addresses of the descriptor table, available ring, and
/// used ring. Returns the queue's notify offset for computing its doorbell address.
pub fn setupQueue(
    common: *volatile CommonCfg,
    q_idx: u16,
    size: u16,
    desc_addr: usize,
    avail_addr: usize,
    used_addr: usize,
) u16 {
    common.queue_select = q_idx;
    common.queue_size = size;
    common.queue_msix_vector = 0xFFFF;
    common.queue_desc = desc_addr;
    common.queue_driver = avail_addr;
    common.queue_device = used_addr;
    const notify_off = common.queue_notify_off;
    common.queue_enable = 1;
    return notify_off;
}

/// Write the queue index to its doorbell register to notify the device.
pub inline fn kickQueue(caps: *const Caps, notify_off: u16, q_idx: u16) void {
    const addr = caps.notify_base + @as(usize, notify_off) * caps.notify_mult;
    @as(*volatile u16, @ptrFromInt(addr)).* = q_idx;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

test "DeviceStatus layout" {
    try std.testing.expectEqual(8, @bitSizeOf(DeviceStatus));
    const s = DeviceStatus{ .acknowledge = true, .driver = true };
    try std.testing.expectEqual(@as(u8, 0x03), @as(u8, @bitCast(s)));
    const s2 = DeviceStatus{ .acknowledge = true, .driver = true, .driver_ok = true, .features_ok = true };
    try std.testing.expectEqual(@as(u8, 0x0F), @as(u8, @bitCast(s2)));
}

test "DescFlags layout" {
    try std.testing.expectEqual(16, @bitSizeOf(DescFlags));
    try std.testing.expectEqual(@as(u16, 0x0001), @as(u16, @bitCast(DescFlags{ .next = true })));
    try std.testing.expectEqual(@as(u16, 0x0002), @as(u16, @bitCast(DescFlags{ .write = true })));
}

test "CommonCfg layout" {
    try std.testing.expectEqual(0, @offsetOf(CommonCfg, "device_feature_select"));
    try std.testing.expectEqual(16, @offsetOf(CommonCfg, "config_msix_vector"));
    try std.testing.expectEqual(20, @offsetOf(CommonCfg, "device_status"));
    try std.testing.expectEqual(22, @offsetOf(CommonCfg, "queue_select"));
    try std.testing.expectEqual(30, @offsetOf(CommonCfg, "queue_notify_off"));
    try std.testing.expectEqual(32, @offsetOf(CommonCfg, "queue_desc"));
    try std.testing.expectEqual(40, @offsetOf(CommonCfg, "queue_driver"));
    try std.testing.expectEqual(48, @offsetOf(CommonCfg, "queue_device"));
    try std.testing.expectEqual(56, @sizeOf(CommonCfg));
}

test "Desc size" {
    try std.testing.expectEqual(16, @sizeOf(Desc));
}

test "AvailRing size" {
    // flags(2) + idx(2) + ring(64*2=128) = 132
    try std.testing.expectEqual(132, @sizeOf(AvailRing(64)));
}

test "UsedElem size" {
    try std.testing.expectEqual(8, @sizeOf(UsedElem));
}

test "UsedRing size" {
    // flags(2) + idx(2) + ring(64*8=512) = 516
    try std.testing.expectEqual(516, @sizeOf(UsedRing(64)));
}

test "setupQueue writes fields and returns notify_off" {
    var cfg = std.mem.zeroes(CommonCfg);
    cfg.queue_notify_off = 3; // simulates the device having pre-set this
    const notify_off = setupQueue(&cfg, 2, 64, 0x1000, 0x2000, 0x3000);
    try std.testing.expectEqual(2, cfg.queue_select);
    try std.testing.expectEqual(64, cfg.queue_size);
    try std.testing.expectEqual(0xFFFF, cfg.queue_msix_vector);
    try std.testing.expectEqual(0x1000, cfg.queue_desc);
    try std.testing.expectEqual(0x2000, cfg.queue_driver);
    try std.testing.expectEqual(0x3000, cfg.queue_device);
    try std.testing.expectEqual(1, cfg.queue_enable);
    try std.testing.expectEqual(3, notify_off);
}

test "Virtqueue zero clears rings" {
    var q: Virtqueue(4) = .{};
    q.avail.idx = 42;
    q.used.idx = 7;
    q.descs[0].addr = 0xDEAD;
    q.zero();
    try std.testing.expectEqual(0, q.avail.idx);
    try std.testing.expectEqual(0, q.used.idx);
    try std.testing.expectEqual(0, q.descs[0].addr);
}

test "Virtqueue setup records q_idx and notify_off" {
    var cfg = std.mem.zeroes(CommonCfg);
    cfg.queue_notify_off = 5;
    var q: Virtqueue(4) = .{};
    q.setup(&cfg, 3);
    try std.testing.expectEqual(3, q.q_idx);
    try std.testing.expectEqual(5, q.notify_off);
    try std.testing.expectEqual(3, cfg.queue_select);
    try std.testing.expectEqual(4, cfg.queue_size);
    try std.testing.expectEqual(1, cfg.queue_enable);
}

test "kickQueue writes queue index to doorbell" {
    var doorbells = [_]u16{ 0, 0, 0, 0 };
    const caps = Caps{
        .common = undefined,
        .notify_base = @intFromPtr(&doorbells),
        .notify_mult = @sizeOf(u16),
    };
    kickQueue(&caps, 1, 5); // addr = base + 1*2 → doorbells[1]
    try std.testing.expectEqual(0, doorbells[0]);
    try std.testing.expectEqual(5, doorbells[1]);
    try std.testing.expectEqual(0, doorbells[2]);
}

test "findDevice returns null for nonexistent device" {
    const arch = @import("arch");
    try arch.freestanding();
    try std.testing.expectEqual(null, findDevice(0xDEAD, 0xBEEF));
}

test "findDevice locates i440FX host bridge" {
    const arch = @import("arch");
    try arch.freestanding();
    // QEMU i440FX machines always have an Intel i440FX host bridge.
    const addr = findDevice(0x8086, 0x1237);
    try std.testing.expect(addr != null);
}

test "walkCaps finds VirtIO sound common_cfg and notify regions" {
    const arch = @import("arch");
    try arch.freestanding();
    // VirtIO sound: vendor=0x1AF4, device=0x1059 (0x1040 + VIRTIO_ID_SOUND=25).
    const addr = findDevice(0x1AF4, 0x1059) orelse return error.SkipZigTest;
    const caps = walkCaps(addr.bus, addr.dev);
    try std.testing.expect(caps != null);
    try std.testing.expect(caps.?.notify_base != 0);
    try std.testing.expect(caps.?.notify_mult != 0);
}
