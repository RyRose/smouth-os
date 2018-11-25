#ifndef KERNEL_ARCH_I386_INTERRUPT_TABLE_H
#define KERNEL_ARCH_I386_INTERRUPT_TABLE_H

#include "kernel/arch/i386/interrupt/descriptor.h"
#include "kernel/util/status.h"

namespace interrupt {

constexpr uint16_t MAX_ENTRIES = 256;

// The InterruptDescriptorTable represents the i386 IDT.
class InterruptDescriptorTable {
 public:
  InterruptDescriptorTable() = default;

  // Registers the interrupt gate descriptor in the next free
  // spot in the IDT.
  util::Status Register(GateDescriptor descriptor, uint16_t index);

  // Returns a 48-bit value to be stored in the IDTR.
  uint64_t IDTR() const;

 private:
  // The interrupt desciptor table. Aligned on an 8-byte boundary as recommended
  // by the Intel x86 Systems Programming Guide for better cache locality.
  GateDescriptor table_[MAX_ENTRIES] __attribute__((aligned(8)));

  // The value to use for limit in the IDTR. Corresponds to the highest numbered
  // interrupt vector used.
  uint16_t limit_ = 0;

  // Used for testing.
  friend class Table_TestAddress_Test;
  friend class Table_TestInitiallyZeroed_Test;
};

// THE interrupt descriptor table.
static InterruptDescriptorTable IDT;

}  // namespace interrupt

#endif
