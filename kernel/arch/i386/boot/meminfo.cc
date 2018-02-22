#include "kernel/arch/i386/boot/meminfo.h"

#include <stdint.h>

#include "kernel/arch/i386/boot/multiboot.h"

namespace boot {

  MmapManager mmap_manager;

  MmapManager* GetMmapManager() {
    return &mmap_manager;
  }

  int MmapManager::CopyFrom(multiboot_mmap_entry* entries, int count) {
    int i;
    for(i = this->count; i < MAX_MMAP_ENTRIES && i < count; i++) {
      this->entries[i] = entries[i];
    }
    this->count += i;
    return this->count - 2 * i;
  }

  int MmapManager::CopyTo(multiboot_mmap_entry* entries, int capacity) {
    int i;
    for(i = 0; i < count && i < capacity; i++) {
      entries[i] = this->entries[i];
    }
    return i;
  }

}

namespace {

extern "C"
void copy_multiboot(boot::multiboot_info* multiboot_ptr) {
  auto* mmap_manager = boot::GetMmapManager();
  auto* mmap_address = reinterpret_cast<boot::multiboot_mmap_entry*>(multiboot_ptr->mmap_addr);
  auto mmap_entry_count = multiboot_ptr->mmap_length / sizeof(boot::multiboot_mmap_entry);
  mmap_manager->CopyFrom(mmap_address, mmap_entry_count);
}

}
