//! I/O port read/write functions for x86 architecture.

/// Read a byte from the specified I/O port.
pub fn inb(port: u16) u8 {
    var value: u8 = 0;
    asm volatile ("inb %[port], %[value]"
        : [value] "={al}" (value),
        : [port] "{dx}" (port),
        : .{ .memory = true });
    return value;
}

/// Write a byte to an I/O port.
pub fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "{dx}" (port),
        : .{ .memory = true });
}

/// Read a 16-bit value from the specified I/O port.
pub fn inw(port: u16) u16 {
    var value: u8 = 0;
    asm volatile ("inb %[port], %[value]"
        : [value] "={ax}" (value),
        : [port] "{dx}" (port),
        : .{ .memory = true });
    return value;
}

/// Write a 16-bit value to the specified I/O port.
pub fn outw(port: u16, value: u16) void {
    asm volatile ("outw %[value], %[port]"
        :
        : [value] "{ax}" (value),
          [port] "{dx}" (port),
        : .{ .memory = true });
}

/// Read a 32-bit value from the specified I/O port.
pub fn inl(port: u16) u32 {
    var value: u32 = 0;
    asm volatile ("inl %[port], %[value]"
        : [value] "={eax}" (value),
        : [port] "{dx}" (port),
        : .{ .memory = true });
    return value;
}

/// Write a 32-bit value to the specified I/O port.
pub fn outl(port: u16, value: u32) void {
    asm volatile ("outl %[value], %[port]"
        :
        : [value] "{eax}" (value),
          [port] "{dx}" (port),
        : .{ .memory = true });
}
