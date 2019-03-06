#include "libc/stdio/printf.h"

#include "kernel/arch/memory.h"
#include "kernel/memory/memory.h"

namespace {

extern "C" void kernel_main(void) {
  libc::printf("Hello, World!\n");
  auto* allocator = memory::GetAllocator();
  arch::MemoryRegion regions[100];
  int count = arch::DetectMemory(regions, 100);
  const char* words[] = {"AVAILABLE", "RESERVED", "ACPI_RECLAIMABLE", "NVS",
                         "BADRAM"};
  for (int i = 0; i < count; i++) {
    libc::printf("address: %X, length: %X, ", regions[i].address,
                 regions[i].length);
    libc::printf("type: %s\n", words[static_cast<int>(regions[i].type) - 1]);
    allocator->AddMemory(regions[i]);
  }
  libc::printf("Kernel start: 0x%p, end: 0x%p.\n", arch::GetKernelStart(),
               arch::GetKernelEnd());
  char* a = new char[0x9FC000];
  a[0] = 'm';
  a[1] = 'e';
  a[2] = 'm';
  a[3] = '\0';
  libc::printf("memory test: location=0x%p, string=%s\n", a, a);
  delete a;
}

}  // namespace
