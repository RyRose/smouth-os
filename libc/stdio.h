#ifndef LIBC_STDIO_H
#define LIBC_STDIO_H

#include <stdint.h>

#include "libc/string.h"

#include "util/status.h"

namespace libc {

template <typename T, typename... Args>
util::StatusOr<int> printf(const char*, const T&, const Args&...);

util::Status putchar(int);
util::StatusOr<int> puts(const char*);

}  // namespace libc

namespace libc {
namespace {

template <class V>
char convert_to_char(V number, bool is_uppercase) {
  if (number < 10) {
    return '0' + number;
  }
  return (is_uppercase ? 'A' : 'a') + (number % 10);
}

template <class V>
util::StatusOr<int> print_number(const V& number, const V& base,
                                 const bool& uppercase) {
  int i = 0;
  V temp = number > 0 ? number : -number;
  char converted[100];
  do {
    converted[i] = convert_to_char<V>(temp % base, uppercase);
    temp /= base;
    i++;
  } while (temp && i < 100);
  RET_CHECK(temp == 0);

  if (number < 0) {
    converted[i] = '-';
    i++;
  }

  int ret = i;
  for (i--; i >= 0; i--) {
    RETURN_IF_ERROR(putchar(converted[i]));
  }
  return ret;
}

template <typename T>
util::StatusOr<int> print(T data, char c) {
  RET_CHECK(strchr("xXdiuo", c));
  T base;
  switch (c) {
    case 'x':
    case 'X':
      base = 16;
      break;
    case 'd':
    case 'i':
    case 'u':
      base = 10;
      break;
    case 'o':
      base = 8;
      break;
    default:
      return util::Status("unhandled integer base conversion");
  }
  return print_number<T>(data, base, c == 'X');
}

template <typename T>
util::StatusOr<int> print(T* data, char c) {
  RET_CHECK(c == 'p');
  return print_number<uintptr_t>(reinterpret_cast<uintptr_t>(data), 16, true);
}

template <>
util::StatusOr<int> print(char data, char c) {
  RET_CHECK(strchr("%c", c));
  RETURN_IF_ERROR(putchar(data));
  return 1;
}

template <>
util::StatusOr<int> print(const char* data, char c) {
  RET_CHECK(c == 's');
  int i = 0;
  for (; data[i]; i++) {
    RETURN_IF_ERROR(putchar(data[i]));
  }
  return i;
}

util::StatusOr<int> printf(const char* format) { return print(format, 's'); }

}  // namespace

template <typename T, typename... Args>
util::StatusOr<int> printf(const char* format, const T& value,
                           const Args&... args) {
  int i = 0;
  while (*format) {
    if (*format != '%' || *(++format) == '%') {
      RETURN_IF_ERROR(putchar(*format));
      i++;
      format++;
      continue;
    }
    ASSIGN_OR_RETURN(const auto& print_length, print(value, *format));
    ASSIGN_OR_RETURN(const auto& printf_length, printf(++format, args...));
    return i + print_length + printf_length;
  }
  return util::Status(util::ErrorCode::INVALID_ARGUMENT,
                      "too many printf formatters specified.");
}

}  // namespace libc

#endif  // LIBC_STDIO_H
