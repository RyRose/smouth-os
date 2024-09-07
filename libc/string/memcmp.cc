
#include <stdint.h>

#include "libc/string.h"
#include "util/status.h"

namespace libc {

util::StatusOr<int> memcmp(const void* aptr, const void* bptr, size_t size) {
  RET_CHECK(aptr != nullptr);
  RET_CHECK(bptr != nullptr);
  const auto* a = static_cast<const uint8_t*>(aptr);
  const auto* b = static_cast<const uint8_t*>(bptr);
  for (size_t i = 0; i < size; i++) {
    if (a[i] < b[i])
      return -1;
    else if (b[i] < a[i])
      return 1;
  }
  return 0;
}

}  // namespace libc
