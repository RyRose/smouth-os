
#include "kernel/arch/i386/instructions/instructions.h"
#include "kernel/testing/macros.h"

KERNEL_TEST(TestArchI386InstructionsRdtsc) {
  constexpr const size_t iterations = 100;
  uint64_t values[iterations];
  for (uint64_t& value : values) {
    value = instructions::RDTSC();
  }

  libc::printf("tsc (%d of %d): %d\n", 1, iterations, values[0]);
  for (size_t i = 1; i < iterations; i++) {
    libc::printf("tsc (%d of %d): %d (+%d)\n", i, iterations, values[i],
                 values[i] - values[i - 1]);
  }

  char message[50];
  for (size_t i = 1; i < iterations; i++) {
    KERNEL_EXPECT_OK(libc::snprintf(message, 50, "%d of %d: %d < %d\n", i + 1,
                                    iterations, values[i - 1], values[i]));
    KERNEL_EXPECT(values[i - 1] < values[i], message);
  }
}
