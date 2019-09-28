
#include "kernel/arch/i386/interrupt/macros.h"
#include "libc/stdio/printf.h"

namespace dummy_isr {

extern "C" void dummy_handler() { libc::printf("dummy handler works!\n"); }
extern "C" void handleDummyInterrupt();

INTERRUPT_SERVICE_ROUTINE(handleDummyInterrupt, dummy_handler)

} // namespace dummy_isr
