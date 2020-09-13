#ifndef KERNEL_ARCH_MEMORY_H
#define KERNEL_ARCH_MEMORY_H

#include <stdint.h>

#include "util/status.h"

namespace arch {

enum class MemoryRegionType { AVAILABLE, RESERVED };

struct MemoryRegion {
 public:
  MemoryRegion(uint64_t address_, uint64_t length_, MemoryRegionType type_)
      : address(address_), length(length_), type(type_){};

  MemoryRegion() = default;

  uint64_t address;
  uint64_t length;
  MemoryRegionType type;
};

}  // namespace arch

#endif
