#include "libc/stdio.h"

#include "kernel/arch/boot.h"

namespace {

extern "C" void kernel_main(arch::BootInfo* boot) {
  libc::puts("== Kernel Main ==");
  libc::printf("Boot Info: {address=0x%p, com1=0x%p, allocator=0x%p}\n",
               boot->allocator, boot->com1, boot->allocator);
}

}  // namespace
