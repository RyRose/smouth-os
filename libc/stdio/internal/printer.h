#ifndef LIBC_STDIO_PRINTER_H
#define LIBC_STDIO_PRINTER_H

#include "libc/kernel.h"
#include "libc/string.h"
#include "stdint.h"
#include "util/status.h"

namespace libc {

class Printer {
 public:
  template <typename T, typename... Args>
  util::StatusOr<int> Printf(const char* format, const T& value,
                             const Args&... args) {
    int i = 0;
    while (*format) {
      if (*format != '%' || *(++format) == '%') {
        RETURN_IF_ERROR(PutChar(*format));
        i++;
        format++;
        continue;
      }
      ASSIGN_OR_RETURN(const auto& print_length, Print(value, *format));
      ASSIGN_OR_RETURN(const auto& printf_length, Printf(++format, args...));
      return i + print_length + printf_length;
    }
    return util::Status(util::ErrorCode::INVALID_ARGUMENT,
                        "too many printf formatters specified.");
  }

  util::StatusOr<int> Printf(const char* format) { return Print(format, 's'); }

 private:
  util::Status PutChar(int ic) {
    RET_CHECK(kernel_put != nullptr, "kernel_put API null.");
    return kernel_put(static_cast<char>(ic));
  }

  template <class V>
  char ConvertToChar(V number, bool is_uppercase) {
    if (number < 10) {
      return '0' + number;
    }
    return (is_uppercase ? 'A' : 'a') + (number % 10);
  }

  template <class V>
  util::StatusOr<int> PrintNumber(const V& number, const V& base,
                                  const bool& uppercase) {
    int i = 0;
    V temp = number > 0 ? number : -number;
    char converted[100];
    do {
      converted[i] = ConvertToChar<V>(temp % base, uppercase);
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
      RETURN_IF_ERROR(PutChar(converted[i]));
    }
    return ret;
  }

  template <typename T>
  util::StatusOr<int> Print(T data, char c) {
    ASSIGN_OR_RETURN(const auto* ptr, strchr("xXdivuo", c));
    RET_CHECK(ptr != nullptr);
    T base;
    switch (c) {
      case 'x':
      case 'X':
        base = 16;
        break;
      case 'd':
      case 'i':
      case 'u':
      case 'v':
        base = 10;
        break;
      case 'o':
        base = 8;
        break;
      default:
        return util::Status("unhandled integer base conversion");
    }
    return PrintNumber<T>(data, base, c == 'X');
  }

  template <typename T>
  util::StatusOr<int> Print(T* data, char c) {
    RET_CHECK(c == 'p');
    return PrintNumber<uintptr_t>(reinterpret_cast<uintptr_t>(data), 16, true);
  }

  util::StatusOr<int> Print(char data, char c) {
    ASSIGN_OR_RETURN(const auto* ptr, strchr("%cv", c));
    RET_CHECK(ptr != nullptr);
    RETURN_IF_ERROR(PutChar(data));
    return 1;
  }

  util::StatusOr<int> Print(const char* data, char c) {
    ASSIGN_OR_RETURN(const auto* ptr, strchr("sqv", c));
    RET_CHECK(ptr != nullptr);
    if (c == 'q') {
      RETURN_IF_ERROR(PutChar('"'));
    }
    int i = 0;
    for (; data[i]; i++) {
      if (c == 'q' && data[i] == '"') {
        RETURN_IF_ERROR(PutChar('\\'));
        i += 1;
      }
      RETURN_IF_ERROR(PutChar(data[i]));
    }
    if (c == 'q') {
      RETURN_IF_ERROR(PutChar('"'));
      i += 1;
    }
    return i;
  }
};

}  // namespace libc

#endif  // LIBC_STDIO_PRINTER_H
