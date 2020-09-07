#ifndef KERNEL_ARCH_I386_BOOT_BOOT_H
#define KERNEL_ARCH_I386_BOOT_BOOT_H

#include "kernel/arch/i386/boot/multiboot.h"
#include "stdint.h"

// The address of this is the start of the kernel code. It's explicitly not
// wrapped in a namespace to ensure that the linker sets it.
extern char kKernelStart;

// The address of this is the end of the kernel code. It's explicitly not
// wrapped in a namespace to ensure that the linker sets it.
extern char kKernelEnd;

namespace arch {

// Information about the multiboot header provided by the bootloader. See
// https://en.wikipedia.org/wiki/Multiboot_specification for more details on
// what this is.
extern multiboot_info kMultibootInformation;

}  // namespace arch

#endif
