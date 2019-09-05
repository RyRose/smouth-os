#include "kernel/arch/i386/interrupt/descriptor.h"

#include "gtest/gtest.h"

namespace interrupt {

TEST(Descriptor, TestDefaultGateDescriptor) {
  GateDescriptor descriptor;
  EXPECT_EQ(0, *reinterpret_cast<uint64_t *>(&descriptor));
}

TEST(Descriptor, TestInterruptGateDescriptor) {
  GateDescriptor descriptor(0x12345678, 0x1234, GateType::INTERRUPT_32BIT, 0,
                            true);
  EXPECT_EQ(0x12348E0012345678, *reinterpret_cast<uint64_t *>(&descriptor));
}

TEST(Descriptor, TestTrapGateDescriptor) {
  GateDescriptor descriptor(0x12345678, 0x1234, GateType::TRAP_32BIT, 0, true);
  EXPECT_EQ(0x12348F0012345678, *reinterpret_cast<uint64_t *>(&descriptor));
}

TEST(Descriptor, TestTaskGateDescriptor) {
  GateDescriptor descriptor(0, 0x1234, GateType::TASK, 0, true);
  EXPECT_EQ(0x850012340000, *reinterpret_cast<uint64_t *>(&descriptor));
}

} // namespace interrupt

int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
