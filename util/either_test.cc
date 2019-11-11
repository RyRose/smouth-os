#include "util/either.h"

#include "gtest/gtest.h"

namespace util {

TEST(Either, TestLeft) {
  Either<int, const char*> either = 10;
  EXPECT_TRUE(either.is_left);
  EXPECT_EQ(10, either.left);
}

TEST(Either, TestRight) {
  Either<int, const char*> either = "abc";
  EXPECT_FALSE(either.is_left);
  EXPECT_EQ("abc", either.right);
}

}  // namespace util
