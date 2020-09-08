#ifndef KERNEL_CORE_INIT_H
#define KERNEL_CORE_INIT_H

#include "kernel/arch/init.h"
#include "util/status.h"

namespace kernel {

util::Status Initialize(const arch::BootInfo& boot_info);

}

#endif  // KERNEL_CORE_INIT_H
