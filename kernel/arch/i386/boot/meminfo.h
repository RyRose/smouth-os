#ifndef KERNEL_ARCH_I386_BOOT_MEMINFO_H
#define KERNEL_ARCH_I386_BOOT_MEMINFO_H

#include <stdint.h>

#include "kernel/arch/i386/boot/multiboot.h"

namespace boot {

const int MAX_MMAP_ENTRIES = 100;

class MmapManager {

  public:

    // Copies `count` mmap entries from `entries`.
    // Returns the number of entries copied.
    int CopyFrom(multiboot_mmap_entry* entries, int count);

    // Copies all mmap entries to `entries` until filled.
    // Returns the number of entries copied.
    int CopyTo(multiboot_mmap_entry* entries, int capacity);

    // Returns a constant pointer to the mmap entries.
    const multiboot_mmap_entry* GetEntries() {
      return entries;
    }

    // Returns the number of mmap entries.
    int GetCount() {
      return count;
    }

    MmapManager() = default;
    MmapManager(const MmapManager&) = delete;
    MmapManager& operator=(const MmapManager&) = delete;

  private:

    // The number of Mmap entries
    int count;

    // The Mmap entries provided by being a multiboot kernel
    multiboot_mmap_entry entries[MAX_MMAP_ENTRIES];
};

  MmapManager* GetMmapManager();

} // namespace boot

#endif
