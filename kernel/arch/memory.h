#ifndef KERNEL_ARCH_MEMORY_H
#define KERNEL_ARCH_MEMORY_H

#include <stdint.h>

#include "util/status.h"

namespace arch {

class Allocator {
 public:
  virtual util::StatusOr<void*> Allocate(size_t n) = 0;
};

}  // namespace arch

#endif
