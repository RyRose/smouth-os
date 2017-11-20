#include "kernel/arch/memory_detection.h"

#include <stdint.h>
#include <stddef.h>

#include "libc/stdio/printf.h"

#include "kernel/arch/i386/boot/meminfo.h"
#include "kernel/arch/i386/boot/multiboot.h"

extern uint32_t kernel_start;
extern uint32_t kernel_end;

namespace memory_detection {

  constexpr size_t MAX_MEMORY_REGIONS = 100;

  int DetectMemory(MemoryRegion* regions, int len) {
    if (len < 0 || len > MAX_MEMORY_REGIONS) {return -1;}

    boot::multiboot_mmap_entry entries[MAX_MEMORY_REGIONS];
    int count = boot::GetMmapEntries(entries, len);
    for(int i = 0; i < count; i++) {
      MemoryRegion region;
      region.address = entries[i].addr;
      region.length = entries[i].len;
      region.type = static_cast<MemoryRegionType>(entries[i].type); // hack(ryanthrose) handle errors on type
      regions[i] = region;
    }
    return count;
  }

  void* GetKernelStart() {
    return &kernel_start;
  }

  void* GetKernelEnd() {
    return &kernel_end;
  }

} // namespace memory_detection
