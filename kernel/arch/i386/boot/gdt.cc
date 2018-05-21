#include "kernel/arch/i386/boot/gdt.h"

#include <stdint.h>

namespace boot {

uint64_t GdtEntry::Get() {
  uint8_t target[8];

  if (limit_ > 65536) {
    // Adjust granularity if required
    limit_ = limit_ >> 12;
    target[6] = 0xC0;
  } else if (limit_ == 0) {
    target[6] = 0;
  } else {
    target[6] = 0x40;
  }

  // Encode the limit
  target[0] = limit_ & 0xFF;
  target[1] = (limit_ >> 8) & 0xFF;
  target[6] |= (limit_ >> 16) & 0xF;

  // Encode the base
  target[2] = base_ & 0xFF;
  target[3] = (base_ >> 8) & 0xFF;
  target[4] = (base_ >> 16) & 0xFF;
  target[7] = (base_ >> 24) & 0xFF;

  // And... Type
  target[5] = type_;
  uint64_t* ret = reinterpret_cast<uint64_t*>(target);
  return *ret;
}

} // namespace boot

