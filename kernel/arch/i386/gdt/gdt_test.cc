#include "kernel/arch/i386/gdt/gdt.h"

#include "gtest/gtest.h"

namespace gdt {

TEST(Gdt, TestNullDescriptor) {
  Descriptor d;
  EXPECT_EQ(0, *reinterpret_cast<uint64_t *>(&d));
}

TEST(Gdt, TestCodeDescriptor) {
  Descriptor d(/*base=*/0, /*limit=*/0xFFFFFFFF, /*segment_type=*/0xA,
               /*descriptor_type=*/true, /*dpl=*/0, /*present=*/true,
               /*db=*/true, /*granularity=*/true);
  uint64_t b = *reinterpret_cast<uint64_t *>(&d);
  EXPECT_EQ(0xCF9A000000FFFF, b);
}

TEST(Gdt, TestDataDescriptor) {
  Descriptor d(/*base=*/0, /*limit=*/0xFFFFFFFF, /*segment_type=*/0x2,
               /*descriptor_type=*/true, /*dpl=*/0, /*present=*/true,
               /*db=*/true, /*granularity=*/true);
  uint64_t b = *reinterpret_cast<uint64_t *>(&d);
  EXPECT_EQ(0xCF92000000FFFF, b);
}

}  // namespace gdt

int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
