#include "libc/stdlib/arithmetic.h"

int abs(int n) {
  if (n >= 0) {
    return n;
  } else {
    return -n;
  }
}
