#include <stdint.h>

// This header enables the use of -fstack-protector flag on GCC. This helps
// prevent buffer overflow errors with stack variables. See
// https://wiki.osdev.org/Stack_Smashing_Protector for more details.

extern uintptr_t __stack_chk_guard;

extern "C" void __attribute__((noreturn)) __stack_chk_fail();
