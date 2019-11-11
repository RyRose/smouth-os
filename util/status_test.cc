#include "util/status.h"

#include "gtest/gtest.h"
#include "testing/assert.h"

namespace util {

namespace {

util::StatusOr<int> asPositive(int a) {
  RET_CHECK(a < 0, "a must be negative");
  return -a;
}

util::StatusOr<int> negativePlusFive(int a) {
  ASSIGN_OR_RETURN(const auto& pos, asPositive(a));
  return pos + 5;
}

util::Status checkPositive(int a) {
  RET_CHECK(a > 0, "a must be positive");
  return {};
}

util::Status checkPositiveWrapped(int a) {
  RETURN_IF_ERROR(checkPositive(a));
  return {};
}

}

TEST(Status, TestDefaultConstructor) {
  Status status;
  EXPECT_EQ(ErrorCode::OK, status.Code());
}

TEST(Status, TestExplicitConstructor) {
  Status status(ErrorCode::OK);
  EXPECT_TRUE(status.Ok());
}

TEST(StatusOr, TestErrorCode) {
  StatusOr<int> status_or = ErrorCode::UNKNOWN;
  EXPECT_FALSE(status_or.Ok());
  EXPECT_EQ(ErrorCode::UNKNOWN, status_or.Status().Code());
}

TEST(StatusOr, TestStatus) {
  StatusOr<int> status_or = Status();
  EXPECT_FALSE(status_or.Ok());
  EXPECT_EQ(ErrorCode::OK, status_or.Status().Code());
}

TEST(StatusOr, TestValue) {
  StatusOr<int> status_or = 0;
  EXPECT_TRUE(status_or.Ok());
  EXPECT_EQ(0, status_or.Value());
}

TEST(Macros, RetCheck) {
  EXPECT_FALSE(checkPositive(-10).Ok());
  EXPECT_TRUE(checkPositive(10).Ok());
}

TEST(Macros, ReturnIfError) {
  EXPECT_FALSE(checkPositiveWrapped(-10).Ok());
  EXPECT_TRUE(checkPositiveWrapped(10).Ok());
}

TEST(Macros, AssignOrReturn) {
  EXPECT_FALSE(negativePlusFive(10).Ok());
  EXPECT_TRUE(negativePlusFive(-10).Ok());
  ASSERT_OK_AND_ASSIGN(const auto& value, negativePlusFive(-10));
  EXPECT_EQ(15, value);
}

}  // namespace util
