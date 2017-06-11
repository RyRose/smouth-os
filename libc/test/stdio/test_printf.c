#include <gtest/gtest.h>

#include "../../stdio/printf.c"

TEST(Printf, ConvertToChar) {
  char letters[] = {'0', '1', '2', '3', '4', '5', '6', '7',
                    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};
  for(int i = 0; i < 16; ++i) {
    ASSERT_EQ(convert_to_char(i), letters[i]);
  }
}

TEST(Printf, Reverse) {
  char even[] = "abcd";
  reverse(even, 4);
  ASSERT_STREQ(even, "dcba") << "even is " << even;

  char odd[] = "abcde";
  reverse(odd, 5);
  ASSERT_STREQ(odd, "edcba") << "odd is " << odd;
}
