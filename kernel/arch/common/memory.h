#ifndef KERNEL_ARCH_MEMORY_H
#define KERNEL_ARCH_MEMORY_H

#include <stdint.h>

#include "util/status.h"

namespace arch {

enum class MemoryRegionType { UNKNOWN, AVAILABLE, RESERVED };

struct MemoryRegion {
 public:
  MemoryRegion(uint64_t address_, uint64_t length_, MemoryRegionType type_)
      : address(address_), length(length_), type(type_){};
  MemoryRegion() = default;

  uint64_t address = 0;
  uint64_t length = 0;
  MemoryRegionType type = MemoryRegionType::UNKNOWN;
};

}  // namespace arch

#endif
