#include <stdint.h>

#include "libc/string.h"

namespace libc {

util::Status memset(void* bufptr, int value, size_t size) {
  RET_CHECK(bufptr != nullptr);
  auto* buf = static_cast<uint8_t*>(bufptr);
  for (size_t i = 0; i < size; i++) buf[i] = static_cast<uint8_t>(value);
  return {};
}

}  // namespace libc
