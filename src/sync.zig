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
            return Self{
                .flag = std.atomic.Value(bool).init(false),
                .value = value,
            };
        }

        /// Acquires the lock, spinning until it is available.
        pub fn lock(self: *Self) void {
            while (true) {
                if (!self.flag.load(.seq_cst)) {
                    if (self.flag.cmpxchgStrong(false, true, .seq_cst, .seq_cst) == null) {
                        break;
                    }
                }
                asm volatile ("pause");
            }
        }

        /// Tries to acquire the lock for a specified number of iterations.
        /// Returns true if the lock was acquired, false otherwise.
        pub fn tryLock(self: *Self, iterations: usize) bool {
            var i: usize = 0;
            while (i < iterations) : (i += 1) {
                if (!self.flag.load(.seq_cst)) {
                    if (self.flag.cmpxchgStrong(false, true, .seq_cst, .seq_cst) == null) {
                        return true;
                    }
                }
                asm volatile ("pause");
            }
            return false;
        }

        /// Releases the lock.
        /// Make sure to only call this when the lock is held.
        pub fn unlock(self: *Self) void {
            self.flag.store(false, .seq_cst);
        }
    };
}
