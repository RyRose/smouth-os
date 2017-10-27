#include "libc/stdio/printf.h"

#include "kernel/arch/gdt.h"
#include "kernel/arch/tty.h"

extern "C"
void kernel_main(void) {
  terminal_initialize();
  printf("Hello, World!\n");
  printf("test!\n");
  uint64_t gdt_ptr = installGdt();
  printf("Enabled gdt and protected mode. gdt_ptr: %X.\n", gdt_ptr);
}
