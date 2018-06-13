#ifndef KERNEL_ARCH_I386_INTERRUPT_DESCRIPTOR_H
#define KERNEL_ARCH_I386_INTERRUPT_DESCRIPTOR_H

#include <stdint.h>

namespace interrupt {

namespace {

// Combines the different parts of the 5th byte of an IDT gate descriptor to be
// properly formatted.
//
// `gate_type` is the first 3 bits of the type byte that determine the gate type
// (Interrupt/Task/Trap). `dpl` corresponds to the 2-bit Descriptor Privilege
// Level (DPL). `bit_type` is true if the size of the gate is 32 bits. False is
// 16 bits. `present` is true if the segment is present and false otherwise.
constexpr uint8_t GetDescriptorType(uint8_t gate_type, uint8_t dpl,
                                    bool bit_type, bool present) {
  return (0x7 & gate_type) | (bit_type << 3) | ((dpl & 0x3) << 5) |
         (present << 7);
}

}  // namespace

// A class representing a descriptor to be stored in the Interrupt Descriptor
// Table (IDT).
class GateDescriptor {
 public:
  GateDescriptor(uint32_t offset, uint16_t segment_selector, uint8_t type)
      : offset_(offset), segment_selector_(segment_selector), type_(type) {}

  // Returns the gate descriptor properly formatted for insertion to the IDT.
  uint64_t Get() const;

 private:
  // The offset to the interrupt procedure entry point. Basically, a pointer to
  // the function that handles this interrupt.
  uint32_t offset_;

  // Index of the segment descriptor in the Global Descriptor Table (GDT) that
  // describes the code segment that `offset_` points to.
  uint16_t segment_selector_;

  // The 5th byte (zero-indexed of course) in the gate descriptor. Corresponds
  // to the type of gate (Task/Interrupt/Trap) along with the present bit,
  // Descriptor Privilege Level (DPL), and gate size bit (16 bit vs 32 bit).
  uint8_t type_;
};

// A GateDescriptor that represents an interrupt gate.
class InterruptGateDescriptor : public GateDescriptor {
 public:
  InterruptGateDescriptor(uint32_t offset, uint16_t segment_selector,
                          uint8_t dpl, bool bit_type, bool present)
      : GateDescriptor(offset, segment_selector,
                       GetDescriptorType(0x6, dpl, bit_type, present)) {}
};

// A GateDescriptor that represents a trap gate.
class TrapGateDescriptor : public GateDescriptor {
 public:
  TrapGateDescriptor(uint32_t offset, uint16_t segment_selector, uint8_t dpl,
                     bool bit_type, bool present)
      : GateDescriptor(offset, segment_selector,
                       GetDescriptorType(0x7, dpl, bit_type, present)) {}
};

// A GateDescriptor that represents a task gate.
class TaskGateDescriptor : public GateDescriptor {
 public:
  TaskGateDescriptor(uint16_t segment_selector, uint8_t dpl, bool present)
      : GateDescriptor(0, segment_selector,
                       GetDescriptorType(0x5, dpl, false, present)) {}
};

}  // namespace interrupt

#endif  //   KERNEL_ARCH_I386_INTERRUPT_DESCRIPTOR_H
