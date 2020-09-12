#ifndef LIBC_STDIO_H
#define LIBC_STDIO_H

#include <stdint.h>

#include "libc/stdio/internal/printer.h"
#include "libc/string.h"
#include "util/status.h"

namespace libc {

util::Status putchar(int);

template <typename T, typename... Args>
util::StatusOr<int> printf(const char* format, const T& value,
                           const Args&... args) {
  Printer p;
  return p.Printf(format, value, args...);
}

util::StatusOr<int> puts(const char*);

}  // namespace libc

#endif  // LIBC_STDIO_H
