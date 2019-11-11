#include "libc/stdio.h"
#include "libc/kernel.h"
#include "libc/mock_kernel.h"

#include "testing/assert.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

using testing::_;
using testing::InSequence;
using testing::Return;

class StdioTest : public ::testing::Test {
 protected:
  StdioTest() { libc::kernel_put = &kernel_; }

  ~StdioTest() override { libc::kernel_put = nullptr; }

  libc::MockKernelPut kernel_;
};

TEST_F(StdioTest, CharSpaced) {
  ON_CALL(kernel_, Put(_)).WillByDefault(Return(util::Status()));

  {
    InSequence s;
    for (const auto c : std::string("a b c d e")) {
      EXPECT_CALL(kernel_, Put(c));
    }
  }

  ASSERT_OK_AND_ASSIGN(const auto length,
                       libc::printf("%c %c %c %c %c", 'a', 'b', 'c', 'd', 'e'));
  EXPECT_EQ(9, length);
}

TEST_F(StdioTest, CharNumbered) {
  {
    InSequence s;
    for (const auto& c : std::string("a 1 b 2 c 3 d 4 e")) {
      EXPECT_CALL(kernel_, Put(c));
    }
  }

  ASSERT_OK_AND_ASSIGN(
      const auto& length,
      libc::printf("%c 1 %c 2 %c 3 %c 4 %c", 'a', 'b', 'c', 'd', 'e'));
  EXPECT_EQ(17, length);
}

TEST_F(StdioTest, Strings) {
  {
    InSequence s;
    for (const auto& c : std::string("abc test def")) {
      EXPECT_CALL(kernel_, Put(c));
    }
  }

  ASSERT_OK_AND_ASSIGN(const auto& length,
                       libc::printf("%s test %s", "abc", "def"));
  EXPECT_EQ(12, length);
}

TEST_F(StdioTest, Ints) {
  {
    InSequence s;
    for (const auto& c : std::string("123214 test -12421")) {
      EXPECT_CALL(kernel_, Put(c));
    }
  }
  ASSERT_OK_AND_ASSIGN(const auto& length,
                       libc::printf("%d test %i", 123214, -12421));
  EXPECT_EQ(18, length);
}

TEST_F(StdioTest, HexInts) {
  {
    InSequence s;
    for (const auto& c : std::string("ABDC1243 test aecdb123")) {
      EXPECT_CALL(kernel_, Put(c));
    }
  }
  ASSERT_OK_AND_ASSIGN(const auto& length,
                       libc::printf("%X test %x", 0xABDC1243, 0xAECDB123));
  EXPECT_EQ(22, length);
}

TEST_F(StdioTest, HexIntsBig) {
  {
    InSequence s;
    for (const auto& c : std::string("ABDC124356789012 test aecdb123")) {
      EXPECT_CALL(kernel_, Put(c));
    }
  }
  ASSERT_OK_AND_ASSIGN(
      const auto& length,
      libc::printf("%X test %x", 0xABDC124356789012, 0xAECDB123));
  EXPECT_EQ(30, length);
}
