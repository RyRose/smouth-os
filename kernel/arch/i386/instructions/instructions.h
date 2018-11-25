#ifndef KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H
#define KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H

#include <stdint.h>

namespace instructions {

// LoadIDT calls LIDT on the provided value to load
// into the IDTR.
inline void LoadIDT(uint64_t idtr_value) {
  // TODO(RyRose): Log a warning for non-zero bits in the high 16 bits. This
  // should be a 48-bit value. This will unlikely be in the critical path and
  // thus can be done in non-debug mode.
  __asm__ volatile("LIDT %0" ::"m"(idtr_value));
}

}  // namespace instructions

#endif  // KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H
