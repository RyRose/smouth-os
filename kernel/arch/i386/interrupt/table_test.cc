#include "kernel/arch/i386/interrupt/table.h"

#include "gtest/gtest.h"
#include "testing/assert.h"

namespace arch {

TEST(Descriptor, TestDefaultGateDescriptor) {
  GateDescriptor descriptor;
  EXPECT_EQ(0, *reinterpret_cast<uint64_t*>(&descriptor));
}

TEST(Descriptor, TestInterruptGateDescriptor) {
  ASSERT_OK_AND_ASSIGN(GateDescriptor descriptor,
                       GateDescriptor::Create(
                           /*offset=*/0x12345678, /*segment_selector=*/0x1234,
                           /*gate_type=*/GateType::INTERRUPT_32BIT, /*dpl=*/0));
  EXPECT_EQ(0x12348E0012345678, *reinterpret_cast<uint64_t*>(&descriptor));
}

TEST(Descriptor, TestTrapGateDescriptor) {
  ASSERT_OK_AND_ASSIGN(GateDescriptor descriptor,
                       GateDescriptor::Create(
                           /*offset=*/0x12345678, /*segment_selector=*/0x1234,
                           /*gate_type=*/GateType::TRAP_32BIT, /*dpl=*/0));
  EXPECT_EQ(0x12348F0012345678, *reinterpret_cast<uint64_t*>(&descriptor));
}

TEST(Descriptor, TestTaskGateDescriptor) {
  ASSERT_OK_AND_ASSIGN(GateDescriptor descriptor,
                       GateDescriptor::Create(
                           /*offset=*/0, /*segment_selector=*/0x1234,
                           /*gate_type=*/GateType::TASK, /*dpl=*/0));
  EXPECT_EQ(0x850012340000, *reinterpret_cast<uint64_t*>(&descriptor));
}

TEST(Table, TestAddress) {
  InterruptDescriptorTable<10> idt;
  const uint64_t want =
      reinterpret_cast<uint64_t>(idt.table_.Address()) & 0xFFFFFFFFu;
  const uint64_t got = (idt.IDTR() >> 16u) & 0xFFFFFFFFu;
  EXPECT_EQ(want, got);
  idt.Register(1, GateDescriptor());
  EXPECT_EQ(want, got);
}

TEST(Table, TestZerothRegistered) {
  InterruptDescriptorTable<10> idt;
  EXPECT_TRUE(idt.Register(0, GateDescriptor()).Ok());
  EXPECT_EQ(1 * 8 - 1, idt.IDTR() & 0xFFFFu);
}

TEST(Table, TestSequentiallyRegistered) {
  InterruptDescriptorTable<10> idt;
  EXPECT_OK(idt.Register(0, GateDescriptor()));
  EXPECT_OK(idt.Register(1, GateDescriptor()));
  EXPECT_OK(idt.Register(2, GateDescriptor()));
  EXPECT_EQ(3 * 8 - 1, idt.IDTR() & 0xFFFFu);
}

TEST(Table, TestLaterRegistered) {
  InterruptDescriptorTable<10> idt;
  EXPECT_OK(idt.Register(3, GateDescriptor()));
  EXPECT_EQ(4 * 8 - 1, idt.IDTR() & 0xFFFFu);
}

TEST(Table, TestZerothRepeatedlyRegistered) {
  InterruptDescriptorTable<10> idt;
  EXPECT_OK(idt.Register(0, GateDescriptor()));
  EXPECT_OK(idt.Register(0, GateDescriptor()));
  EXPECT_OK(idt.Register(0, GateDescriptor()));
  EXPECT_OK(idt.Register(0, GateDescriptor()));
  EXPECT_EQ(1 * 8 - 1, idt.IDTR() & 0xFFFFu);
}

TEST(Table, TestLaterRepeatedlyRegistered) {
  InterruptDescriptorTable<10> idt;
  EXPECT_OK(idt.Register(8, GateDescriptor()));
  EXPECT_OK(idt.Register(8, GateDescriptor()));
  EXPECT_OK(idt.Register(8, GateDescriptor()));
  EXPECT_OK(idt.Register(8, GateDescriptor()));
  EXPECT_EQ(9 * 8 - 1, idt.IDTR() & 0xFFFF);
}

TEST(Table, TestOverflow) {
  InterruptDescriptorTable<10> idt;
  EXPECT_NOT_OK(idt.Register(11, GateDescriptor()));
}

}  // namespace arch
