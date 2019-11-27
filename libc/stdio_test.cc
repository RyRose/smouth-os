#include "libc/stdio.h"
#include "libc/kernel.h"

#include "testing/assert.h"

#include <memory>

#include "gtest/gtest.h"

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
