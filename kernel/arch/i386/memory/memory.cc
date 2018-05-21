#include "kernel/arch/memory.h"

#include <stdint.h>
#include <stddef.h>

#include "kernel/arch/i386/boot/mmap_manager.h"
#include "kernel/arch/i386/boot/multiboot.h"

extern uint32_t kernel_start;
extern uint32_t kernel_end;

namespace arch {

  int DetectMemory(MemoryRegion* regions, int len) {
    if (len < 0) {
      return -1;
    }

    auto& mmap_manager = boot::MmapManager::GetInstance();
    int count = mmap_manager.GetCount();
    auto* mmap_entries = mmap_manager.GetEntries();

    MemoryRegion region;
    int i;
    for(i = 0; i < count && i < len; i++) {
      region.address = mmap_entries[i].addr;
      region.length = mmap_entries[i].len;
      region.type = static_cast<MemoryRegionType>(mmap_entries[i].type); // hack(ryanthrose) handle errors on type
      regions[i] = region;
    }
    return i;
  }

  void* GetKernelStart() {
    return &kernel_start;
  }

  void* GetKernelEnd() {
    return &kernel_end;
  }

} // namespace arch
