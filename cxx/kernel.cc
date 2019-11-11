
#include "cxx/kernel.h"

namespace cxx {

util::StatusOr<void*> (*kernel_new)(size_t n) = nullptr;

void (*kernel_panic)(const char* message) = nullptr;

}  // namespace cxx