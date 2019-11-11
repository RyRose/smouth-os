#include <stdint.h>

#include "libc/string.h"

namespace libc {

util::Status memmove(void* dstptr, const void* srcptr, size_t size) {
  RET_CHECK(dstptr != nullptr);
  RET_CHECK(srcptr != nullptr);
  auto* dst = static_cast<uint8_t*>(dstptr);
  const auto* src = static_cast<const uint8_t*>(srcptr);
  if (dst < src) {
    for (size_t i = 0; i < size; i++) dst[i] = src[i];
  } else {
    for (size_t i = size; i != 0; i--) dst[i - 1] = src[i - 1];
  }
  return {};
}

}  // namespace libc
