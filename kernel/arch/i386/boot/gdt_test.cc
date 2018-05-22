#include "kernel/arch/i386/boot/gdt.h"

#include "gtest/gtest.h"

namespace boot {

TEST(Gdt, TestNullSelector) {
  SegmentSelector entry(0, 0, 0);
  EXPECT_EQ(0, entry.Get());
}

TEST(Gdt, TestCodeSelector) {
  SegmentSelector entry(0, 0xFFFFFFFF, 0x9A);
  EXPECT_EQ(0x00CF9A000000FFFF, entry.Get());
}

TEST(Gdt, TestDataSelector) {
  SegmentSelector entry(0, 0xFFFFFFFF, 0x92);
  EXPECT_EQ(0x00CF92000000FFFF, entry.Get());
}

} // namespace boot

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
