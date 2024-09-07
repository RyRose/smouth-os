#include "libc/kernel.h"
#include "libc/stdlib.h"

namespace libc {

__attribute__((__noreturn__)) void abort() {
  if (kernel_panic) {
    kernel_panic("program aborted");
  }
  while (true) {
  }
  __builtin_unreachable();
}

}  // namespace libc
