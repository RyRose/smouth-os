//! x86 I/O port address constants and I/O helper functions.
//!
//! All port addresses are 16-bit values suitable for use with the `in`/`out`
//! family of instructions. Each field is documented with the device it belongs
//! to, its access direction, and a short description of its function.
//!
//! The helper functions (inb, outb, inw, outw, inl, outl) accept Port enum
//! values directly, eliminating raw address literals at call sites.

const insn = @import("insn.zig");

/// x86 I/O port addresses.
pub const Port = enum(u16) {
    // ── PIT — Programmable Interval Timer (Intel 8253/8254) ──────────────────
    //   The PIT has three independent channels; all share the same command port.
    //   The oscillator runs at 1_193_182 Hz; writing a 16-bit divisor to a
    //   channel data port sets its output frequency to pit_hz / divisor.

    /// PIT channel 0 data port (read/write).
    /// Channel 0 is wired to IRQ 0 and traditionally drives the system clock.
    pit_ch0 = 0x40,

    /// PIT channel 1 data port (read/write).
    /// Historically used for DRAM refresh; unused on modern hardware.
    pit_ch1 = 0x41,

    /// PIT channel 2 data port (read/write).
    /// Gated to the PC speaker; used by the PC speaker and TSC calibration.
    /// Write the divisor low byte first, then the high byte.
    pit_ch2 = 0x42,

    /// PIT mode/command register (write-only).
    /// Selects channel, access mode, operating mode, and binary/BCD counting.
    pit_cmd = 0x43,

    // ── NMI status / PC speaker control ─────────────────────────────────────
    //   Port 0x61 is a read/write register on the 8255 PPI (or its successor).
    //   Bits 0 and 1 are writable; bits 4 and 5 change asynchronously.

    /// NMI status and PC speaker control register (read/write).
    ///
    /// Bit layout:
    ///   [0] PIT channel 2 gate — set to enable channel 2 countdown.
    ///   [1] Speaker output enable — set to connect PIT ch2 output to speaker.
    ///   [4] DRAM refresh toggle — toggles at ~15 µs; do not rely on its value.
    ///   [5] PIT channel 2 output state — reflects ch2 output; toggles in mode 3.
    nmi_sc = 0x61,

    // ── COM1 serial port (16550A UART) ───────────────────────────────────────
    //   The register at each offset depends on the DLAB bit in the line control
    //   register (com1_lcr). When DLAB=0: data/IER. When DLAB=1: baud divisor.

    /// COM1 data register (DLAB=0, read/write) / divisor latch low byte (DLAB=1, write).
    com1_data = 0x3F8,

    /// COM1 interrupt enable register (DLAB=0, read/write) / divisor latch high byte (DLAB=1, write).
    com1_ier = 0x3F9,

    /// COM1 interrupt ID register (read) / FIFO control register (write).
    com1_iir_fcr = 0x3FA,

    /// COM1 line control register (read/write).
    /// Bit 7 is the divisor-latch access bit (DLAB); set to program the baud rate.
    com1_lcr = 0x3FB,

    /// COM1 modem control register (read/write).
    com1_mcr = 0x3FC,

    /// COM1 line status register (read-only).
    /// Bit 5 (transmitter holding register empty) indicates the UART is ready to accept a new byte.
    com1_lsr = 0x3FD,

    /// COM1 modem status register (read-only).
    com1_msr = 0x3FE,

    /// COM1 scratch register (read/write). Not used in normal operation.
    com1_scr = 0x3FF,

    // ── PCI configuration space ──────────────────────────────────────────────
    //   PCI configuration registers are accessed via a two-port mechanism:
    //   write the target address to pci_config_addr, then read/write the data
    //   via pci_config_data.

    /// PCI configuration address port (write-only, 32-bit).
    /// Format: [31]=enable, [30:24]=reserved, [23:16]=bus, [15:11]=device,
    ///         [10:8]=function, [7:2]=register, [1:0]=0.
    pci_config_addr = 0xCF8,

    /// PCI configuration data port (read/write, 32-bit).
    /// Read or write after setting pci_config_addr.
    pci_config_data = 0xCFC,

    // ── QEMU virtual hardware ─────────────────────────────────────────────────

    /// QEMU ISA debug exit device port (write-only).
    /// Writing any value triggers QEMU to exit with code `(value << 1) | 1`.
    /// Used to signal test failure or a fatal kernel error.
    qemu_debug_exit = 0xF4,

    /// QEMU ACPI PM1a control block (write-only, 16-bit).
    /// Writing 0x2000 sets the SLP_EN bit and triggers an ACPI S5 (power-off)
    /// shutdown, which causes QEMU to exit cleanly.
    /// Used after successful kernel execution.
    qemu_acpi_shutdown = 0x604,

    /// Returns the numeric port address.
    pub fn addr(self: Port) u16 {
        return @intFromEnum(self);
    }
};

/// Read a byte from the given port.
pub fn inb(port: Port) u8 {
    return insn.inb(port.addr());
}

/// Write a byte to the given port.
pub fn outb(port: Port, value: u8) void {
    insn.outb(port.addr(), value);
}

/// Read a 16-bit word from the given port.
pub fn inw(port: Port) u16 {
    return insn.inw(port.addr());
}

/// Write a 16-bit word to the given port.
pub fn outw(port: Port, value: u16) void {
    insn.outw(port.addr(), value);
}

/// Read a 32-bit doubleword from the given port.
pub fn inl(port: Port) u32 {
    return insn.inl(port.addr());
}

/// Write a 32-bit doubleword to the given port.
pub fn outl(port: Port, value: u32) void {
    insn.outl(port.addr(), value);
}
