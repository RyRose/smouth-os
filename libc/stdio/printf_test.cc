#include "libc/stdio/printf.h"

#include "gtest/gtest.h"

TEST(Printf, CharSpaced) {
  testing::internal::CaptureStdout();
  Stdio::printf("%c %c %c %c %c", 'a', 'b', 'c', 'd', 'e');
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("a b c d e", output.c_str());
}

TEST(Printf, CharNumbered){
  testing::internal::CaptureStdout();
  Stdio::printf("%c 1 %c 2 %c 3 %c 4 %c", 'a', 'b', 'c', 'd', 'e');
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("a 1 b 2 c 3 d 4 e", output.c_str());
}

TEST(Printf, Strings) {
  testing::internal::CaptureStdout();
  Stdio::printf("%s test %s", "abc", "def");
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("abc test def", output.c_str());
}

TEST(Printf, Ints) {
  testing::internal::CaptureStdout();
  Stdio::printf("%d test %i", 123214, -12421);
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("123214 test -12421", output.c_str());
}

TEST(Printf, HexInts) {
  testing::internal::CaptureStdout();
  Stdio::printf("%X test %x", 0xABDC1243, 0xAECDB123);
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("ABDC1243 test aecdb123", output.c_str());
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
