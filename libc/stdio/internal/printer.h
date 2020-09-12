#ifndef LIBC_STDIO_PRINTER_H
#define LIBC_STDIO_PRINTER_H

#include "libc/kernel.h"
#include "libc/string.h"
#include "stdint.h"
#include "util/status.h"

namespace libc {

enum class PrintType {
  KERNEL,
  BUFFER,
  BUFFER_MAXIMUM,
  DRY_RUN,
};

class Printer {
 public:
  Printer() : Printer(PrintType::KERNEL) {}
  explicit Printer(PrintType type) : Printer(type, nullptr) {}

  Printer(PrintType type, char* buffer) : Printer(type, buffer, 0) {}

  Printer(PrintType type, char* buffer, size_t maximum)
      : type_(type), buffer_(buffer), maximum_(maximum), index_(0) {}

  template <typename T, typename... Args>
  util::StatusOr<int> Printf(const char* format, const T& value,
                             const Args&... args) {
    ASSIGN_OR_RETURN(const int length, PrintfInternal(format, value, args...));
    switch (type_) {
      case PrintType::BUFFER_MAXIMUM:
        if (length >= maximum_) {
          buffer_[index_ - 1] = '\0';
          return length;
        }
        [[fallthrough]];
      case PrintType::BUFFER:
        buffer_[index_] = '\0';
        return length + 1;
      case PrintType::KERNEL:
        [[fallthrough]];
      case PrintType::DRY_RUN:
        [[fallthrough]];
      default:
        return length;
    }
  }

  util::StatusOr<int> Printf(const char* format) {
    return Printf("%s", format);
  }

 private:
  PrintType type_;
  char* buffer_;
  int maximum_;
  int index_;

  template <typename T, typename... Args>
  util::StatusOr<int> PrintfInternal(const char* format, const T& value,
                                     const Args&... args) {
    int i = 0;
    while (*format) {
      if (*format != '%' || *(++format) == '%') {
        ASSIGN_OR_RETURN(const int temp, PutChar(*format));
        i += temp;
        format++;
        continue;
      }
      ASSIGN_OR_RETURN(const auto& print_length, Print(value, *format));
      ASSIGN_OR_RETURN(const auto& printf_length,
                       PrintfInternal(++format, args...));
      return i + print_length + printf_length;
    }
    return util::Status(util::ErrorCode::INVALID_ARGUMENT,
                        "too many printf formatters specified.");
  }

  util::StatusOr<int> PrintfInternal(const char* format) {
    return Print(format, 's');
  }

  util::StatusOr<int> PutChar(char ic) {
    switch (type_) {
      case PrintType::KERNEL:
        RET_CHECK(kernel_put != nullptr, "kernel_put API null.");
        RETURN_IF_ERROR(kernel_put(ic));
        return 1;
      case PrintType::BUFFER:
        buffer_[index_] = ic;
        index_++;
        return 1;
      case PrintType::BUFFER_MAXIMUM:
        if (index_ >= maximum_) {
          return 0;
        }
        buffer_[index_] = ic;
        index_++;
        return 1;
      case PrintType::DRY_RUN:
        return 1;
      default:
        return util::Status(util::ErrorCode::INVALID_ARGUMENT,
                            "invalid print type provided");
    }
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

    int ret = 0;
    for (i--; i >= 0; i--) {
      ASSIGN_OR_RETURN(const int result, PutChar(converted[i]));
      ret += result;
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
    return PutChar(data);
  }

  util::StatusOr<int> Print(const char* data, char c) {
    ASSIGN_OR_RETURN(const auto* ptr, strchr("sqv", c));
    RET_CHECK(ptr != nullptr);
    int count = 0;
    if (c == 'q') {
      ASSIGN_OR_RETURN(const int temp, PutChar('"'));
      count += temp;
    }
    for (int i = 0; data[i]; i++) {
      if (c == 'q' && data[i] == '"') {
        ASSIGN_OR_RETURN(const int temp, PutChar('\\'));
        count += temp;
        i += 1;
      }
      ASSIGN_OR_RETURN(const int temp, PutChar(data[i]));
      count += temp;
    }
    if (c == 'q') {
      ASSIGN_OR_RETURN(const int temp, PutChar('"'));
      count += temp;
    }
    return count;
  }
};

}  // namespace libc

#endif  // LIBC_STDIO_PRINTER_H
