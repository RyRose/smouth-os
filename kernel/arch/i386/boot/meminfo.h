#ifndef KERNEL_ARCH_I386_BOOT_MEMINFO_H
#define KERNEL_ARCH_I386_BOOT_MEMINFO_H

#include <stdint.h>

#include "kernel/arch/i386/boot/multiboot.h"

namespace boot {

int GetMmapEntries(multiboot_mmap_entry* entries, int count);

void add_mmap_entries(unsigned int* multiboot_ptr);

}

#endif
