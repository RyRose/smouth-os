#include "libc/stdio.h"

#include "libc/stdlib.h"

#include "kernel/arch/boot.h"
#include "util/check.h"

namespace {

extern "C" void KernelMain(arch::BootInfo* boot) {
  CHECK(boot);
  libc::puts("== Kernel Main ==");
  libc::printf("Boot Info: {address=0x%p, com1=0x%p, allocator=0x%p}\n",
               boot->allocator, boot->com1, boot->allocator);
  libc::abort();
}

}  // namespace
