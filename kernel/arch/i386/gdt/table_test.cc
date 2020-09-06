#include "kernel/arch/i386/gdt/table.h"

#include "gtest/gtest.h"
#include "testing/assert.h"

namespace arch {

TEST(Descriptor, TestNullDescriptor) {
  Descriptor d = Descriptor();
  EXPECT_EQ(0, *reinterpret_cast<uint64_t*>(&d));
}

TEST(Descriptor, TestCodeDescriptor) {
  ASSERT_OK_AND_ASSIGN(
      Descriptor d,
      Descriptor::Create(/*base=*/0, /*limit=*/0xFFFFF, /*segment_type=*/0xA,
                         /*descriptor_type=*/true, /*dpl=*/0,
                         /*db=*/true, /*granularity=*/true));
  uint64_t b = *reinterpret_cast<uint64_t*>(&d);
  EXPECT_EQ(0xCF9A000000FFFF, b);
}

TEST(Descriptor, TestDataDescriptor) {
  ASSERT_OK_AND_ASSIGN(
      Descriptor d,
      Descriptor::Create(/*base=*/0, /*limit=*/0xFFFFF, /*segment_type=*/0x2,
                         /*descriptor_type=*/true, /*dpl=*/0,
                         /*db=*/true, /*granularity=*/true));
  uint64_t b = *reinterpret_cast<uint64_t*>(&d);
  EXPECT_EQ(0xCF92000000FFFF, b);
}

}  // namespace arch
