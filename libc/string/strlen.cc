#include "libc/string.h"

namespace libc {

util::StatusOr<size_t> strlen(const char* str) {
  RET_CHECK(str != nullptr);
  size_t len = 0;
  while (str[len]) len++;
  return len;
}

}  // namespace libc
