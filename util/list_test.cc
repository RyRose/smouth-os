#include "util/list.h"

#include "testing/assert.h"

#include "gtest/gtest.h"

namespace util {

TEST(List, TestInitial) {
  List<int, 10> list;
  EXPECT_EQ(10, list.Capacity());
  EXPECT_EQ(0, list.Size());
}

TEST(List, TestAdd) {
  List<int, 10> list;
  EXPECT_OK(list.Add(5));
  ASSERT_OK_AND_ASSIGN(const auto& val, list.At(0));
  EXPECT_EQ(5, *val);
}

}  // namespace util
