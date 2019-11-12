#include "kernel/arch/i386/init/dummy_isr.h"

#include "kernel/arch/i386/interrupt/macros.h"

#include "libc/stdio.h"

namespace arch_internal {

INTERRUPT_SERVICE_ROUTINE(handleDummyInterrupt, {
  libc::puts("== Handling Dummy Interrupt ==");
  libc::puts("Dummy handler works!");
});

}  // namespace arch_internal
