
#include "cxx/kernel.h"

namespace cxx {

util::StatusOr<void*> (*kernel_new)(size_t n) = nullptr;

void (*kernel_panic)(const char* message) = nullptr;

void __attribute__((noreturn)) KernelPanic(const char* message) {
  if (kernel_panic != nullptr) {
    kernel_panic(message);
  }
  // Fall back to infinite loop if kernel panic does not exist or returns.
  while (true) {
  }
}

}  // namespace cxx