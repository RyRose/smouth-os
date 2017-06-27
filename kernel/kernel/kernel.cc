#include <stdio.h>

#include <kernel/tty.h>
#include <kernel/gdt.h>

extern "C"
void kernel_main(void) {
  terminal_initialize();
  printf("Hello, World!\n");
  installGdt();
}
