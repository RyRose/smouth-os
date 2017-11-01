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
//    uint32_t p1, p2, p3, p4;
//    p1 = static_cast<uint32_t>(multiboot_ptr[44]);
//    p2 = static_cast<uint32_t>(multiboot_ptr[45]);
//    p3 = static_cast<uint32_t>(multiboot_ptr[46]);
//    p4 = static_cast<uint32_t>(multiboot_ptr[47]);
//    uint32_t mmap_length = (p1 << 24) + (p2 << 16) + (p3 << 8) + p4;
//
//    p1 = static_cast<uint32_t>(multiboot_ptr[48]);
//    p2 = static_cast<uint32_t>(multiboot_ptr[49]);
//    p3 = static_cast<uint32_t>(multiboot_ptr[50]);
//    p4 = static_cast<uint32_t>(multiboot_ptr[51]);
//
//    uint32_t mmap_addr_start = (p1 << 24) + (p2 << 16) + (p3 << 8) + p4;
//    MmapEntry* mmap_addr = reinterpret_cast<MmapEntry*>(mmap_addr_start);
//
//    int i = 0;
//    while(reinterpret_cast<uint64_t>(mmap_addr) < mmap_addr_start + mmap_length) {
//      ++i;
//      mmap_entries[i] = *mmap_addr;
//      mmap_addr += mmap_addr->size;
//    }
//    mmap_entries_count = i;
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
