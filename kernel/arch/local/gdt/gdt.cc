#include "kernel/arch/gdt.h"

#include <stdint.h>

namespace arch {

// Gdt already installed.
uint64_t installGdt() {
  return 0;
}

}
