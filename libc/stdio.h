#ifndef LIBC_STDIO_H
#define LIBC_STDIO_H

#include <stdint.h>

#include "cxx/new.h"
#include "libc/stdio/internal/printer.h"
#include "libc/string.h"
#include "util/status.h"

namespace libc {

// printf is a minimal version of the standard C printf function. Formatters
// supported:
//   * %v - auto-deduce the type from the argument. Uses the following for each:
//     * char* - %s
//     * char - %c
//     * number - %d %i %u
//     * pointer - %p
//   * %s - char*
//   * %q - quoted char*
//   * %d %i %u - base 10 number (signed or unsigned)
//   * %x - base 16 number
//   * %X - base 16 number (capitalized)
//   * %o - octal
//   * %p - pointer
//   * %c - char
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
  *strp = new (std::nothrow) char[len];
  RET_CHECK(*strp != nullptr);
  Printer p(PrintType::BUFFER, *strp);
  return p.Printf(format, value, args...);
}

util::StatusOr<int> asprintf(char** strp, const char* format);

util::StatusOr<int> puts(const char*);

util::Status putchar(int);

}  // namespace libc

#endif  // LIBC_STDIO_H
