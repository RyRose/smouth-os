#ifndef LIBC_STDIO_H
#define LIBC_STDIO_H

#include "util/status.h"

namespace libc {

util::Status putchar(int);
util::StatusOr<int> printf(const char*, ...);
util::StatusOr<int> puts(const char*);

}  // namespace libc

#endif  // LIBC_STDIO_H
