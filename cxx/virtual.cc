#include "cxx/virtual.h"

#include "cxx/kernel.h"

void __cxa_pure_virtual() {
  if (cxx::kernel_panic != nullptr) {
    cxx::kernel_panic("__cxa_pure_virtual called.");
  }
  // Fall back to infinite while loop if kernel panic unavailable or fails.
  while (true) {
  }
}
