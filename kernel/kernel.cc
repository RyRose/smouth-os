#include "libc/stdio/printf.h"

#include "kernel/arch/boot.h"
#include "kernel/arch/memory.h"
#include "kernel/arch/serial.h"
#include "kernel/memory/memory.h"

namespace {

extern "C" void kernel_main(void) {
  arch::Initialize();
  libc::printf("Hello, World!\n");
  arch::COM1.Initialize();
  libc::printf("Initialized COM1\n");
  arch::COM1.Write('h');
  libc::printf("Wrote 'h' to COM1\n");
  arch::COM1.Write('e');
  libc::printf("Wrote 'e' to COM1\n");
  arch::COM1.Write('l');
  libc::printf("Wrote 'l' to COM1\n");
  arch::COM1.Write('l');
  libc::printf("Wrote 'l' to COM1\n");
  arch::COM1.Write('o');
  libc::printf("Wrote 'o' to COM1\n");
  auto *allocator = memory::GetAllocator();
  arch::MemoryRegion regions[100];
  int count = arch::DetectMemory(regions, 100);
  const char *words[] = {"AVAILABLE", "RESERVED", "ACPI_RECLAIMABLE", "NVS",
                         "BADRAM"};
  for (int i = 0; i < count; i++) {
    libc::printf("address: %X, length: %X, ", regions[i].address,
                 regions[i].length);
    libc::printf("type: %s\n", words[static_cast<int>(regions[i].type) - 1]);
    allocator->AddMemory(regions[i]);
  }
  libc::printf("Kernel start: 0x%p, end: 0x%p.\n", arch::GetKernelStart(),
               arch::GetKernelEnd());
  char *a = new char[0x9FC000];
  a[0] = 'm';
  a[1] = 'e';
  a[2] = 'm';
  a[3] = '\0';
  libc::printf("memory test: location=0x%p, string=%s\n", a, a);
  delete a;
}

} // namespace
