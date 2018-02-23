#include "libc/stdio/printf.h"

#include "kernel/arch/gdt.h"
#include "kernel/arch/tty.h"
#include "kernel/arch/memory.h"

extern "C"
void kernel_main(void) {
  arch::terminal_initialize();
  libc::printf("Hello, World!\n");
  arch::MemoryRegion regions[100];
  int count = arch::DetectMemory(regions, 100);
  char* words[] = {"AVAILABLE", "RESERVED", "ACPI_RECLAIMABLE", "NVS", "BADRAM"};
  for (int i = 0; i < count; i++) {
    libc::printf("address: %X, length: %X, ", regions[i].address, regions[i].length);
    libc::printf("type: %s\n", words[static_cast<int>(regions[i].type) - 1]);
  }
  uint64_t gdt_ptr = arch::installGdt();
  libc::printf("Enabled gdt. gdt_ptr: 0x%X, &gdt_ptr: 0x%p.\n", gdt_ptr, &gdt_ptr);
  libc::printf("Kernel start: 0x%p, end: 0x%p.\n", arch::GetKernelStart(), arch::GetKernelEnd());
}
