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
    int CopyTo(multiboot_mmap_entry* entries, int capacity) const;

    // Returns a constant pointer to the mmap entries.
    const multiboot_mmap_entry* GetEntries() const {
      return entries_;
    }

    // Returns the number of mmap entries.
    int GetCount() const {
      return count_;
    }

    MmapManager() = default;
    MmapManager(const MmapManager&) = delete;
    MmapManager& operator=(const MmapManager&) = delete;

  private:

    // The number of Mmap entries
    int count_;

    // The Mmap entries provided by being a multiboot kernel
    multiboot_mmap_entry entries_[MAX_MMAP_ENTRIES];
};

  MmapManager* GetMmapManager();

} // namespace boot

#endif
