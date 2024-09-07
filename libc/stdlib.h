#ifndef LIBC_STDLIB_H
#define LIBC_STDLIB_H

namespace libc {

// Aborts the entire execution of the kernel.
__attribute__((__noreturn__)) void abort();

// Returns the absolute value of n.
int abs(int n);

}  // namespace libc

#endif
