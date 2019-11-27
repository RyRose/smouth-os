#include "libc/string.h"

namespace libc {

const char* strchr(const char* s, char c) {
  while (*s && *s != c) {
    s++;
  }
  return s;
}

}  // namespace libc
