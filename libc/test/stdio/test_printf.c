#include <limits.h>
#include <stdio.h>

#include <gtest/gtest.h>

#include "../../stdio/printf.c"

TEST(Printf, Swap) {
  char test[] = "test";
  swap(test, 1, 2);
  ASSERT_STREQ(test, "tset");
}

TEST(Printf, Reverse) {
  char even[] = "abcd";
  reverse(even, 0, 4);
  ASSERT_STREQ(even, "dcba") << "even is " << even;

  char odd[] = "abcde";
  reverse(odd, 0, 5);
  ASSERT_STREQ(odd, "edcba") << "odd is " << odd;
}

TEST(Printf, ConvertToCharUpper) {
  char letters[] = {'0', '1', '2', '3', '4', '5', '6', '7',
                    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};
  for(int i = 0; i < 16; ++i) {
    ASSERT_EQ(convert_to_char(i, true), letters[i]);
  }
}

TEST(Printf, ConvertToCharLower) {
  char letters[] = {'0', '1', '2', '3', '4', '5', '6', '7',
                    '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
  for(int i = 0; i < 16; ++i) {
    ASSERT_EQ(convert_to_char(i, false), letters[i]);
  }
}

TEST(Printf, ConvertStringHex) {
  char test[20];
  for(int i = 0; i < 0xFFFF; i++) {
    sprintf(test, "%X", i);
    ASSERT_STREQ(convert_to_string(i, 16, false, true), test);
  }

  for(size_t i = ULONG_MAX; i > ULONG_MAX - 0xFFFF; --i) {
    sprintf(test, "%lX", i);
    ASSERT_STREQ(convert_to_string(i, 16, false, true), test);
  }

  for(int i = 0; i < 0xFFFF; i++) {
    sprintf(test, "%x", i);
    ASSERT_STREQ(convert_to_string(i, 16, false, false), test);
  }

  for(size_t i = ULONG_MAX; i > ULONG_MAX - 0xFFFF; --i) {
    sprintf(test, "%lx", i);
    ASSERT_STREQ(convert_to_string(i, 16, false, false), test);
  }
}

TEST(Printf, ConvertStringOctal) {
  char test[20];
  for(size_t i = 0; i < 0xFFFF; ++i) {
    sprintf(test, "%llo", i);
    ASSERT_STREQ(convert_to_string(i, 8, false, true), test);
  }

  for(size_t i = ULONG_MAX - 1; i > ULONG_MAX - 0xFFFF; --i) {
    sprintf(test, "%llo", i);
    ASSERT_STREQ(convert_to_string(i, 8, false, true), test);
  }
}

TEST(Printf, ConvertStringDecimal) {
  char test[20];

  for(size_t i = 0; i < 0xFFFF; ++i) {
    sprintf(test, "%lu", i);
    ASSERT_STREQ(convert_to_string(i, 10, false, true), test);
  }

  for(int i = -9999; i < 9999; i++) {
    sprintf(test, "%d", i);
    ASSERT_STREQ(convert_to_string(abs(i), 10, i < 0, true), test); 
    sprintf(test, "%i", i);
    ASSERT_STREQ(convert_to_string(abs(i), 10, i < 0, true), test); 
  }

  int a = abs(-100);

  for(size_t i = ULONG_MAX- 1; i > ULONG_MAX - 0xFFFF; --i) {
    sprintf(test, "%lu", i);
    ASSERT_STREQ(convert_to_string(i, 10, i < 0, true), test);
  }
}

TEST(Printf, Printf_char1) {
  testing::internal::CaptureStdout();
  printf("%c %c %c %c %c", 'a', 'b', 'c', 'd', 'e');
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("a b c d e", output.c_str());
}

TEST(Printf, Printf_char2) {
  testing::internal::CaptureStdout();
  printf("%c 1 %c 2 %c 3 %c 4 %c", 'a', 'b', 'c', 'd', 'e');
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("a 1 b 2 c 3 d 4 e", output.c_str());
}

TEST(Printf, Printf_string) {
  testing::internal::CaptureStdout();
  printf("%s test %s", "abc", "def");
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("abc test def", output.c_str());
}

TEST(Printf, Printf_int) {
  testing::internal::CaptureStdout();
  printf("%d test %i", 123214, -12421);
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("123214 test -12421", output.c_str());
}

TEST(Printf, Printf_hex) {
  testing::internal::CaptureStdout();
  printf("%X test %x", 0xABDC1243, 0xAECDB123);
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("ABDC1243 test aecdb123", output.c_str());
}

TEST(Printf, Printf_invalid_flag) {
  testing::internal::CaptureStdout();
  printf("%z test %x", 0xABDC1243, 0xAECDB123);
  std::string output = testing::internal::GetCapturedStdout();
  ASSERT_STREQ("%z test %x", output.c_str());
}
