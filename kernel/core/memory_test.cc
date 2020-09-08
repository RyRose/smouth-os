
#include "kernel/core/memory.h"

#include "gtest/gtest.h"
#include "testing/assert.h"

namespace kernel {

TEST(Allocator, TestAllocate) {
  util::List<arch::MemoryRegion, 10> arch_regions;
  ASSERT_OK(arch_regions.Add(
      arch::MemoryRegion(/*address=*/100, /*length=*/10,
                         /*type=*/arch::MemoryRegionType::AVAILABLE)));
  ASSERT_OK_AND_ASSIGN(auto allocator, BumpAllocator<10>::Create(arch_regions));
  ASSERT_OK_AND_ASSIGN(const void* obj, allocator.Allocate(10));
  EXPECT_EQ(reinterpret_cast<uint64_t>(obj), 100);
  ASSERT_NOT_OK(allocator.Allocate(1));
}

TEST(Allocator, TestAllocateReserved) {
  util::List<arch::MemoryRegion, 10> arch_regions;
  ASSERT_OK(arch_regions.Add(
      arch::MemoryRegion(/*address=*/100, /*length=*/10,
                         /*type=*/arch::MemoryRegionType::AVAILABLE)));
  ASSERT_OK(arch_regions.Add(
      arch::MemoryRegion(/*address=*/100, /*length=*/5,
                         /*type=*/arch::MemoryRegionType::RESERVED)));
  ASSERT_OK_AND_ASSIGN(auto allocator, BumpAllocator<10>::Create(arch_regions));
  ASSERT_OK_AND_ASSIGN(const void* obj, allocator.Allocate(5));
  EXPECT_EQ(reinterpret_cast<uint64_t>(obj), 105);
  ASSERT_NOT_OK(allocator.Allocate(1));
}

}  // namespace kernel
