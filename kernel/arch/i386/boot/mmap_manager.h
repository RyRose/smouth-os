#ifndef KERNEL_ARCH_I386_BOOT_MMAP_MANAGER_H
#define KERNEL_ARCH_I386_BOOT_MMAP_MANAGER_H

#include <stddef.h>

#include "kernel/arch/i386/boot/multiboot.h"

namespace boot {

constexpr const size_t MAX_MMAP_ENTRIES = 100;

class MmapManager {
public:
  static MmapManager &GetInstance() {
    static MmapManager instance;
    return instance;
  }

  // Parses the multiboot pointer and copies up `MAX_MMAP_ENTRIES` to
  // pre-allocated memory.
  bool Init(const multiboot_info &multiboot_ptr);

  // Copies all of the stored mmap entries up to `capacity` entries to the
  // provided `entries` array.
  // Returns the number of entries copied.
  int CopyTo(multiboot_mmap_entry *entries, size_t capacity) const;

  int GetCount() const { return count_; }

  const multiboot_mmap_entry *GetEntries() const { return entries_; }

  MmapManager &operator=(const MmapManager &) = delete;

private:
  MmapManager() = default;

  // The number of Mmap entries
  size_t count_;

  // The Mmap entries provided by being a multiboot kernel
  multiboot_mmap_entry entries_[MAX_MMAP_ENTRIES];
};

} // namespace boot

#endif
