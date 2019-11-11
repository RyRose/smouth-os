#ifndef KERNEL_ARCH_I386_BOOT_DUMMY_ISR_H
#define KERNEL_ARCH_I386_BOOT_DUMMY_ISR_H

namespace arch_internal {

extern "C" void dummy_handler();
extern "C" void handleDummyInterrupt();

}  // namespace arch_internal

#endif
