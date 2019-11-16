#include "libc/kernel.h"

namespace libc {

util::Status (*kernel_put)(char c) = nullptr;

void (*kernel_panic)(const char* message) = nullptr;

}  // namespace libc