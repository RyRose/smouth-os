#ifndef KERNEL_ARCH_I386_INTERRUPT_TABLE_H
#define KERNEL_ARCH_I386_INTERRUPT_TABLE_H

#include <stddef.h>
#include <stdint.h>

#include "libc/string.h"

#include "gtest/gtest_prod.h"

#include "util/list.h"
#include "util/status.h"

namespace arch_internal {

enum GateType {
  EMPTY = 0u,
  TASK = 0x5u,
  INTERRUPT_32BIT = 0xEu,
  TRAP_32BIT = 0xFu,
};

// A class representing a 32-bit descriptor to be stored in the Interrupt
// Descriptor Table (IDT). Packed such that it can be directly used as elements
// in the i386 IDT.
struct GateDescriptor {
  // Creates a present interrupt GateDescriptor with the provided values.
  static util::StatusOr<GateDescriptor> Create(uint32_t offset,
                                               uint16_t segment_selector,
                                               GateType gate_type, uint8_t dpl);

  GateDescriptor()
      : offset_first(0),
        segment_selector(0),
        zeroes(0),
        gate_type(GateType::EMPTY),
        segment(false),
        dpl(0),
        present(false),
        offset_second(0) {}

  // The first 2 bytes of offset to the interrupt procedure entry point.
  // Basically, a pointer to the function that handles this interrupt.
  uint16_t offset_first : 16;
  // Index of the segment descriptor in the Global Descriptor Table (GDT) that
  // describes the code segment that `offset_` points to.
  uint16_t segment_selector : 16;
  // A byte that should always be zero.
  uint8_t zeroes : 8;
  // Four bits that determine the gate type (Interrupt/Task/Trap) and 16/32
  // bitness.
  GateType gate_type : 4;
  // Whether this descriptor points to a code/data segment. Else, it points
  // to some other system segment. We consider interrupt handlers some other
  // system segment and thus this bit should always be false.
  bool segment : 1;
  // Two bits that correspond to the 2-bit Descriptor Privilege Level (DPL)
  uint8_t dpl : 2;
  // Whether or not the segment is present.
  bool present : 1;
  // The last 2 bytes of the offset.
  uint16_t offset_second : 16;
} __attribute__((packed));

static_assert(sizeof(GateDescriptor) == 8,
              "i386 IDT gate descriptors must be 8 bytes!");

// The InterruptDescriptorTable represents the i386 IDT.
template <size_t N>
class InterruptDescriptorTable {
 public:
  // Registers the interrupt gate descriptor in the next free
  // spot in the IDT.
  util::Status Register(uint16_t index, GateDescriptor descriptor) {
    return table_.Set(index, descriptor);
  }

  // Returns a 48-bit value to be stored in the IDTR.
  uint64_t IDTR() const {
    uint64_t ret = reinterpret_cast<uint64_t>(table_.Address()) << 16u;
    if (table_.Size() > 0) {
      ret |= static_cast<uint64_t>(8 * table_.Size() - 1);
    }
    return ret;
  }

 private:
  FRIEND_TEST(Table, TestAddress);

  // The interrupt descriptor table.
  util::List<GateDescriptor, N> table_;
};

}  // namespace arch_internal

#endif
