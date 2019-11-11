#include <stdint.h>

#include "libc/string.h"
#include "util/status.h"

namespace libc {

util::Status memcpy(void* dstptr, const void* srcptr, size_t size) {
  RET_CHECK(dstptr != nullptr);
  RET_CHECK(srcptr != nullptr);
  auto* dst = static_cast<uint8_t*>(dstptr);
  const auto* src = static_cast<const uint8_t*>(srcptr);
  for (size_t i = 0; i < size; i++) dst[i] = src[i];
  return {};
}

}  // namespace libc
