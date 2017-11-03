#include "libc/stdlib/abort.h"

namespace stdlib {

__attribute__((__noreturn__))
void abort(void) {
  // TODO: Add proper kernel panic.
  while (true) { }
  __builtin_unreachable();
}

}
