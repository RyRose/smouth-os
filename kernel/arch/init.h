#ifndef KERNEL_ARCH_INIT_H
#define KERNEL_ARCH_INIT_H

#include <stdint.h>

#include "kernel/arch/common/memory.h"
#include "kernel/arch/common/serial.h"
#include "kernel/arch/common/tty.h"
#include "util/list.h"
#include "util/status.h"

namespace arch {

struct BootInfo {
  Terminal* tty;
  SerialPortInterface* com1;
  util::List<MemoryRegion, 100> memory_regions;
};

// Do architecture-specific initialization before entering the main kernel.
util::StatusOr<BootInfo> Initialize();

}  // namespace arch

#endif
