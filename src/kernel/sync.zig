//! Synchronization primitives for kernel development.
//!

const std = @import("std");

/// A simple spinlock implementation using an atomic flag.
///
/// TODO: Improve implementation if performance is an issue.
///       Current implementation uses a busy-wait loop with a pause instruction,
///       sequentially consistent memory ordering, and strong compare-and-exchange.
///
pub fn SpinLock(comptime T: type) type {
    return struct {
        /// The atomic flag indicating lock status.
        /// true = locked, false = unlocked
        flag: std.atomic.Value(bool),

        /// The protected value.
        /// Make sure to only access this value while holding the lock.
        value: T,

        const Self = @This();

        /// Initializes the spinlock with the given value.
        pub fn init(value: T) Self {
            return .{
                .flag = std.atomic.Value(bool).init(false),
                .value = value,
            };
        }

        /// Acquires the lock, spinning until it is available.
        pub fn lock(self: *Self) void {
            while (self.flag.cmpxchgStrong(false, true, .seq_cst, .seq_cst) != null) {
                std.atomic.spinLoopHint();
            }
        }

        /// Tries to acquire the lock for a specified number of iterations.
        /// Returns true if the lock was acquired, false otherwise.
        pub fn tryLock(self: *Self, iterations: u64) bool {
            var i: usize = 0;
            while (self.flag.cmpxchgStrong(false, true, .seq_cst, .seq_cst) != null and i < iterations) : (i += 1) {
                std.atomic.spinLoopHint();
            }
            return i < iterations;
        }

        /// Releases the lock.
        /// Make sure to only call this when the lock is held.
        pub fn unlock(self: *Self) void {
            self.flag.store(false, .seq_cst);
        }
    };
}

test "SpinLock basic functionality" {
    var lock = SpinLock(u32).init(0);
    lock.lock();
    lock.value = 42;
    lock.unlock();
    lock.lock();
    try std.testing.expectEqual(42, lock.value);
    lock.unlock();
}

test "SpinLock tryLock functionality" {
    var lock = SpinLock(u32).init(0);
    try std.testing.expect(lock.tryLock(1000));
    try std.testing.expect(!lock.tryLock(1000));
    lock.unlock();
    try std.testing.expect(lock.tryLock(1000));
}
