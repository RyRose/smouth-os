#include <limits.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

static void swap(char* data, size_t first, size_t second) {
  char temp = data[first];
  data[first] = data[second];
  data[second] = temp;
}

static void reverse(char* data, size_t length) {
  for(int i = 0; i < length / 2; ++i) {
    swap(data, i, length - 1 - i);
  }
}

static bool print(const char* data, size_t length) {
  const unsigned char* bytes = (const unsigned char*) data;
  for (size_t i = 0; i < length; i++)
    if (putchar(bytes[i]) == EOF)
      return false;
  return true;
}

static char convert_to_char(int number) {
  if (number < 10) {
    return '0' + number;
  } else {
    return 'A' + (number % 10);
  }
}

static int print_int(int to_print, int maxrem, int base) {
  char converted[10];
  int i;
  for (i = 0; i < 9; ++i) {
    if (to_print > 0) {
      converted[i] = convert_to_char(to_print % base);
      to_print /= base;
    } else {
      break;
    }
  }
  if (i > maxrem) {
    return -1;
  }

  reverse(converted, i);

  if (!print(converted, i)) {
    return -1;
  }

  return i;
}

int printf(const char* format, ...) {
  va_list parameters;
  va_start(parameters, format);

  int written = 0;

  while (*format != '\0') {
    size_t maxrem = INT_MAX - written;

    if (format[0] != '%' || format[1] == '%') {
      if (format[0] == '%')
	format++;
      size_t amount = 1;
      while (format[amount] && format[amount] != '%')
	amount++;
      if (maxrem < amount) {
	// TODO: Set errno to EOVERFLOW.
	return -1;
      }
      if (!print(format, amount))
	return -1;
      format += amount;
      written += amount;
      continue;
    }

    const char* format_begun_at = format++;

    if (*format == 'c') {
      format++;
      char c = (char) va_arg(parameters, int /* char promotes to int */);
      if (!maxrem) {
	// TODO: Set errno to EOVERFLOW.
	return -1;
      }
      if (!print(&c, sizeof(c)))
	return -1;
      written++;
    } else if (*format == 's') {
      format++;
      const char* str = va_arg(parameters, const char*);
      size_t len = strlen(str);
      if (maxrem < len) {
	// TODO: Set errno to EOVERFLOW.
	return -1;
      }
      if (!print(str, len))
	return -1;
      written += len;
    } else if (*format == 'd') {
      format++;
      int arg = va_arg(parameters, int);
      size_t len = print_int(arg, maxrem, 10);
      if (len == -1) {
        return -1;
      }
      written += len;
    } else if (*format == 'X') {
      format++;
      int arg = va_arg(parameters, int);
      size_t len = print_int(arg, maxrem, 16);
      if (len == -1) {
        return -1;
      }
      written += len;
    } else {
      format = format_begun_at;
      size_t len = strlen(format);
      if (maxrem < len) {
	// TODO: Set errno to EOVERFLOW.
	return -1;
      }
      if (!print(format, len))
	return -1;
      written += len;
      format += len;
    }
  }

  va_end(parameters);
  return written;
}
