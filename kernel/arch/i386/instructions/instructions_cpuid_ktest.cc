
#include "kernel/arch/i386/instructions/instructions.h"
#include "kernel/testing/macros.h"

namespace {

char message[300];

const char* FormatCpuidValues(uint32_t* values) {
  char name[32];
  for (int i = 0; i < 32; i++) {
    name[i] = reinterpret_cast<char*>(values)[i];
  }
  KERNEL_ASSERT_OK(libc::snprintf(
      message, 300, "%s [\n  %u 0x%x,\n  %u 0x%x,\n  %u 0x%x,\n  %u 0x%x]",
      name, values[0], values[0], values[1], values[1], values[2], values[2],
      values[3], values[3]));
  return message;
}

}  // namespace

KERNEL_TEST(TestArchI386InstructionsCpuid) {
  libc::puts("=========");
  uint32_t values[4];
  for (uint32_t i = 0; i < 6; i++) {
    instructions::CPUID(i, values);
    libc::printf("%d (%x)\n", i, i);
    libc::puts(FormatCpuidValues(values));
    libc::puts("=========");
  }
  for (uint64_t i = 0x80000000; i < 0x80000009; i++) {
    instructions::CPUID(i, values);
    libc::printf("%d (%x)\n", i, i);
    libc::puts(FormatCpuidValues(values));
    libc::puts("=========");
  }
}
