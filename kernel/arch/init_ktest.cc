
#include "kernel/arch/init.h"
#include "kernel/testing/macros.h"
#include "libc/stdio.h"
#include "util/check.h"

KERNEL_TEST(Initialize) {
  KERNEL_ASSERT_OK_AND_ASSIGN(const auto& boot, arch::Initialize());
  libc::printf("Boot Info: {tty=0x%p, com1=0x%p, allocator=0x%p}\n", boot.tty,
               boot.com1, boot.allocator);
}
