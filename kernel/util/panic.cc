#include "kernel/util/panic.h"
#include "libc/stdio/printf.h"

namespace util {

__attribute__((noreturn)) void panic(const char *message) {
  libc::printf("The kernel has panicked!\n");
  libc::printf("Message: %s\n", message);
  while (true) {
  }
  __builtin_unreachable();
}
} //  namespace util
