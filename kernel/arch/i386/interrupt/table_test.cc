#include "kernel/arch/i386/interrupt/table.h"
#include "kernel/arch/i386/interrupt/descriptor.h"

#include "gtest/gtest.h"

namespace interrupt {

TEST(Table, TestAddress) {
  InterruptDescriptorTable idt;
  EXPECT_EQ(reinterpret_cast<uint64_t>(idt.table_) & 0xFFFFFFFF,
            idt.IDTR() & 0xFFFFFFFF);
}

TEST(Table, TestInitiallyZeroed) {
  InterruptDescriptorTable idt;
  for (int i = 0; i < MAX_ENTRIES; i++) {
    EXPECT_EQ(0, reinterpret_cast<uint64_t *>(idt.table_)[i]);
  }
}

TEST(Table, TestZerothRegistered) {
  InterruptDescriptorTable idt;
  EXPECT_TRUE(idt.Register(GateDescriptor(), 0).ok());
  EXPECT_EQ(1 * 8 - 1, idt.IDTR() >> 32);
}

TEST(Table, TestSequentiallyRegistered) {
  InterruptDescriptorTable idt;
  EXPECT_TRUE(idt.Register(GateDescriptor(), 0).ok());
  EXPECT_TRUE(idt.Register(GateDescriptor(), 1).ok());
  EXPECT_TRUE(idt.Register(GateDescriptor(), 2).ok());
  EXPECT_EQ(3 * 8 - 1, idt.IDTR() >> 32);
}

TEST(Table, TestLaterRegistered) {
  InterruptDescriptorTable idt;
  EXPECT_TRUE(idt.Register(GateDescriptor(), 3).ok());
  EXPECT_EQ(4 * 8 - 1, idt.IDTR() >> 32);
}

TEST(Table, TestZerothRepeatedlyRegistered) {
  InterruptDescriptorTable idt;
  EXPECT_TRUE(idt.Register(GateDescriptor(), 0).ok());
  EXPECT_TRUE(idt.Register(GateDescriptor(), 0).ok());
  EXPECT_TRUE(idt.Register(GateDescriptor(), 0).ok());
  EXPECT_TRUE(idt.Register(GateDescriptor(), 0).ok());
  EXPECT_EQ(1 * 8 - 1, idt.IDTR() >> 32);
}

TEST(Table, TestLaterRepeatedlyRegistered) {
  InterruptDescriptorTable idt;
  EXPECT_TRUE(idt.Register(GateDescriptor(), 8).ok());
  EXPECT_TRUE(idt.Register(GateDescriptor(), 8).ok());
  EXPECT_TRUE(idt.Register(GateDescriptor(), 8).ok());
  EXPECT_TRUE(idt.Register(GateDescriptor(), 8).ok());
  EXPECT_EQ(9 * 8 - 1, idt.IDTR() >> 32);
}

TEST(Table, TestOverflow) {
  InterruptDescriptorTable idt;
  EXPECT_FALSE(idt.Register(GateDescriptor(), MAX_ENTRIES).ok());
}

}  // namespace interrupt

int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
