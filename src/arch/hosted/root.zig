//! Root module for hosted environments (i.e. OSes with a standard library).
//! These functions are no-ops in hosted environments.
//! They are only implemented in freestanding environments.

/// Install and flush the Global Descriptor Table (GDT).
pub fn installAndFlushGDT(_: u64) void {
    return;
}
