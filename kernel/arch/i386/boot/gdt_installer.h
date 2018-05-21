#ifndef KERNEL_ARCH_I386_BOOT_GDT_INSTALLER_H
#define KERNEL_ARCH_I386_BOOT_GDT_INSTALLER_H

namespace boot {

// Installs the global descriptor table into memory.
// See this link for more details:
// http://www.jamesmolloy.co.uk/tutorial_html/4.-The%20GDT%20and%20IDT.html
void installGdt();

} // namespace boot

#endif // KERNEL_ARCH_I386_BOOT_GDT_INSTALLER_H

