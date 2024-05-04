
#include "kernel/arch/i386/boot/boot.h"
#include "kernel/arch/i386/instructions/instructions.h"
#include "kernel/testing/macros.h"

namespace {

// NOLINTNEXTLINE(misc-no-recursion)
void Recursive(int level, int64_t prev_distance) {
  if (level == 10) {
    return;
  }
  uint32_t ptr = instructions::SP();
  int64_t distance = reinterpret_cast<int64_t>(&kKernelEnd) - ptr;
  libc::printf("%X %p (%d)\n", ptr, &kKernelEnd, distance);

  KERNEL_EXPECT(prev_distance < distance);
  Recursive(level + 1, distance);
}
}  // namespace

KERNEL_TEST(TestArchI386InstructionsStackPointer) { Recursive(0, 0); }
