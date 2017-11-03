#include "libc/stdlib/arithmetic.h"

namespace stdlib {

int abs(int n) {
  if (n >= 0) {
    return n;
  } else {
    return -n;
  }
}

}
