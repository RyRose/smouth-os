#include "kernel/arch/i386/boot/gdt_installer.h"

#include "kernel/arch/i386/boot/gdt.h"

#include <stddef.h>

extern "C"
void gdtFlush(uint64_t gdt_ptr);

namespace {
  uint64_t gdt[10];
}

namespace boot {

void installGdt() {
  GdtEntry null_selector(0, 0, 0);
  GdtEntry code_segment_selector(0, 0xFFFFFFFF, 0x9A);
  GdtEntry data_segment_selector(0, 0xFFFFFFFF, 0X92);
  gdt[0] = null_selector.Get();
  gdt[1] = code_segment_selector.Get();
  gdt[2] = data_segment_selector.Get();
  uint64_t gdt_ptr = reinterpret_cast<uint64_t>(&gdt);
  gdt_ptr <<= 16;
  gdt_ptr |= ((3 * sizeof(uint64_t)) - 0) & 0xFFFF;
  gdtFlush(gdt_ptr);
}

} // namespace boot

