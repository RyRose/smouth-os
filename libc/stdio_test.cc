#include "libc/stdio.h"

#include <memory>

#include "gtest/gtest.h"
#include "libc/kernel.h"
#include "testing/assert.h"

namespace {
std::unique_ptr<std::string> kernel_cache;
}

class StdioTest : public ::testing::Test {
 protected:
  StdioTest() {
    kernel_cache = std::unique_ptr<std::string>(new std::string);
    libc::kernel_put = [](char c) -> util::Status {
      kernel_cache->push_back(c);
      return {};
    };
  }

  ~StdioTest() override {
    kernel_cache = nullptr;
    libc::kernel_put = nullptr;
  }
};

TEST_F(StdioTest, CharSpaced) {
  ASSERT_OK_AND_ASSIGN(const auto length,
                       libc::printf("%c %c %c %c %c", 'a', 'b', 'c', 'd', 'e'));
  EXPECT_EQ("a b c d e", *kernel_cache);
  EXPECT_EQ(9, length);
}

TEST_F(StdioTest, CharNumbered) {
  ASSERT_OK_AND_ASSIGN(
      const auto& length,
      libc::printf("%c 1 %c 2 %c 3 %c 4 %c", 'a', 'b', 'c', 'd', 'e'));
  EXPECT_EQ("a 1 b 2 c 3 d 4 e", *kernel_cache);
  EXPECT_EQ(17, length);
}

TEST_F(StdioTest, Strings) {
  ASSERT_OK_AND_ASSIGN(const auto& length,
                       libc::printf("%s test %s", "abc", "def"));
  EXPECT_EQ("abc test def", *kernel_cache);
  EXPECT_EQ(12, length);
}

TEST_F(StdioTest, Ints) {
  ASSERT_OK_AND_ASSIGN(const auto& length,
                       libc::printf("%d test %i", 123214, -12421));
  EXPECT_EQ("123214 test -12421", *kernel_cache);
  EXPECT_EQ(18, length);
}

TEST_F(StdioTest, HexInts) {
  ASSERT_OK_AND_ASSIGN(const auto& length,
                       libc::printf("%X test %x", 0xABDC1243, 0xAECDB123));
  EXPECT_EQ("ABDC1243 test aecdb123", *kernel_cache);
  EXPECT_EQ(22, length);
}

TEST_F(StdioTest, HexIntsBig) {
  ASSERT_OK_AND_ASSIGN(
      const auto& length,
      libc::printf("%X test %x", 0xABDC124356789012, 0xAECDB123));
  EXPECT_EQ("ABDC124356789012 test aecdb123", *kernel_cache);
  EXPECT_EQ(30, length);
}

TEST_F(StdioTest, EscapeQuotes) {
  ASSERT_OK_AND_ASSIGN(const auto& length, libc::printf("a %q e", "b \"c\" d"));
  EXPECT_EQ("a \"b \\\"c\\\" d\" e", *kernel_cache);
  EXPECT_EQ(15, length);
}

TEST_F(StdioTest, Sprintf) {
  char actual[100];
  ASSERT_OK_AND_ASSIGN(const auto& length, libc::sprintf(actual, "test"));
  const char* expected = "test";
  for (int i = 0; i < 5; i++) {
    EXPECT_EQ(expected[i], actual[i]);
  }
  EXPECT_EQ(5, length);
}

TEST_F(StdioTest, Snprintf) {
  char actual[4];
  ASSERT_OK_AND_ASSIGN(const auto& length,
                       libc::snprintf(actual, 4, "test %s", "foo"));
  const char* expected = "tes";
  for (int i = 0; i < 4; i++) {
    EXPECT_EQ(expected[i], actual[i]);
  }
  EXPECT_EQ(4, length);
}

TEST_F(StdioTest, Asprintf) {
  char* actual;
  ASSERT_OK_AND_ASSIGN(const auto& length,
                       libc::asprintf(&actual, "test %s", "foo"));
  const char* expected = "test foo";
  for (int i = 0; i < 9; i++) {
    EXPECT_EQ(expected[i], actual[i]);
  }
  EXPECT_EQ(9, length);
}
