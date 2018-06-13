#include "kernel/arch/i386/interrupt/descriptor.h"

namespace interrupt {
uint64_t GateDescriptor::Get() const {
  uint64_t ret = 0;
  ret |= (offset_ >> 16) & 0xFFFF;
  ret <<= 8;
  ret |= type_;
  ret <<= 24;
  ret |= segment_selector_;
  ret <<= 16;
  ret |= (offset_ & 0xFFFF);
  return ret;
}
}  // namespace interrupt
