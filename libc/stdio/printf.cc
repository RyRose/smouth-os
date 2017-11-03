#include "libc/stdio/printf.h"

#include <stdint.h>
#include <stdarg.h>
#include <stddef.h>

#include "libc/stdio/putchar.h"
#include "libc/stdlib/arithmetic.h"
#include "libc/string/str.h"

namespace stdio {

  int print(const char* data) {
    int len = string::strlen(data);
    if (len < 0) {
      return len;
    }
    for (int i = 0; i < len; i++) {
      if (putchar(data[i]) != data[i]) {
        return -1;
      }
    }
    return len;
  }

  char convert_to_char(uint8_t number, bool is_uppercase) {
    if (number < 10) {
      return '0' + number;
    } else if (is_uppercase) {
      return 'A' + (number % 10);
    } else {
      return 'a' + (number % 10);
    }
  }

  int print_number(uint64_t number, uint8_t base, bool negative, bool uppercase) {
    if (number == 0) {
      return putchar('0') == '0' ? 1 : -1;
    } else {
      int i = 0;
      char converted[100];
      while(number) {
        converted[i] = convert_to_char(number % base, uppercase);
        number /= base;
        ++i;
      }

      int ret = 0;
      if (negative) {
        if (putchar('-') != '-') {
          return -1;
        } else {
          ++ret;
        }
      }

      --i;
      for (; i >= 0; --i) {
        if (putchar(converted[i]) != converted[i]) {
          return -1;
        }
        ++ret;
      }

      return ret;
    }
  }

  int printf(const char* format, ...) {
    va_list parameters;
    va_start(parameters, format);

    int len = 0;
    int format_len = string::strlen(format);
    for (int i = 0; i < format_len; ++i) {
      if (format[i] == '%') {
        if (++i == format_len) {
          return -1;
        }
        int arg_len;
        if (format[i] == 'c') {
          char c = va_arg(parameters, int);
          arg_len = putchar(c) == c ? 1 : -1;
        } else if (format[i] == 's') {
          char* string = va_arg(parameters, char*);
          arg_len = print(string);
        } else if (format[i] == 'd' || format[i] == 'i') {
          int arg = va_arg(parameters, int);
          arg_len = print_number(stdlib::abs(arg), 10, arg < 0, true);
        } else if (format[i] == 'X' || format[i] == 'x') {
          uint64_t arg = va_arg(parameters, uint64_t);
          arg_len = print_number(arg, 16, false, format[i] == 'X');
        } else if (format[i] == 'o') {
          uint64_t arg = va_arg(parameters, uint64_t);
          arg_len = print_number(arg, 8, false, true);
        } else if (format[i] == 'p') {
          uint64_t arg = reinterpret_cast<uint64_t>(va_arg(parameters, void*));
          arg_len = print_number(arg, 16, false, true);
        } else {
          return -1;
        }
        if (arg_len < 0) {
          return arg_len;
        }
        len += arg_len;
      } else { 
        if (putchar(format[i]) != format[i]) {
          return -1;
        } else {
          len++;
        }
      }
    }
    va_end(parameters);
    return len;
  }

}
