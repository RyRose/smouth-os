#include "libc/stdlib/abort.h"

namespace libc {

__attribute__((__noreturn__))
void abort(void) {
  // TODO: Add proper kernel panic.
  while (true) { }
  __builtin_unreachable();
}

} // namespace libc
