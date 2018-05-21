#include "kernel/arch/i386/boot/mmap_manager.h"

#include <stddef.h>

#include "kernel/arch/i386/boot/multiboot.h"

namespace boot {

  bool MmapManager::Init(const multiboot_info& multiboot_ptr) {
    const auto* mmap_address =
      reinterpret_cast<multiboot_mmap_entry*>(multiboot_ptr.mmap_addr);
    const size_t mmap_entry_count =
      multiboot_ptr.mmap_length / sizeof(multiboot_mmap_entry);
    size_t i;
    for(i = 0; i < MAX_MMAP_ENTRIES && i < mmap_entry_count; i++) {
      entries_[i] = mmap_address[i];
    }
    count_ = i;
    return count_ == mmap_entry_count;
  }

  int MmapManager::CopyTo(multiboot_mmap_entry* entries, size_t capacity) const {
    size_t i;
    for(i = 0; i < count_ && i < capacity; i++) {
      entries[i] = entries_[i];
    }
    return i;
  }

}
