#include "util/list.h"

#include "testing/assert.h"

#include "gtest/gtest.h"

namespace util {

TEST(List, TestInitial) {
  List<int, 10> list;
  EXPECT_EQ(10, list.Capacity());
  EXPECT_EQ(0, list.Size());
}

TEST(List, TestSingleAdd) {
  List<int, 10> list;
  EXPECT_OK(list.Add(5));
  ASSERT_OK_AND_ASSIGN(const auto* val, list.At(0));
  EXPECT_EQ(5, *val);
}

TEST(List, TestAddOverflow) {
  List<int, 10> list;
  for (size_t i = 0; i < list.Capacity(); i++) {
    EXPECT_OK(list.Add(i));
    ASSERT_OK_AND_ASSIGN(const auto* val, list.At(i));
    EXPECT_EQ(i, *val);
  }
  EXPECT_NOT_OK(list.Add(100));
}

TEST(List, TestSingleInsertFront) {
  List<int, 10> list;
  EXPECT_OK(list.Insert(0, 5));
  EXPECT_EQ(1, list.Size());
  ASSERT_OK_AND_ASSIGN(const auto* val, list.At(0));
  EXPECT_EQ(5, *val);
}

TEST(List, TestSingleInsertNotFront) {
  List<int, 10> list;
  EXPECT_OK(list.Insert(5, 5));
  EXPECT_EQ(6, list.Size());
  ASSERT_OK_AND_ASSIGN(const auto* val, list.At(5));
  EXPECT_EQ(5, *val);
}

TEST(List, TestInsertShift) {
  List<int, 10> list;
  for (size_t i = 0; i < 8; i++) {
    ASSERT_OK(list.Add(i));
  }
  EXPECT_OK(list.Insert(4, 100));
  EXPECT_EQ(9, list.Size());
  int j = 0;
  for (const auto& i : {0, 1, 2, 3, 100, 4, 5, 6, 7}) {
    ASSERT_OK_AND_ASSIGN(const auto* val, list.At(j));
    EXPECT_EQ(i, *val);
    j++;
  }
}

TEST(List, TestInsertOverflow) {
  List<int, 10> list;
  for (size_t i = 0; i < list.Capacity(); i++) {
    EXPECT_OK(list.Add(i));
  }
  EXPECT_EQ(10, list.Size());
  EXPECT_NOT_OK(list.Insert(3, 131));
}

TEST(List, TestInsertBadIndex) {
  List<int, 10> list;
  EXPECT_NOT_OK(list.Insert(-1, 100));
  EXPECT_NOT_OK(list.Insert(100, 100));
}

TEST(List, TestSet) {
  List<int, 10> list;
  for (size_t i = 0; i < list.Capacity(); i++) {
    ASSERT_OK(list.Add(i));
  }
  EXPECT_OK(list.Set(7, 1312));
}

TEST(List, TestSetBadIndex) {
  List<int, 10> list;
  EXPECT_NOT_OK(list.Set(-1, 100));
  EXPECT_NOT_OK(list.Set(100, 100));
}

}  // namespace util
