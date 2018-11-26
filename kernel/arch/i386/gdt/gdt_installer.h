#ifndef KERNEL_ARCH_I386_GDT_GDT_INSTALLER_H
#define KERNEL_ARCH_I386_GDT_GDT_INSTALLER_H

#include "kernel/arch/i386/gdt/gdt.h"

namespace gdt {

// Installs the global descriptor table into memory.
// See this link for more details:
// http://www.jamesmolloy.co.uk/tutorial_html/4.-The%20GDT%20and%20IDT.html
void InstallGDT();

}  // namespace gdt

#endif  // KERNEL_ARCH_I386_GDT_GDT_INSTALLER_H
