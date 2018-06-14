#include "kernel/arch/i386/interrupt/table.h"
#include "kernel/arch/i386/interrupt/descriptor.h"

#include "kernel/util/status.h"

namespace interrupt {

util::Status InterruptDescriptorTable::Register(GateDescriptor descriptor,
                                                uint16_t index) {
  if (index >= MAX_ENTRIES) {
    return util::Status(util::ErrorCode::OVERFLOW);
  }
  table_[index] = descriptor;
  if (8 * (index + 1) - 1 > limit_) {
    limit_ = 8 * (index + 1) - 1;
  }
  return util::Status();
}

uint64_t InterruptDescriptorTable::IDTR() const {
  // TODO(RyRose): Log a warning if the memory address is greater than 2^32 - 1.
  return (static_cast<uint64_t>(limit_) << 32) |
         (reinterpret_cast<uint64_t>(table_) & 0xFFFFFFFF);
}

}  // namespace interrupt
