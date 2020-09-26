
#include "kernel/arch/init.h"
#include "kernel/core/init.h"
#include "kernel/testing/macros.h"

KERNEL_TEST(TestKernelInitialize) {
  KERNEL_ASSERT_OK_AND_ASSIGN(const auto& boot, arch::Initialize());
  KERNEL_ASSERT_OK(kernel::Initialize(boot));
}
