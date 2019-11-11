#ifndef KERNEL_ARCH_I386_GDT_GDT_INSTALLER_H
#define KERNEL_ARCH_I386_GDT_GDT_INSTALLER_H

#include <stdint.h>
#include "util/status.h"

namespace arch_internal {

// Installs and flushes the global descriptor table.
// See this link for more details:
// http://www.jamesmolloy.co.uk/tutorial_html/4.-The%20GDT%20and%20IDT.html
util::Status InstallAndFlushGDT(uint64_t gdt_ptr);

}  // namespace arch_internal

#endif  // KERNEL_ARCH_I386_GDT_GDT_INSTALLER_H
