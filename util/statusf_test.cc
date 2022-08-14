#include "util/statusf.h"

#include "gtest/gtest.h"
#include "testing/assert.h"

namespace util {

TEST(Status, TestNoFormat) {
  Statusf status(ErrorCode::INTERNAL, "foo");
  EXPECT_EQ(ErrorCode::INTERNAL, status.Code());
  EXPECT_EQ("foo", std::string(status.Message()));
}

TEST(Status, TestFormat) {
  Statusf status(ErrorCode::INTERNAL, "%s", "foo");
  EXPECT_EQ(ErrorCode::INTERNAL, status.Code());
  EXPECT_EQ("foo", std::string(status.Message()));
}

TEST(Status, TestInvalidation) {
  Statusf status(ErrorCode::INTERNAL, "%s", "foo");
  EXPECT_EQ("foo", std::string(status.Message()));
  Statusf status_overwrite(ErrorCode::INTERNAL, "%s", "bar");
  EXPECT_EQ("%s", std::string(status.Message()));
  EXPECT_EQ("bar", std::string(status_overwrite.Message()));
}

}  // namespace util
