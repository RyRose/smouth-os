#include "libc/stdio/printf.h"

#include "kernel/arch/gdt.h"
#include "kernel/arch/tty.h"
#include "kernel/arch/memory_detection.h"

extern "C"
void kernel_main(void) {
  terminal_initialize();
  printf("Hello, World!\n");
  memory_detection::MemoryRegion regions[100];
  int count = memory_detection::DetectMemory(regions, 100);
  char* words[] = {"AVAILABLE", "RESERVED", "ACPI_RECLAIMABLE", "NVS", "BADRAM"};
  for (int i = 0; i < count; i++) {
    printf("address: %X, length: %X, ", regions[i].address, regions[i].length);
    printf("type: %s\n", words[regions[i].type - 1]);
  }
  uint64_t gdt_ptr = installGdt();
  printf("Enabled gdt. gdt_ptr: %X.\n", gdt_ptr);
}
