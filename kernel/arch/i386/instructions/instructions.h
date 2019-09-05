#ifndef KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H
#define KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H

#include <stdint.h>

namespace instructions {

// LoadIDT calls LIDT on the provided value to load
// into the Interrupt Descriptor Table Register (IDTR).
inline void LoadIDT(uint64_t idtr_value) {
  // TODO(RyRose): Log a warning for non-zero bits in the high 16 bits. This
  // should be a 48-bit value. This will unlikely be in the critical path and
  // thus can be done in non-debug mode.
  // TODO(RyRose): Check that CPL = 0. The current privilege level (CPL) must be
  // zero for this instruction to work.
  __asm__ volatile("LIDT %0" ::"m"(idtr_value));
}

// INT calls the INT instruction on the provided interrupt vector. This triggers
// a software interrupt. Should be templated since the instruction expects an
// imm8.
template <int N> inline void INT() { __asm__ volatile("INT %0" ::"N"(N)); }

} // namespace instructions

#endif // KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H
