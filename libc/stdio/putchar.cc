#include "libc/stdio/putchar.h"

#include "kernel/arch/tty.h"

namespace libc {

int putchar(int ic) {
  char c = static_cast<char>(ic);
  arch::terminal_write(&c, sizeof(c));
  return ic;
}

} // namespace libc
