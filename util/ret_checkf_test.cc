
#include "util/ret_checkf.h"

#include "gtest/gtest.h"
#include "testing/assert.h"

namespace util {

namespace {

util::Status eq(int a, int b) {
  RET_CHECKF_EQ(a, b, "%d, %d, %d, %d, %d", 10, 20, 30, 40, 50);
  return {};
}

util::Status ne(int a, int b) {
  RET_CHECKF_NE(a, b, "%d, %d, %d, %d, %d", 10, 20, 30, 40, 50);
  return {};
}

util::Status lt(int a, int b) {
  RET_CHECKF_LT(a, b, "%d, %d, %d, %d, %d", 10, 20, 30, 40, 50);
  return {};
}

util::Status le(int a, int b) {
  RET_CHECKF_LE(a, b, "%d, %d, %d, %d, %d", 10, 20, 30, 40, 50);
  return {};
}

util::Status gt(int a, int b) {
  RET_CHECKF_GT(a, b, "%d, %d, %d, %d, %d", 10, 20, 30, 40, 50);
  return {};
}

util::Status ge(int a, int b) {
  RET_CHECKF_GE(a, b, "%d, %d, %d, %d, %d", 10, 20, 30, 40, 50);
  return {};
}

util::Status check(bool condition) {
  RET_CHECKF(condition, "%d, %d, %d, %d, %d", 10, 20, 30, 40, 50);
  return {};
}

util::Status eqEmpty(int a, int b) {
  RET_CHECKF_EQ(a, b);
  return {};
}

util::Status neEmpty(int a, int b) {
  RET_CHECKF_NE(a, b);
  return {};
}

util::Status ltEmpty(int a, int b) {
  RET_CHECKF_LT(a, b);
  return {};
}

util::Status leEmpty(int a, int b) {
  RET_CHECKF_LE(a, b);
  return {};
}

util::Status gtEmpty(int a, int b) {
  RET_CHECKF_GT(a, b);
  return {};
}

util::Status geEmpty(int a, int b) {
  RET_CHECKF_GE(a, b);
  return {};
}

util::Status checkEmpty(bool condition) {
  RET_CHECKF(condition);
  return {};
}

}  // namespace

TEST(RetCheckF, Equals) {
  EXPECT_OK(eq(10, 10));
  const util::Status actual = eq(5, 10);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:12: a == b: '5 == 10' not true: 10, 20, 30, 40, "
      "50",
      actual.Message());
}

TEST(RetCheckF, EqualsEmpty) {
  EXPECT_OK(eqEmpty(10, 10));
  const util::Status actual = eqEmpty(5, 10);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:47: a == b: '5 == 10' not true: INTERNAL",
      actual.Message());
}

TEST(RetCheckF, NotEquals) {
  EXPECT_OK(ne(5, 10));
  const util::Status actual = ne(10, 10);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:17: a != b: '10 != 10' not true: 10, 20, 30, "
      "40, 50",
      actual.Message());
}

TEST(RetCheckF, NotEqualsEmpty) {
  EXPECT_OK(neEmpty(5, 10));
  const util::Status actual = neEmpty(10, 10);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:52: a != b: '10 != 10' not true: INTERNAL",
      actual.Message());
}

TEST(RetCheckF, LessThan) {
  EXPECT_OK(lt(5, 10));
  const util::Status actual = lt(15, 10);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:22: a < b: '15 < 10' not true: 10, 20, 30, 40, "
      "50",
      actual.Message());
}

TEST(RetCheckF, LessThanEmpty) {
  EXPECT_OK(ltEmpty(5, 10));
  const util::Status actual = ltEmpty(15, 10);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:57: a < b: '15 < 10' not true: INTERNAL",
      actual.Message());
}

TEST(RetCheckF, LessThanEquals) {
  EXPECT_OK(le(5, 10));
  EXPECT_OK(le(10, 10));
  const util::Status actual = le(15, 10);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:27: a <= b: '15 <= 10' not true: 10, 20, 30, "
      "40, 50",
      actual.Message());
}

TEST(RetCheckF, LessThanEqualsEmpty) {
  EXPECT_OK(leEmpty(5, 10));
  EXPECT_OK(leEmpty(10, 10));
  const util::Status actual = leEmpty(15, 10);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:62: a <= b: '15 <= 10' not true: INTERNAL",
      actual.Message());
}

TEST(RetCheckF, GreaterThan) {
  EXPECT_OK(gt(10, 5));
  const util::Status actual = gt(10, 15);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:32: a > b: '10 > 15' not true: 10, 20, 30, 40, "
      "50",
      actual.Message());
}

TEST(RetCheckF, GreaterThanEmpty) {
  EXPECT_OK(gtEmpty(10, 5));
  const util::Status actual = gtEmpty(10, 15);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:67: a > b: '10 > 15' not true: INTERNAL",
      actual.Message());
}

TEST(RetCheckF, GreaterThanEquals) {
  EXPECT_OK(ge(10, 5));
  EXPECT_OK(ge(10, 10));
  const util::Status actual = ge(10, 15);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:37: a >= b: '10 >= 15' not true: 10, 20, 30, "
      "40, 50",
      actual.Message());
}

TEST(RetCheckF, GreaterThanEqualsEmpty) {
  EXPECT_OK(geEmpty(10, 5));
  EXPECT_OK(geEmpty(10, 10));
  const util::Status actual = geEmpty(10, 15);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ(
      "util/ret_checkf_test.cc:72: a >= b: '10 >= 15' not true: INTERNAL",
      actual.Message());
}

TEST(RetCheckF, Check) {
  EXPECT_OK(check(true));
  const util::Status actual = check(false);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ("util/ret_checkf_test.cc:42: condition: 10, 20, 30, 40, 50",
               actual.Message());
}

TEST(RetCheckF, CheckEmpty) {
  EXPECT_OK(checkEmpty(true));
  const util::Status actual = checkEmpty(false);
  ASSERT_NOT_OK(actual);
  EXPECT_STREQ("util/ret_checkf_test.cc:77: 'condition' not true",
               actual.Message());
}

}  // namespace util
