#ifndef KERNEL_ARCH_I386_BOOT_BOOT_H
#define KERNEL_ARCH_I386_BOOT_BOOT_H

#include "kernel/arch/i386/boot/multiboot.h"

namespace arch {

// Information about the multiboot header provided by the bootloader. See
// https://en.wikipedia.org/wiki/Multiboot_specification for more details on
// what this is.
extern multiboot_info multiboot_information;

}  // namespace arch

#endif
