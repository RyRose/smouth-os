#ifndef KERNEL_ARCH_I386_INTERRUPT_ISRS_H
#define KERNEL_ARCH_I386_INTERRUPT_ISRS_H

#include "stddef.h"
#include "stdint.h"

namespace arch {

namespace isrs {

extern "C" void dummy_handler();
extern "C" void double_fault();

}  // namespace isrs

}  // namespace arch

#endif  // KERNEL_ARCH_I386_INTERRUPT_ISRS_H
