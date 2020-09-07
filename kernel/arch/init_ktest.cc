
#include "kernel/arch/init.h"
#include "kernel/testing/macros.h"
#include "libc/stdio.h"
#include "util/check.h"

KERNEL_TEST(Initialize) {
  KERNEL_ASSERT_OK_AND_ASSIGN(const auto& boot, arch::Initialize());
  KERNEL_EXPECT_OK(
      libc::printf("Boot Info: {tty=0x%p, com1=0x%p}\n", boot.tty, boot.com1));
  libc::puts("Memory Regions: [");
  for (size_t i = 0; i < boot.memory_regions.Size(); i++) {
    KERNEL_ASSERT_OK_AND_ASSIGN(const auto& region, boot.memory_regions.At(i));
    libc::printf("  {address=0x%x, length=0x%x (%d KiB), type=%s}\n",
                 region->address, region->length, region->length / 1024,
                 region->type == arch::MemoryRegionType::AVAILABLE
                     ? "available"
                     : "reserved");
  }
  libc::puts("]");
}
