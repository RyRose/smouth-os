#include "kernel/util/status.h"

#include "gtest/gtest.h"

namespace util {

TEST(Status, TestDefaultConstructor) {
  Status status;
  EXPECT_EQ(ErrorCode::OK, status.GetCode());
}

TEST(Status, TestExplicitConstructor) {
  Status status(ErrorCode::OK);
  EXPECT_TRUE(status.ok());
}

TEST(StatusOr, TestErrorCode) {
  StatusOr<int> status_or = ErrorCode::UNKNOWN;
  EXPECT_FALSE(status_or.ok());
  EXPECT_EQ(ErrorCode::UNKNOWN, status_or.status().GetCode());
}

TEST(StatusOr, TestStatus) {
  StatusOr<int> status_or = Status();
  EXPECT_FALSE(status_or.ok());
  EXPECT_EQ(ErrorCode::OK, status_or.status().GetCode());
}

TEST(StatusOr, TestValue) {
  StatusOr<int> status_or = 0;
  EXPECT_TRUE(status_or.ok());
  EXPECT_EQ(0, status_or.value());
}

}  // namespace util

int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
