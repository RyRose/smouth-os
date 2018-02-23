#ifndef KERNEL_ARCH_GDT_H
#define KERNEL_ARCH_GDT_H

#include <stdint.h>

namespace arch {

uint64_t installGdt();

} // namespace arch

#endif
