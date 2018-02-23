#include "libc/stdio/puts.h"

#include "libc/stdio/printf.h"

namespace libc {

int puts(const char* string) {
  return printf("%s\n", string);
}

} // namespace libc

