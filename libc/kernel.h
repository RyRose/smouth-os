#ifndef LIBC_KERNEL_H
#define LIBC_KERNEL_H

#include "util/status.h"

namespace libc {

extern util::Status (*kernel_put)(char c);

extern void (*kernel_panic)(const char* message);

}  // namespace libc

#endif  // LIBC_KERNEL_H
