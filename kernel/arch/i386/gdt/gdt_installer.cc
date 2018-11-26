#include "kernel/arch/i386/gdt/gdt_installer.h"

#include "kernel/arch/i386/gdt/gdt.h"

#include <stddef.h>

namespace {
extern "C" void gdtFlush(uint64_t gdt_ptr);
}  // namespace

namespace gdt {

void InstallGDT() {
  Descriptor null_descriptor;
  Descriptor code_descriptor(
      /*base=*/0, /*limit=*/0xFFFFFFFF, /*segment_type=*/0xA,
      /*descriptor_type=*/true, /*dpl=*/0, /*present=*/true,
      /*db=*/true, /*granularity=*/true);
  Descriptor data_descriptor(
      /*base=*/0, /*limit=*/0xFFFFFFFF, /*segment_type=*/0x2,
      /*descriptor_type=*/true, /*dpl=*/0, /*present=*/true,
      /*db=*/true, /*granularity=*/true);
  GDT[0] = null_descriptor;
  GDT[1] = code_descriptor;
  GDT[2] = data_descriptor;
  uint64_t gdt_ptr = reinterpret_cast<uint64_t>(&GDT);
  gdt_ptr <<= 16;
  gdt_ptr |= (3 * sizeof(uint64_t)) & 0xFFFF;
  gdtFlush(gdt_ptr);
}

}  // namespace gdt
