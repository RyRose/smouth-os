#include "kernel/arch/init.h"
#include "libc/stdio.h"
#include "libc/stdlib.h"
#include "util/check.h"

extern "C" void KernelMain() {
  CHECK_OR_RETURN(const auto& boot, arch::Initialize());
  libc::puts("== Kernel Test ==");
  libc::printf("Boot Info: {tty=0x%p, com1=0x%p, allocator=0x%p}\n", boot.tty,
               boot.com1, boot.allocator);
  libc::puts("<<KERNEL TEST COMPLETE>>");
  libc::abort();
}