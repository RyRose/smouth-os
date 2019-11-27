#include "libc/string.h"

namespace libc {

util::StatusOr<const char*> strchr(const char* s, char c) {
  RET_CHECK(s != nullptr);
  while (*s && *s != c) {
    s++;
  }
  return *s == c ? s : nullptr;
}

}  // namespace libc
