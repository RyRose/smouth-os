
#include "kernel/arch/i386/boot/dummy_isr.h"

#include "kernel/arch/i386/interrupt/macros.h"

#include "libc/stdio.h"

namespace arch_internal {

extern "C" void dummy_handler() { libc::puts("dummy handler works!"); }

extern "C" void handleDummyInterrupt();

INTERRUPT_SERVICE_ROUTINE(handleDummyInterrupt, dummy_handler)

}  // namespace arch_internal
