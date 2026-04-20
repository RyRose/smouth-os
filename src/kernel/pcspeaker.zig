//! PC speaker driver.
//!
//! Controls the system PC speaker via PIT channel 2 in square wave mode
//! (mode 3). The desired frequency is converted to a PIT divisor and loaded
//! into channel 2; enabling the channel 2 gate and speaker output via port
//! 0x61 drives the speaker at that frequency.
//!
//! Port map:
//!   0x42 - PIT channel 2 data (write divisor lobyte then hibyte)
//!   0x43 - PIT mode/command register (write-only)
//!   0x61 - PC speaker / NMI status port (bits 0 and 1 control output)

const std = @import("std");

const arch = @import("arch");
const time = @import("time.zig");

const ioport = arch.x86.ioport;

const log = std.log.scoped(.pcspeaker);

/// PIT oscillator frequency in Hz.
const pit_hz: u32 = 1_193_182;

/// Bitmask for the PIT channel 2 gate bit.
const ch2_gate_bit: u8 = 0x01;

/// Bitmask for the speaker output enable bit.
const speaker_enable_bit: u8 = 0x02;

/// PIT command byte: channel 2, lobyte/hibyte access, mode 3 (square wave), binary.
/// Bit layout: [7:6]=10 (ch2), [5:4]=11 (lobyte/hibyte), [3:1]=011 (mode 3), [0]=0 (binary).
const pit_ch2_squarewave_cmd: u8 = 0b10110110;

/// Play a continuous tone at `freq_hz` Hz on the PC speaker.
/// Calling with `freq_hz = 0` is equivalent to calling `stop()`.
/// Frequencies outside the PIT range [18, 1_193_182] Hz are clamped.
/// The tone continues until `stop()` is called.
pub fn play(freq_hz: u32) void {
    if (freq_hz == 0) {
        stop();
        return;
    }

    // Compute the PIT divisor: ticks per cycle at the PIT oscillator frequency.
    // Clamped to [1, 0xFFFF] to stay within the 16-bit PIT counter range.
    const divisor: u16 = @intCast(std.math.clamp(pit_hz / freq_hz, 1, 0xFFFF));

    // Program PIT channel 2 in square wave mode.
    ioport.outb(.pit_cmd, pit_ch2_squarewave_cmd);
    ioport.outb(.pit_ch2, @truncate(divisor));
    ioport.outb(.pit_ch2, @truncate(divisor >> 8));

    // Enable channel 2 gate and speaker output while preserving other bits.
    const ctrl = ioport.inb(.nmi_sc);
    ioport.outb(.nmi_sc, ctrl | ch2_gate_bit | speaker_enable_bit);

    log.debug("playing {} Hz (divisor={})", .{ freq_hz, divisor });
}

/// Stop the PC speaker by disabling the channel 2 gate and speaker output.
pub fn stop() void {
    const ctrl = ioport.inb(.nmi_sc);
    ioport.outb(.nmi_sc, ctrl & ~(ch2_gate_bit | speaker_enable_bit));
}

/// Play a tone at `freq_hz` Hz for `duration_ms` milliseconds, then stop.
/// Requires `time.calibrate()` to have been called first.
pub fn beep(freq_hz: u32, duration_ms: u64) void {
    play(freq_hz);
    time.mdelay(duration_ms);
    stop();
}

test "play enables channel 2 gate and speaker output" {
    try arch.freestanding();
    play(440);
    defer stop();
    const ctrl = ioport.inb(.nmi_sc);
    try std.testing.expect(ctrl & ch2_gate_bit != 0);
    try std.testing.expect(ctrl & speaker_enable_bit != 0);
}

test "stop clears channel 2 gate and speaker output" {
    try arch.freestanding();
    play(440);
    stop();
    const ctrl = ioport.inb(.nmi_sc);
    try std.testing.expect(ctrl & ch2_gate_bit == 0);
    try std.testing.expect(ctrl & speaker_enable_bit == 0);
}

test "play with zero frequency stops speaker" {
    try arch.freestanding();
    play(440);
    play(0);
    const ctrl = ioport.inb(.nmi_sc);
    try std.testing.expect(ctrl & ch2_gate_bit == 0);
    try std.testing.expect(ctrl & speaker_enable_bit == 0);
}

test "beep plays then stops" {
    try arch.freestanding();
    beep(440, 10);
    const ctrl = ioport.inb(.nmi_sc);
    try std.testing.expect(ctrl & ch2_gate_bit == 0);
    try std.testing.expect(ctrl & speaker_enable_bit == 0);
}
