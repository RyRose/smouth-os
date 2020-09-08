
#include "kernel/core/init.h"

#include "cxx/kernel.h"
#include "kernel/arch/init.h"
#include "kernel/core/memory.h"
#include "libc/stdio.h"
#include "util/status.h"

namespace kernel {

namespace {
BumpAllocator<100> kHeap;
}

util::Status Initialize(const arch::BootInfo& boot_info) {
  libc::puts("== Kernel Initialize ==");
  libc::printf("Boot Info: {tty=0x%p, com1=0x%p}\n", boot_info.tty,
               boot_info.com1);
  libc::puts("Memory Regions: [");
  for (size_t i = 0; i < boot_info.memory_regions.Size(); i++) {
    ASSIGN_OR_RETURN(const auto& region, boot_info.memory_regions.At(i));
    libc::printf("  {address=0x%x, length=0x%x (%d KiB), type=%s}\n",
                 region->address, region->length, region->length / 1024,
                 region->type == arch::MemoryRegionType::AVAILABLE
                     ? "available"
                     : "reserved");
  }
  libc::puts("]");
  ASSIGN_OR_RETURN(kHeap, BumpAllocator<100>::Create(boot_info.memory_regions));
  cxx::kernel_new = [](size_t n) { return kHeap.Allocate(n); };
  return {};
}

}  // namespace kernel
