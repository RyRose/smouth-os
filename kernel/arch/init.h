#ifndef KERNEL_ARCH_INIT_H
#define KERNEL_ARCH_INIT_H

#include <stdint.h>

#include "kernel/arch/common/tty.h"
#include "kernel/arch/memory.h"
#include "kernel/arch/serial.h"
#include "util/status.h"

namespace arch {

struct BootInfo {
  BootInfo(Terminal* tty_, SerialPortInterface* com1_, Allocator* allocator_)
      : tty(tty_), com1(com1_), allocator(allocator_) {}

 public:
  Terminal* tty;
  SerialPortInterface* com1;
  Allocator* allocator;
};

// Do architecture-specific initialization before entering the main kernel.
util::StatusOr<BootInfo> Initialize();

}  // namespace arch

#endif
