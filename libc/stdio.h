#ifndef LIBC_STDIO_H
#define LIBC_STDIO_H

#include <stdint.h>

#include "libc/stdio/internal/printer.h"
#include "libc/string.h"
#include "util/status.h"

namespace libc {

template <typename T, typename... Args>
util::StatusOr<int> printf(const char* format, const T& value,
                           const Args&... args) {
  Printer p;
  return p.Printf(format, value, args...);
}

util::StatusOr<int> printf(const char* format);

template <typename T, typename... Args>
util::StatusOr<int> sprintf(char* buffer, const char* format, const T& value,
                            const Args&... args) {
  Printer p(PrintType::BUFFER, buffer);
  return p.Printf(format, value, args...);
}

util::StatusOr<int> sprintf(char* buffer, const char* format);

template <typename T, typename... Args>
util::StatusOr<int> snprintf(char* buffer, size_t bufsz, const char* format,
                             const T& value, const Args&... args) {
  Printer p(PrintType::BUFFER_MAXIMUM, buffer, bufsz);
  return p.Printf(format, value, args...);
}

util::StatusOr<int> snprintf(char* buffer, size_t bufsz, const char* format);

template <typename T, typename... Args>
util::StatusOr<int> asprintf(char** strp, const char* format, const T& value,
                             const Args&... args) {
  Printer dry_runner(PrintType::DRY_RUN);
  ASSIGN_OR_RETURN(const int len, dry_runner.Printf(format, value, args...));
  *strp = new char[len];
  Printer p(PrintType::BUFFER, *strp);
  return p.Printf(format, value, args...);
}

util::StatusOr<int> asprintf(char** strp, const char* format);

util::StatusOr<int> puts(const char*);

util::Status putchar(int);

}  // namespace libc

#endif  // LIBC_STDIO_H
