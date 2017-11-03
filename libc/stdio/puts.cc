#include "libc/stdio/puts.h"

#include "libc/stdio/printf.h"

namespace stdio {

int puts(const char* string) {
  return printf("%s\n", string);
}

}
