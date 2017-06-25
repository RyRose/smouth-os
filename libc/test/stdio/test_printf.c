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
    ASSERT_STREQ(convert_to_string_unsigned(i, 16, true), test);
  }

  for(int i = 0; i < 0xFFFF; i++) {
    sprintf(test, "%x", i);
    ASSERT_STREQ(convert_to_string_unsigned(i, 16, false), test);
  }
}

TEST(Printf, ConvertStringOctal) {
  char test[20];
  for(int i = 0; i < 07777; i++) {
    sprintf(test, "%o", i);
    ASSERT_STREQ(convert_to_string_unsigned(i, 8, true), test);
  }
}

TEST(Printf, ConvertStringUnsignedInt) {
  char test[20];
  for(int i = 0; i < 9999; i++) {
    sprintf(test, "%u", i);
    ASSERT_STREQ(convert_to_string_unsigned(i, 10, true), test);
  }
}

TEST(Printf, ConvertStringSignedInt) {
  char test[20];
  for(int i = -9999; i < 9999; i++) {
    sprintf(test, "%d", i);
    ASSERT_STREQ(convert_to_string_signed(i, 10, true), test); 
  }
}
