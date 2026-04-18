//! This file contains the entry point for the kernel when booting in test
//! mode. It sets up a stack, initializes the kernel, and runs all tests
//! defined in the `builtin` module. The results of the tests are printed to
//! the serial port.
//!
//! This file intentionally does not take a direct dependency on any arch files
//! to simplify build configuration.
//!

const builtin = @import("builtin");
const std = @import("std");

const kernel = @import("kernel");

const log = std.log.scoped(.TESTBOOT);

const multiboot_header_magic = 0x1BADB002;
const multiboot_flag_align = 1 << 0;
const multiboot_flag_meminfo = 1 << 1;
const multiboot_flags = multiboot_flag_align | multiboot_flag_meminfo;

/// https://www.gnu.org/software/grub/manual/multiboot/multiboot.html
const MultibootHeader = packed struct(u128) {
    magic: u32 = multiboot_header_magic,
    flags: u32 = multiboot_flags,
    checksum: u32,
    // Required padding to allow for exporting according to ABI standards.
    // Fails with this error otherwise:
    // note: only extern structs and ABI sized packed structs are extern
    // compatible
    padding: u32 = 0,
};

export var multiboot_header: MultibootHeader align(4) linksection(".multiboot") = .{
    // Here we are adding magic and flags and ~ to get 1's complement and by
    // adding 1 we get 2's complement
    .checksum = ~@as(u32, (multiboot_header_magic + multiboot_flags)) + 1,
};

// Reserve 16 KiB stack for initial thread.
var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

fn main() anyerror!void {
    try kernel.init.init();

    const tty = kernel.serial.tty;
    try tty.setColor(.dim);
    try tty.writer.writeAll("start\n");
    try tty.writer.print("└─ {d} tests\n", .{builtin.test_functions.len});
    try tty.setColor(.reset);

    var failed: usize = 0;
    var skipped: usize = 0;
    for (builtin.test_functions) |t| {
        kernel.log.test_name = t.name;
        t.func() catch |err| {
            if (err == error.SkipZigTest) {
                skipped += 1;
                continue;
            }
            try tty.setColor(.bright_red);
            try tty.writer.writeAll("error:");
            try tty.setColor(.reset);
            try tty.writer.writeAll(" '");
            try tty.writer.writeAll(t.name);
            try tty.writer.writeAll("' failed: ");
            try tty.writer.writeAll(kernel.iotest.writer.buffer);
            kernel.iotest.writer.end = 0;
            try tty.writer.writeAll("\n");
            if (@errorReturnTrace()) |trace| {
                std.debug.writeErrorReturnTrace(trace, tty) catch |err2| {
                    log.warn("Failed to write test error trace: {}.", .{err2});
                };
            }
            failed += 1;
        };
    }
    try tty.setColor(.dim);
    try tty.writer.writeAll("end\n");
    try tty.writer.print("└─ {d}/{d} passed", .{
        builtin.test_functions.len - failed - skipped,
        builtin.test_functions.len,
    });

    if (failed > 0) {
        try tty.writer.writeAll(", ");
        try tty.setColor(.red);
        try tty.writer.print("{d} failed", .{failed});
        try tty.setColor(.reset);
    }

    if (skipped > 0) {
        try tty.writer.writeAll(", ");
        try tty.setColor(.yellow);
        try tty.writer.print("{d} skipped", .{skipped});
        try tty.setColor(.reset);
    }
    try tty.setColor(.reset);
    kernel.serial.write("\n");
    if (failed > 0) {
        return error.TestFailed;
    }
}

export fn kmain() noreturn {
    main() catch |err| {
        if (err != error.TestFailed) {
            log.err("Kernel main failed: {}", .{err});
            if (@errorReturnTrace()) |trace| {
                std.debug.writeErrorReturnTrace(trace, kernel.serial.tty) catch |err2| {
                    log.warn("Failed to write error trace: {}.", .{err2});
                };
            }
        }
        // Use QEMU shutdown port to halt the system with a non-zero exit code on test failure.
        kernel.arch.x86.insn.outw(0xF4, 0);
    };

    // Halt the CPU using QEMU shutdown port with a zero exit code
    // or an infinite loop.
    kernel.arch.x86.insn.outw(0x604, 0x2000);
    while (true) {}
}

// We specify that this function is "naked" to let the compiler know
// not to generate a standard function prologue and epilogue, since
// we don't have a stack yet.
export fn _start() callconv(.naked) noreturn {
    // We use inline assembly to set up the stack before jumping to
    // our kernel entry point.
    asm volatile (
        \\ movl %[stack_top], %esp
        \\ movl %esp, %ebp
        \\ call %[kmain:P]
        :
        // The stack grows downwards on x86, so we need to point ESP register
        // to one element past the end of `stack_bytes`.
        //
        // Finally, we pass the whole expression as an input operand with the
        // "immediate" constraint to force the compiler to encode this as an
        // absolute address. This prevents the compiler from doing unnecessary
        // extra steps to compute the address at runtime (especially in Debug
        // mode),
        // which could possibly clobber registers that are specified by
        // multiboot
        // to hold special values (e.g. EAX).
        : [stack_top] "i" (stack_bytes[stack_bytes.len..].ptr),
          [kmain] "X" (&kmain),
    );
}
