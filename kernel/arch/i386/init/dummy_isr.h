#ifndef KERNEL_ARCH_I386_BOOT_DUMMY_ISR_H
#define KERNEL_ARCH_I386_BOOT_DUMMY_ISR_H

#include "kernel/arch/i386/interrupt/macros.h"

namespace arch_internal {

REGISTER_INTERRUPT_SERVICE_ROUTINE(handleDummyInterrupt);

}  // namespace arch_internal

#endif
