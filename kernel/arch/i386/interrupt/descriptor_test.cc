#include "kernel/arch/i386/interrupt/descriptor.h"

#include "gtest/gtest.h"

namespace interrupt {

TEST(Descriptor, TestBaseDescriptor) {
  GateDescriptor descriptor(0x23456789, 0x1234, 0x78);
  EXPECT_EQ(0x2345780012346789, descriptor.Get());
}

TEST(Descriptor, TestInterruptGateDescriptor) {
  InterruptGateDescriptor descriptor(0x12345678, 0x1234, 0, true, true);
  EXPECT_EQ(0x12348E0012345678, descriptor.Get());
}

TEST(Descriptor, TestTrapGateDescriptor) {
  TrapGateDescriptor descriptor(0x12345678, 0x1234, 0, true, true);
  EXPECT_EQ(0x12348F0012345678, descriptor.Get());
}

TEST(Descriptor, TestTaskGateDescriptor) {
  TaskGateDescriptor descriptor(0x1234, 0, true);
  EXPECT_EQ(0x850012340000, descriptor.Get());
}

}  // namespace interrupt

int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
