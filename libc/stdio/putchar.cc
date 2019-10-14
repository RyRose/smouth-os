#include "libc/stdio/putchar.h"

#include "kernel/arch/serial.h"
#include "kernel/arch/tty.h"

namespace libc {

int putchar(int ic) {
  char c = static_cast<char>(ic);
  arch::TTY.Write(&c, sizeof(c));
  arch::COM1.Write(static_cast<uint8_t>(ic));
  return ic;
}

} // namespace libc
