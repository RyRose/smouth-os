#ifndef KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H
#define KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H

#include <stdint.h>

#include "util/ret_checkf.h"
#include "util/status.h"

namespace instructions {

// LoadIDT calls LIDT on the provided value to load
// into the Interrupt Descriptor Table Register (IDTR).
inline util::Status LIDT(uint64_t idtr_value) {
  RET_CHECKF_EQ((idtr_value >> 48u), 0ul,
                "value of IDTR (0x%x) contains non-zero bits in high 16 bits",
                idtr_value);
  // TODO(RyRose): Check that CPL = 0. The current privilege level (CPL) must be
  // zero for this instruction to work.
  asm volatile("LIDT %0"::"m"(idtr_value));
  return {};
}

// INT calls the INT instruction on the provided interrupt vector. This triggers
// a software interrupt. Templated since the instruction expects an
// imm8.
template<int N>
inline void INT() {
  asm volatile("INT %0"::"N"(N));
}

// HLT calls the HLT instruction.
inline void HLT() { asm volatile("HLT"); }

// CLI calls the CLI instruction.
inline void CLI() { asm volatile("CLI"); }

// RDTSC calls the rdtsc instruction. See https://www.felixcloutier.com/x86/rdtsc for more details.
inline uint64_t RDTSC() {
  uint32_t low, high;
  asm volatile("RDTSC": "=a"(low), "=d"(high));
  return static_cast<uint64_t>(low) | (static_cast<uint64_t>(high) << 32);
}

inline void CPUID(int code, uint32_t where[4]) {
  asm volatile("cpuid":"=a"(*where), "=b"(*(where + 1)),
  "=c"(*(where + 2)), "=d"(*(where + 3)):"a"(code));
}

}  // namespace instructions

#endif  // KERNEL_ARCH_I386_INSTRUCTIONS_INSTRUCTIONS_H
