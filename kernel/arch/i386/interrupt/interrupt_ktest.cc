
#include "kernel/arch/i386/instructions/instructions.h"
#include "kernel/arch/i386/interrupt/isrs.h"
#include "kernel/arch/i386/interrupt/table.h"
#include "kernel/testing/macros.h"
#include "libc/stdio.h"

namespace {
arch::InterruptDescriptorTable<256> idt;
}

KERNEL_TEST(TestInterrupts) {
  KERNEL_ASSERT_OK_AND_ASSIGN(
      const auto& dummy_handler,
      arch::GateDescriptor::Create(
          /*offset=*/reinterpret_cast<uintptr_t>(arch::isrs::dummy_handler),
          /*segment_selector=*/0x8,
          /*gate_type=*/arch::GateType::INTERRUPT_32BIT,
          /*dpl=*/0));
  KERNEL_ASSERT_OK(idt.Register(0x80, dummy_handler));
  KERNEL_ASSERT_OK(instructions::LIDT(idt.IDTR()));
  instructions::INT<0x80>();
}
