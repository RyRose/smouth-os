//! Kernel time utilities.
//!
//! Provides TSC-based busy-wait delays with nanosecond, microsecond, and
//! millisecond granularity. The TSC frequency is calibrated once at init
//! time using PIT channel 2 as a reference.

const std = @import("std");
const builtin = @import("builtin");

const arch = @import("arch");
const insn = arch.x86.insn;

const log = std.log.scoped(.time);

/// TSC frequency in Hz. Set by calibrate().
var tsc_hz: u64 = 0;

/// PIT oscillator frequency in Hz.
const pit_hz: u64 = 1_193_182;

/// PIT mode/command register (write-only).
/// Used to configure channel mode, access mode, and operating mode.
/// Reference: https://wiki.osdev.org/PIT#I/O_Ports
const pit_cmd_port: u16 = 0x43;

/// PIT channel 2 data port (read/write).
/// Used to load the initial countdown value (lobyte then hibyte).
const pit_ch2_port: u16 = 0x42;

/// PC speaker / NMI status port.
/// Bit 0: channel 2 gate (1 = enabled). Bit 1: speaker output enable.
/// Bit 5: channel 2 output state (1 = countdown reached zero).
/// Reference: https://wiki.osdev.org/PC_Speaker
const pc_speaker_port: u16 = 0x61;

/// Bitmask for the channel 2 gate bit in pc_speaker_port.
const ch2_gate_bit: u8 = 0x01;

/// Bitmask for the speaker output enable bit in pc_speaker_port.
const speaker_enable_bit: u8 = 0x02;

/// Bitmask for the channel 2 output status bit in pc_speaker_port.
/// Goes high when the PIT channel 2 countdown reaches zero.
const ch2_output_bit: u8 = 0x20;

/// PIT command byte: select channel 2, lobyte/hibyte access, mode 0
/// (interrupt on terminal count / one-shot), binary counting.
/// Bit layout: [7:6]=10 (ch2), [5:4]=11 (lobyte/hibyte), [3:1]=000 (mode 0), [0]=0 (binary).
const pit_ch2_oneshot_cmd: u8 = 0b10110000;

/// Calibrate the TSC frequency against PIT channel 2.
///
/// Uses the PIT (Programmable Interval Timer) channel 2 as a known-frequency
/// reference to measure how many TSC ticks elapse in a fixed time window
/// (~10 ms), then derives tsc_hz, tsc_per_us for use by sleep() and sleep_ns().
///
/// 1. Program PIT channel 2 in mode 0 (one-shot): it counts down from
///    `pit_ticks` at `pit_hz` (1.193182 MHz) and raises its output line
///    when the count reaches zero.
/// 2. Toggle the channel 2 gate via port 0x61 to (re)arm the countdown.
///    The speaker enable bit is explicitly cleared to avoid audible output.
/// 3. Record the TSC immediately after arming, then spin-poll the channel 2
///    output bit until it goes high (countdown complete).
/// 4. Compute tsc_hz from elapsed ticks and the known window duration.
///
/// Must be called once during kernel init before udelay(), ndelay(), or mdelay() are used.
pub fn calibrate() void {
    const pit_ticks: u16 = 11_932; // ~10 ms window at PIT frequency

    insn.outb(pit_cmd_port, pit_ch2_oneshot_cmd);
    insn.outb(pit_ch2_port, @intCast(pit_ticks & 0xFF));
    insn.outb(pit_ch2_port, @intCast(pit_ticks >> 8));

    const ctrl = insn.inb(pc_speaker_port);
    insn.outb(pc_speaker_port, ctrl & ~ch2_gate_bit); // gate low
    insn.outb(pc_speaker_port, (ctrl & ~speaker_enable_bit) | ch2_gate_bit); // gate high, speaker off

    const start = insn.rdtsc();
    while ((insn.inb(pc_speaker_port) & ch2_output_bit) == 0) {}
    const end = insn.rdtsc();

    tsc_hz = (end - start) * pit_hz / pit_ticks;
    log.debug("TSC: {} Hz", .{tsc_hz});
}

/// Busy-wait for at least `ns` nanoseconds.
/// calibrate() must be called before using this function.
///
/// Uses tsc_hz directly to avoid precision loss from integer ticks-per-microsecond
/// truncation. The computation ns * tsc_hz / 1_000_000_000 is safe from overflow
/// for durations up to ~4 seconds on a 4 GHz CPU, which is well beyond any
/// practical nanosecond delay.
pub fn ndelay(ns: u64) void {
    const start = insn.rdtsc();
    const target = start + ns * tsc_hz / 1_000_000_000;
    while (insn.rdtsc() < target) {
        std.atomic.spinLoopHint();
    }
}

/// Busy-wait for at least `us` microseconds.
/// calibrate() must be called before using this function.
pub fn udelay(us: u64) void {
    const start = insn.rdtsc();
    const target = start + us * tsc_hz / 1_000_000;
    while (insn.rdtsc() < target) {
        std.atomic.spinLoopHint();
    }
}

/// Busy-wait for at least `ms` milliseconds.
/// calibrate() must be called before using this function.
pub fn mdelay(ms: u64) void {
    udelay(ms * 1_000);
}

test "ndelay waits at least the requested duration" {
    try arch.freestanding();
    try std.testing.expect(tsc_hz > 0);

    const ns: u64 = 500_000; // 500 µs
    const before = insn.rdtsc();
    ndelay(ns);
    const after = insn.rdtsc();

    try std.testing.expect(after - before >= ns * tsc_hz / 1_000_000_000);
}

test "udelay waits at least the requested duration" {
    try arch.freestanding();
    try std.testing.expect(tsc_hz > 0);

    const us: u64 = 1_000; // 1 ms
    const before = insn.rdtsc();
    udelay(us);
    const after = insn.rdtsc();

    try std.testing.expect(after - before >= us * (tsc_hz / 1_000_000));
}

test "mdelay waits at least the requested duration" {
    try arch.freestanding();
    try std.testing.expect(tsc_hz > 0);

    const ms: u64 = 1;
    const before = insn.rdtsc();
    mdelay(ms);
    const after = insn.rdtsc();

    try std.testing.expect(after - before >= ms * 1_000 * (tsc_hz / 1_000_000));
}
