#ifndef KERNEL_ARCH_BOOT_H
#define KERNEL_ARCH_BOOT_H

#include <stdint.h>

#include "kernel/arch/common/tty.h"
#include "kernel/arch/memory.h"
#include "kernel/arch/serial.h"

namespace arch {

struct BootInfo {
  BootInfo(Terminal* tty_, SerialPortInterface* com1_, Allocator* allocator_)
      : tty(tty_), com1(com1_), allocator(allocator_) {}

 public:
  Terminal* tty;
  SerialPortInterface* com1;
  Allocator* allocator;
};

}  // namespace arch

#endif
