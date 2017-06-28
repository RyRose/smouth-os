#include <stdio.h>

#include <kernel/tty.h>
#include <kernel/gdt.h>

extern "C"
void kernel_main(void) {
  terminal_initialize();
  printf("Hello, World!\n");
  uint64_t gdt_ptr = installGdt();
  printf("Enabled gdt and protected mode. gdt_ptr: %X.\n", gdt_ptr);
}
