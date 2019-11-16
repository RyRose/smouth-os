#ifndef KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H
#define KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H

#include <stdint.h>
#include "util/status.h"

namespace instructions {

// LoadIDT calls LIDT on the provided value to load
// into the Interrupt Descriptor Table Register (IDTR).
inline util::Status LIDT(uint64_t idtr_value) {
  RET_CHECK((idtr_value >> 48u) == 0,
            "value of IDTR contains non-zero bits in high 16 bits");
  // TODO(RyRose): Check that CPL = 0. The current privilege level (CPL) must be
  // zero for this instruction to work.
  asm volatile("LIDT %0" ::"m"(idtr_value));
  return {};
}

// INT calls the INT instruction on the provided interrupt vector. This triggers
// a software interrupt. Templated since the instruction expects an
// imm8.
template <int N>
inline void INT() {
  asm volatile("INT %0" ::"N"(N));
}

// HLT calls the HLT instruction.
inline void HLT() { asm volatile("HLT"); }

// CLI calls the CLI instruction.
inline void CLI() { asm volatile("CLI"); }

}  // namespace instructions

#endif  // KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H
