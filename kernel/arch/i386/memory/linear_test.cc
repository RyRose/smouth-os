#include "kernel/arch/i386/memory/linear.h"

#include <iostream>

#include "kernel/arch/memory.h"

#include "gtest/gtest.h"
#include "testing/assert.h"

namespace arch {
std::ostream& operator<<(std::ostream& stream, const MemoryRegion& region) {
  return stream << "\nMemoryRegion {\n address: " << region.address
                << "\n length: " << region.length
                << "\n type: " << static_cast<int>(region.type) << "\n}";
}

bool operator==(const MemoryRegion& lhs, const MemoryRegion& rhs) {
  return lhs.address == rhs.address && lhs.length == rhs.length &&
         lhs.type == rhs.type;
}
}  // namespace arch

namespace memory {

TEST(Mem, FreeAllocation) {
  arch::MemoryRegion regions[3];
  regions[0] = {
      .address = 1, .length = 1000, .type = arch::MemoryRegionType::AVAILABLE};
  regions[1] = {.address = 1001,
                .length = 2000,
                .type = arch::MemoryRegionType::AVAILABLE};

  LinearAllocator<10> allocator;
  allocator.AddMemory(regions[0]);
  allocator.AddMemory(regions[1]);
  ASSERT_OK_AND_ASSIGN(const auto& ptr, allocator.Allocate(100));
  EXPECT_EQ(1, reinterpret_cast<uint64_t>(ptr));
}

}  // namespace memory
