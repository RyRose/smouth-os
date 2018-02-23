#include "libc/stdlib/arithmetic.h"

namespace libc {

int abs(int n) {
  if (n >= 0) {
    return n;
  } else {
    return -n;
  }
}

} // namespace libc
