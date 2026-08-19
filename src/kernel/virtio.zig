//! Architecture-independent VirtIO queue and feature-negotiation primitives.
//!
//! Architecture modules provide the transport-specific register access for
//! PCI or MMIO, while device drivers use the types in this module.

const std = @import("std");

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

/// Selects one 32-bit bank in the 64-bit VirtIO feature bitset.
pub const FeatureBank = enum(u32) {
    /// Feature bits 0 through 31.
    low = 0,
    /// Feature bits 32 through 63.
    high = 1,
};

/// VIRTIO_F_VERSION_1, required by modern VirtIO transports.
pub const feature_version_1: u32 = 1;

/// A single VirtIO descriptor table entry (§2.7.5).
pub const Desc = extern struct {
    /// Physical address of the buffer.
    addr: u64,
    /// Length of the buffer in bytes.
    len: u32,
    /// Descriptor flags.
    flags: DescFlags,
    /// Index of the next descriptor when `flags.next` is set.
    next: u16,
};

/// VirtIO descriptor flags (§2.7.5).
pub const DescFlags = packed struct(u16) {
    /// The descriptor chain continues at `next`.
    next: bool = false,
    /// The device may write this buffer.
    write: bool = false,
    _reserved: u14 = 0,
};

/// Returns the available-ring layout for `size` descriptor heads.
pub fn AvailRing(comptime size: u16) type {
    return extern struct {
        /// Available-ring flags.
        flags: u16,
        /// Next available-ring slot written by the driver.
        idx: u16,
        /// Descriptor-chain head indices.
        ring: [size]u16,
    };
}

/// A device-written used-ring entry.
pub const UsedElem = extern struct {
    /// Descriptor-chain head consumed by the device.
    id: u32,
    /// Bytes written to writable descriptors.
    len: u32,
};

/// Returns the used-ring layout for `size` completed descriptor chains.
pub fn UsedRing(comptime size: u16) type {
    return extern struct {
        /// Used-ring flags.
        flags: u16,
        /// Next used-ring slot written by the device.
        idx: u16,
        /// Completed descriptor chains.
        ring: [size]UsedElem,
    };
}

/// Returns a statically allocated VirtIO queue with `size` descriptors.
///
/// The transport passed to `setup` and `submit` must provide `setupQueue` and
/// `notifyQueue` methods. Its address space must identity-map DMA memory,
/// which remains true through this kernel's early identity map.
pub fn Virtqueue(comptime size: u16) type {
    return struct {
        /// Descriptor table shared with the device.
        descs: [size]Desc align(16) = undefined,
        /// Driver-owned available ring shared with the device.
        avail: AvailRing(size) align(2) = undefined,
        /// Device-owned used ring shared with the driver.
        used: UsedRing(size) align(4) = undefined,
        /// Queue index registered with the device.
        idx: u16 = 0,

        const Self = @This();

        /// Clears all DMA-visible queue storage.
        fn zero(self: *Self) void {
            self.descs = std.mem.zeroes([size]Desc);
            self.avail = std.mem.zeroes(AvailRing(size));
            self.used = std.mem.zeroes(UsedRing(size));
        }

        /// Registers this queue with `transport` and enables it.
        pub fn setup(self: *Self, transport: anytype, idx: u16) !void {
            self.zero();
            self.idx = idx;
            try transport.setupQueue(
                idx,
                size,
                @intFromPtr(&self.descs),
                @intFromPtr(&self.avail),
                @intFromPtr(&self.used),
            );
        }

        /// Submits `chain` and polls until the device completes it.
        pub fn submit(self: *Self, transport: anytype, chain: []const Desc) void {
            std.debug.assert(chain.len > 0 and chain.len <= size);
            for (chain, 0..) |desc, i| self.descs[i] = desc;

            const avail_idx = self.avail.idx;
            self.avail.ring[avail_idx % size] = 0;
            transport.memoryBarrier();
            @as(*volatile u16, &self.avail.idx).* = avail_idx +% 1;
            transport.notifyQueue(self.idx);

            while (@as(*volatile u16, &self.used.idx).* != avail_idx +% 1)
                std.atomic.spinLoopHint();
            transport.memoryBarrier();
        }
    };
}

test "DeviceStatus layout" {
    try std.testing.expectEqual(8, @bitSizeOf(DeviceStatus));
    const status = DeviceStatus{ .acknowledge = true, .driver = true };
    try std.testing.expectEqual(@as(u8, 0x03), @as(u8, @bitCast(status)));
    const ready = DeviceStatus{
        .acknowledge = true,
        .driver = true,
        .features_ok = true,
        .driver_ok = true,
    };
    try std.testing.expectEqual(@as(u8, 0x0F), @as(u8, @bitCast(ready)));
}

test "DescFlags layout" {
    try std.testing.expectEqual(16, @bitSizeOf(DescFlags));
    try std.testing.expectEqual(@as(u16, 1), @as(u16, @bitCast(DescFlags{ .next = true })));
    try std.testing.expectEqual(@as(u16, 2), @as(u16, @bitCast(DescFlags{ .write = true })));
}

test "Virtqueue layout" {
    try std.testing.expectEqual(16, @sizeOf(Desc));
    try std.testing.expectEqual(132, @sizeOf(AvailRing(64)));
    try std.testing.expectEqual(8, @sizeOf(UsedElem));
    try std.testing.expectEqual(516, @sizeOf(UsedRing(64)));
}

test "Virtqueue setup clears memory and registers queue" {
    const FakeTransport = struct {
        idx: u16 = 0,
        size: u16 = 0,
        desc_addr: usize = 0,
        avail_addr: usize = 0,
        used_addr: usize = 0,

        fn setupQueue(
            self: *@This(),
            idx: u16,
            queue_size: u16,
            desc_addr: usize,
            avail_addr: usize,
            used_addr: usize,
        ) !void {
            self.idx = idx;
            self.size = queue_size;
            self.desc_addr = desc_addr;
            self.avail_addr = avail_addr;
            self.used_addr = used_addr;
        }

        fn memoryBarrier(_: *@This()) void {}
    };

    var transport = FakeTransport{};
    var queue: Virtqueue(4) = .{};
    queue.avail.idx = 42;
    queue.used.idx = 7;
    queue.descs[0].addr = 0xDEAD;
    try queue.setup(&transport, 3);

    try std.testing.expectEqual(@as(u16, 3), queue.idx);
    try std.testing.expectEqual(@as(u16, 0), queue.avail.idx);
    try std.testing.expectEqual(@as(u16, 0), queue.used.idx);
    try std.testing.expectEqual(@as(u64, 0), queue.descs[0].addr);
    try std.testing.expectEqual(@as(u16, 3), transport.idx);
    try std.testing.expectEqual(@as(u16, 4), transport.size);
    try std.testing.expect(transport.desc_addr != 0);
    try std.testing.expect(transport.avail_addr != 0);
    try std.testing.expect(transport.used_addr != 0);
}
