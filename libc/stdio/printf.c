#include <limits.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

static void swap(char* data, size_t first, size_t second) {
  char temp = data[first];
  data[first] = data[second];
  data[second] = temp;
}

static void reverse(char* data, size_t start, size_t end) {
  for(int i = start; i < end / 2; ++i) {
    swap(data, i, end - 1 - i);
  }
}

static bool print(const char* data, size_t length) {
  const unsigned char* bytes = (const unsigned char*) data;
  for (size_t i = 0; i < length; i++)
    if (putchar(bytes[i]) == EOF)
      return false;
  return true;
}

static char convert_to_char(uint8_t number, bool is_uppercase) {
  if (number < 10) {
    return '0' + number;
  } else if (is_uppercase) {
    return 'A' + (number % 10);
  } else {
    return 'a' + (number % 10);
  }
}

static char* convert_to_string(uint64_t number, uint8_t base, bool is_negative, bool is_uppercase) {
  if (number == 0) {
    return "0";
  } else {
    static char converted[65];
    size_t i;
    for (i = 0; i < 64; ++i) {
      if (number > 0) {
        converted[i] = convert_to_char(number % base, is_uppercase);
        number /= base;
      } else {
        break;
      }
    }

    if (is_negative) {
      converted[i] = '-';
      ++i;
    }

    reverse(converted, 0, i);
    converted[i] = '\0';
    return converted;
  }
}

static int print_string(char* string, size_t maxrem) {
  int len = strlen(string);
  if (maxrem < len) {
    // TODO: Set errno to EOVERFLOW.
    return -1;
  }
  if (!print(string, len))
    return -1;
  return len;
}

int printf(const char* format, ...) {
  va_list parameters;
  va_start(parameters, format);

  int written = 0;
  int len;
  char* string;

  while (*format != '\0') {
    size_t maxrem = INT_MAX - written;

    if (format[0] != '%' || format[1] == '%') {
      if (format[0] == '%') {
	format++;
      }
      size_t amount = 1;
      while (format[amount] && format[amount] != '%') {
	amount++;
      }
      if (maxrem < amount) {
	// TODO: Set errno to EOVERFLOW.
	return -1;
      }
      if (!print(format, amount)) {
	return -1;
      }
      format += amount;
      written += amount;
      continue;
    }

    ++format;
    if (*format == 'c') {
      ++format;
      char c = (char) va_arg(parameters, int /* char promotes to int */);
      if (!maxrem) {
	// TODO: Set errno to EOVERFLOW.
	return -1;
      }
      if (!print(&c, sizeof(c)))
	return -1;
      ++written;
      continue;
    } else if (*format == 's') {
      ++format;
      string = va_arg(parameters, char*);
    } else if (*format == 'd' || *format == 'i') {
      ++format;
      int arg = va_arg(parameters, int);
      string = convert_to_string(abs(arg), 10, arg < 0, true);
    } else if (*format == 'X' || *format == 'x') {
      ++format;
      uint64_t arg = va_arg(parameters, uint64_t);
      string = convert_to_string(arg, 16, false, *(format - 1) == 'X');
    } else if (*format == 'o') {
      ++format;
      uint64_t arg = va_arg(parameters, uint64_t);
      string = convert_to_string(arg, 8, false, true);
    } else {
      string = (char*) format - 1;
      format += strlen(format);
    }

    len = print_string(string, maxrem);
    if (len == -1) {
      return -1;
    }
    written += len;
  }

  va_end(parameters);
  return written;
}
