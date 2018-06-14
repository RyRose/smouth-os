#ifndef KERNEL_ARCH_I386_INTERRUPT_DESCRIPTOR_H
#define KERNEL_ARCH_I386_INTERRUPT_DESCRIPTOR_H

#include <stdint.h>

namespace interrupt {

enum class GateType : uint8_t {
  EMPTY = 0,
  TASK = 0x5,
  INTERRUPT_16BIT = 0x6,
  INTERRUPT_32BIT = 0xE,
  TRAP_16BIT = 0x7,
  TRAP_32BIT = 0xF,
};

// A class representing a 32-bit descriptor to be stored in the Interrupt
// Descriptor Table (IDT). Packed such that it can be directly used as elements
// in the i386 IDT.
class GateDescriptor {
 public:
  GateDescriptor()
      : offset_first_(0),
        segment_selector_(0),
        zeroes_(0),
        gate_type_(GateType::EMPTY),
        segment_(false),
        dpl_(0),
        present_(false),
        offset_second_(0) {}

  GateDescriptor(uint32_t offset, uint16_t segment_selector, GateType gate_type,
                 uint8_t dpl, bool present)
      : offset_first_(offset & 0xFFFF),
        segment_selector_(segment_selector),
        zeroes_(0),
        gate_type_(gate_type),
        segment_(false),
        // TODO(RyRose): Add check for overflow.
        dpl_(dpl),
        present_(present),
        offset_second_(offset >> 16) {}

 private:
  // The first 2 bytes of offset to the interrupt procedure entry point.
  // Basically, a pointer to the function that handles this interrupt.
  uint16_t offset_first_ : 16;
  // Index of the segment descriptor in the Global Descriptor Table (GDT) that
  // describes the code segment that `offset_` points to.
  uint16_t segment_selector_ : 16;
  // A byte that should always be zero.
  uint8_t zeroes_ : 8;
  // Four bits that determine the gate type (Interrupt/Task/Trap) and 16/32
  // bitness.
  GateType gate_type_ : 4;
  // Whether this descriptor points to a code/data segment. Else, it points
  // to some other system segment. We consider interrupt handlers some other
  // system segment and thus this bit should always be false.
  bool segment_ : 1;
  // Two bits that correspond to the 2-bit Descriptor Privilege Level (DPL)
  uint8_t dpl_ : 2;
  // Whether or not the segment is present.
  bool present_ : 1;
  // The last 2 bytes of the offset.
  uint16_t offset_second_ : 16;
} __attribute__((packed));

static_assert(sizeof(GateDescriptor) == 8,
              "i386 IDT gate descriptors must be 8 bytes!");

}  // namespace interrupt

#endif  //   KERNEL_ARCH_I386_INTERRUPT_DESCRIPTOR_H
