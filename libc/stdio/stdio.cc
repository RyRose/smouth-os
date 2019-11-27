#include "libc/stdio.h"
#include "libc/kernel.h"

namespace libc {

util::StatusOr<int> puts(const char* string) { return printf("%s\n", string); }

util::Status putchar(int ic) {
  RET_CHECK(kernel_put != nullptr, "kernel_put API null.");
  return kernel_put(static_cast<char>(ic));
}

}  // namespace libc
