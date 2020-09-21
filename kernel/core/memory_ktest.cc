
#include "cxx/kernel.h"
#include "kernel/arch/init.h"
#include "kernel/core/memory.h"
#include "kernel/testing/macros.h"
#include "libc/stdio.h"

namespace {
kernel::BumpAllocator<100> allocator;
}  // namespace

KERNEL_TEST(TestCoreMemory) {
  KERNEL_ASSERT_OK_AND_ASSIGN(const auto& boot, arch::Initialize());
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
  KERNEL_ASSERT_OK_AND_ASSIGN(
      allocator, kernel::BumpAllocator<100>::Create(boot.memory_regions));
  cxx::kernel_new = [](size_t n) { return allocator.Allocate(n); };
  for (size_t i = 0; i < 10; i++) {
    KERNEL_ASSERT(reinterpret_cast<uint64_t>(new (char[1000])) == i * 1000);
  }
}
