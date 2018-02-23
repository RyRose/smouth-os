#include "kernel/arch/tty.h"

#include <stdio.h>

namespace arch {

void terminal_initialize(void) {}

void terminal_putchar(char c) {
  putchar(c);
}

void terminal_write(const char* data, size_t size) {
  printf("%.*s", static_cast<int>(size), data);
}

void terminal_writestring(const char* data) {
  printf("%s", data);
}

}

