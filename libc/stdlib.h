#ifndef LIBC_STDLIB_H
#define LIBC_STDLIB_H

namespace libc {

__attribute__((__noreturn__)) void abort();

int abs(int n);

}  // namespace libc

#endif
