const root = @import("root");
const std = @import("std");

comptime {
    const actual = @TypeOf(root.kmain);
    const expected = fn () callconv(.c) noreturn;
    if (actual != expected) {
        @compileError(std.fmt.comptimePrint(
            "kmain must have type `{}` but found `{}`",
            .{ expected, actual },
        ));
    }
}

const multibootHeaderMagic = 0x1BADB002;
const multibootFlagAlign = 1 << 0;
const multibootFlagMeminfo = 1 << 1;
const multibootFlags = multibootFlagAlign | multibootFlagMeminfo;

/// https://www.gnu.org/software/grub/manual/multiboot/multiboot.html
const MultibootHeader = packed struct {
    magic: u32 = multibootHeaderMagic,
    flags: u32 = multibootFlags,
    checksum: u32,
    // Required padding to allow for exporting according to ABI standards.
    // Fails with this error otherwise:
    // note: only extern structs and ABI sized packed structs are extern
    // compatible
    padding: u32 = 0,
};

export var multiboot: MultibootHeader align(4) linksection(".multiboot") = .{
    // Here we are adding magic and flags and ~ to get 1's complement and by
    // adding 1 we get 2's complement
    .checksum = ~@as(u32, (multibootHeaderMagic + multibootFlags)) + 1,
};

// Reserve stack for initial thread.
var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

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
          [kmain] "X" (&root.kmain),
    );
}
