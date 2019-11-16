#include "libc/kernel.h"
#include "libc/stdio.h"

namespace libc {

util::Status putchar(int ic) {
  RET_CHECK(kernel_put != nullptr, "kernel_put API null.");
  return kernel_put(static_cast<char>(ic));
}

}  // namespace libc
