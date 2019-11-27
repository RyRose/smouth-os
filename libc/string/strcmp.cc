#include "libc/string.h"

namespace libc {

int strcmp(const char* str1, const char* str2) {
  while (*str1 && *str2 && *str1 != *str2) {
    str1++;
    str2++;
  }
  if (!*str1 && !*str2) {
    return 0;
  }
  return *str1 > *str2 ? 1 : -1;
}

}  // namespace libc
