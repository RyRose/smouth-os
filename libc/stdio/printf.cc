#include "libc/stdio.h"

#include <stdarg.h>
#include <stdint.h>

#include "libc/stdlib.h"
#include "libc/string.h"
#include "util/status.h"

namespace libc {

namespace {

util::StatusOr<int> print(const char* data) {
  ASSIGN_OR_RETURN(int len, strlen(data));
  for (int i = 0; i < len; i++) {
    RETURN_IF_ERROR(putchar(data[i]));
  }
  return len;
}

template <class V>
char convert_to_char(V number, bool is_uppercase) {
  if (number < 10) {
    return '0' + number;
  }
  return (is_uppercase ? 'A' : 'a') + (number % 10);
}

template <class V>
util::StatusOr<int> print_number(const V& number, const V& base,
                                 const bool& negative, const bool& uppercase) {
  RET_CHECK(number >= 0);

  int i = 0;
  V temp = number;
  char converted[100];
  do {
    converted[i] = convert_to_char<V>(temp % base, uppercase);
    temp /= base;
    i++;
  } while (temp && i < 100);
  RET_CHECK(temp == 0);

  if (negative) {
    converted[i] = '-';
    i++;
  }

  int ret = i;
  for (i--; i >= 0; i--) {
    RETURN_IF_ERROR(putchar(converted[i]));
  }
  return ret;
}

}  // namespace

util::StatusOr<int> printf(const char* format, ...) {
  va_list parameters;
  va_start(parameters, format);

  ASSIGN_OR_RETURN(int format_len, strlen(format));

  int percents = 0;
  for (int i = 0; i < format_len; i++) {
    if (format[i] == '%') {
      percents++;
    }
  }

  int len = 0;
  int arg_count = 0;
  for (int i = 0; i < format_len; i++) {
    if (format[i] != '%') {
      RETURN_IF_ERROR(putchar(format[i]));
      len++;
      continue;
    }

    RET_CHECK(arg_count < percents, "number of %'s exceeds arguments");
    arg_count++;

    i++;
    RET_CHECK(i < format_len, "% cannot be used as final character");

    int arg_len;
    switch (format[i]) {
      case '%': {
        RETURN_IF_ERROR(putchar('%'));
        arg_len = 1;
        break;
      }
      case 'c': {
        auto c = va_arg(parameters, int);
        RETURN_IF_ERROR(putchar(c));
        arg_len = 1;
        break;
      }
      case 's': {
        const char* string = va_arg(parameters, const char*);
        ASSIGN_OR_RETURN(arg_len, print(string));
        break;
      }
      case 'u': {
        auto base = 10;
        bool negative = false;
        bool uppercase = false;
        switch (format[i + 1]) {
          case 'l':
            i++;
            switch (format[i + 1]) {
              case 'l': {
                i++;
                auto arg = va_arg(parameters, unsigned long long int);
                ASSIGN_OR_RETURN(arg_len, print_number<unsigned long long int>(
                                              /*number=*/arg, /*base=*/base,
                                              /*negative=*/negative,
                                              /*uppercase=*/uppercase));
                break;
              }
              default: {
                auto arg = va_arg(parameters, unsigned long int);
                ASSIGN_OR_RETURN(arg_len, print_number<unsigned long int>(
                                              /*number=*/arg, /*base=*/base,
                                              /*negative=*/negative,
                                              /*uppercase=*/uppercase));
                break;
              }
            }
            break;
          default:
            auto arg = va_arg(parameters, unsigned int);
            ASSIGN_OR_RETURN(arg_len, print_number<unsigned int>(
                                          /*number=*/arg, /*base=*/base,
                                          /*negative=*/negative,
                                          /*uppercase=*/uppercase));
            break;
        }
        break;
      }
      case 'd':
      case 'i': {
        auto base = 10;
        bool uppercase = false;
        switch (format[i + 1]) {
          case 'l':
            i++;
            switch (format[i + 1]) {
              case 'l': {
                i++;
                auto arg = va_arg(parameters, signed long long int);
                if (arg < 0) {
                  arg = -arg;
                }
                ASSIGN_OR_RETURN(arg_len, print_number<signed long long int>(
                                              /*number=*/arg, /*base=*/base,
                                              /*negative=*/arg < 0,
                                              /*uppercase=*/uppercase));
                break;
              }
              default: {
                auto arg = va_arg(parameters, signed long int);
                if (arg < 0) {
                  arg = -arg;
                }
                ASSIGN_OR_RETURN(arg_len, print_number<signed long int>(
                                              /*number=*/arg, /*base=*/base,
                                              /*negative=*/arg < 0,
                                              /*uppercase=*/uppercase));
                break;
              }
            }
            break;
          default:
            auto arg = va_arg(parameters, signed int);
            if (arg < 0) {
              arg = -arg;
            }
            ASSIGN_OR_RETURN(arg_len, print_number<signed int>(
                                          /*number=*/arg, /*base=*/base,
                                          /*negative=*/arg < 0,
                                          /*uppercase=*/uppercase));
            break;
        }
        break;
      }
      case 'X':
      case 'x': {
        auto base = 16;
        bool negative = false;
        bool uppercase = format[i] == 'X';
        switch (format[i + 1]) {
          case 'l':
            i++;
            switch (format[i + 1]) {
              case 'l': {
                i++;
                auto arg = va_arg(parameters, unsigned long long int);
                ASSIGN_OR_RETURN(arg_len, print_number<unsigned long long int>(
                                              /*number=*/arg, /*base=*/base,
                                              /*negative=*/negative,
                                              /*uppercase=*/uppercase));
                break;
              }
              default: {
                auto arg = va_arg(parameters, unsigned long int);
                ASSIGN_OR_RETURN(arg_len, print_number<unsigned long int>(
                                              /*number=*/arg, /*base=*/base,
                                              /*negative=*/negative,
                                              /*uppercase=*/uppercase));
                break;
              }
            }
            break;
          default:
            auto arg = va_arg(parameters, unsigned int);
            ASSIGN_OR_RETURN(arg_len, print_number<unsigned int>(
                                          /*number=*/arg, /*base=*/base,
                                          /*negative=*/negative,
                                          /*uppercase=*/uppercase));
            break;
        }
        break;
      }
      case 'o': {
        auto base = 8;
        bool negative = false;
        bool uppercase = false;
        switch (format[i + 1]) {
          case 'l':
            i++;
            switch (format[i + 1]) {
              case 'l': {
                i++;
                auto arg = va_arg(parameters, unsigned long long int);
                ASSIGN_OR_RETURN(arg_len, print_number<unsigned long long int>(
                                              /*number=*/arg, /*base=*/base,
                                              /*negative=*/negative,
                                              /*uppercase=*/uppercase));
                break;
              }
              default: {
                auto arg = va_arg(parameters, unsigned long int);
                ASSIGN_OR_RETURN(arg_len, print_number<unsigned long int>(
                                              /*number=*/arg, /*base=*/base,
                                              /*negative=*/negative,
                                              /*uppercase=*/uppercase));
                break;
              }
            }
            break;
          default:
            auto arg = va_arg(parameters, unsigned int);
            ASSIGN_OR_RETURN(arg_len, print_number<unsigned int>(
                                          /*number=*/arg, /*base=*/base,
                                          /*negative=*/negative,
                                          /*uppercase=*/uppercase));
            break;
        }
        break;
      }
      case 'p': {
        auto arg = reinterpret_cast<uintptr_t>(va_arg(parameters, void*));
        ASSIGN_OR_RETURN(arg_len, print_number<uintptr_t>(
                                      /*number=*/arg, /*base=*/16,
                                      /*negative=*/false, /*uppercase=*/true));
        break;
      }
      default:
        return util::Status(util::ErrorCode::INVALID_ARGUMENT,
                            "unknown printf formatter");
    }
    len += arg_len;
  }
  va_end(parameters);
  return len;
}

}  // namespace libc
