#ifndef CXX_KERNEL_H
#define CXX_KERNEL_H

#include <stddef.h>

#include "util/status.h"

namespace cxx {

extern util::StatusOr<void*> (*kernel_new)(size_t n);

extern void (*kernel_panic)(const char* message);

// Attempts to use the cxx::kernel_panic and if unavailable, loops forever.
void __attribute__((noreturn)) KernelPanic(const char* message);

}  // namespace cxx

#endif  // CXX_KERNEL_H
