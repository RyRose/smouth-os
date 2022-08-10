
#include "kernel/arch/init.h"
#include "kernel/testing/macros.h"

namespace {
void __attribute__((noinline)) OverrideStackBuffer() {
  KERNEL_ASSERT_OK(libc::puts("Starting stack overriding."));
  char buffer[40];
  KERNEL_ASSERT_OK(libc::memset(buffer, 'a', 100));
}
}

KERNEL_TEST(TestStackSmashingProtector) {
  KERNEL_ASSERT_OK(arch::Initialize());
  OverrideStackBuffer();
  KERNEL_ASSERT_OK(libc::puts("Stack not smashed."));
  libc::abort();
}