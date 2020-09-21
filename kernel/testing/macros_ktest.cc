
#include "kernel/testing/macros.h"
#include "util/status.h"

static util::Status Success() { return {}; }

static util::StatusOr<int> SuccessInt() { return 10; }

KERNEL_TEST(TestMacros) {
  KERNEL_EXPECT(true);
  KERNEL_EXPECT(true, "must be true");
  KERNEL_EXPECT_OK(Success());
  KERNEL_EXPECT_OK(Success(), "success must succeed");
  KERNEL_ASSERT(2 < 4);
  KERNEL_ASSERT(2 < 4, "two must be less than four");
  KERNEL_ASSERT_OK(Success());
  KERNEL_ASSERT_OK(Success(), "success must succeed");
  KERNEL_ASSERT_OK_AND_ASSIGN(const auto& result, SuccessInt());
  KERNEL_ASSERT(result == 10);
}
