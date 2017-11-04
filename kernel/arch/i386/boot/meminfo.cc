#include "kernel/arch/i386/boot/meminfo.h"

#include <stdint.h>

#include "kernel/arch/i386/boot/multiboot.h"

namespace boot {

  int mmap_entries_count;
  multiboot_mmap_entry mmap_entries[100];

  void add_mmap_entries(multiboot_info* multiboot_ptr) {
    uint32_t mmap_length = multiboot_ptr ->mmap_length;
    auto* entries = reinterpret_cast<multiboot_mmap_entry*>(multiboot_ptr->mmap_addr);
    uint32_t i;
    for(i = 0; sizeof(multiboot_mmap_entry) * i < mmap_length; i++) {
      mmap_entries[i] = entries[i];
    }
    mmap_entries_count = i;
  }

  int GetMmapEntries(multiboot_mmap_entry* entries, int count) {
    int i;
    for(i = 0; i < count && i < mmap_entries_count; i++) {
      entries[i] = mmap_entries[i];
    }
    return i;
  }
}

boot::multiboot_info* multiboot_ptr;

extern "C"
void copy_multiboot(void) {
  boot::add_mmap_entries(multiboot_ptr);
}
