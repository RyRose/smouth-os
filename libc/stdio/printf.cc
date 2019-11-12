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

char convert_to_char(uint8_t number, bool is_uppercase) {
  if (number < 10) {
    return '0' + number;
  }
  if (is_uppercase) {
    return 'A' + (number % 10);
  }
  return 'a' + (number % 10);
}

template <class V>
util::StatusOr<int> print_number(V number, uint8_t base, bool negative,
                                 bool uppercase) {
  if (number == 0) {
    RETURN_IF_ERROR(putchar('0'));
    return 1;
  }
  int i = 0;
  char converted[100];
  while (number) {
    RET_CHECK(i < 100, "overflowed array caching printed number");
    converted[i] = convert_to_char(number % base, uppercase);
    number /= base;
    i++;
  }

  int ret = 0;
  if (negative) {
    RETURN_IF_ERROR(putchar('-'));
    ret++;
  }

  i--;
  for (; i >= 0; i--) {
    RETURN_IF_ERROR(putchar(converted[i]));
    ret++;
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
        auto arg = va_arg(parameters, unsigned int);
        ASSIGN_OR_RETURN(arg_len, print_number<unsigned int>(
                                      /*number=*/arg, /*base=*/10,
                                      /*negative=*/false, /*uppercase=*/true));
        break;
      }
      case 'd':
      case 'i': {
        auto arg = va_arg(parameters, int);
        ASSIGN_OR_RETURN(
            arg_len,
            print_number<int>(/*number=*/abs(arg), /*base=*/10,
                              /*negative=*/arg < 0, /*uppercase=*/true));
        break;
      }
      case 'X':
      case 'x': {
        auto arg = va_arg(parameters, uint64_t);
        ASSIGN_OR_RETURN(
            arg_len, print_number<uint64_t>(/*number=*/arg, /*base=*/16,
                                            /*negative=*/false,
                                            /*uppercase=*/format[i] == 'X'));
        break;
      }
      case 'o': {
        auto arg = va_arg(parameters, uint64_t);
        ASSIGN_OR_RETURN(arg_len, print_number<uint64_t>(
                                      /*number=*/arg, /*base=*/8,
                                      /*negative=*/false, /*uppercase=*/true));
        break;
      }
      case 'p': {
        auto arg = reinterpret_cast<uint64_t>(va_arg(parameters, void*));
        ASSIGN_OR_RETURN(arg_len, print_number<uint64_t>(
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
