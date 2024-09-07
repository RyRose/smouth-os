#include "testing/assert.h"

#include "gtest/gtest.h"
#include "util/status.h"

namespace testing {

TEST(Assert, TestAssert) {
  ASSERT_NOT_OK(util::Status(util::ErrorCode::INTERNAL));
  ASSERT_OK(util::Status());
}

TEST(Assert, TestExpect) {
  EXPECT_NOT_OK(util::Status(util::ErrorCode::INTERNAL));
  EXPECT_OK(util::Status());
}

TEST(Assert, AssertOkAndAssign) {
  ASSERT_OK_AND_ASSIGN(const auto& value, util::StatusOr<int>(100));
  EXPECT_EQ(100, value);
}

}  // namespace testing
