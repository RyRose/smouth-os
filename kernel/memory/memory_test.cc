#include "kernel/memory/memory.h"

#include "kernel/arch/memory.h"

#include "gtest/gtest.h"

using memory::Allocator;

using arch::MemoryRegion;

namespace arch {
std::ostream &operator<<(std::ostream &stream, const MemoryRegion &region) {
  return stream << "\nMemoryRegion {\n address: " << region.address
                << "\n length: " << region.length
                << "\n type: " << static_cast<int>(region.type) << "\n}";
}

bool operator==(const MemoryRegion &lhs, const MemoryRegion &rhs) {
  return lhs.address == rhs.address && lhs.length == rhs.length &&
         lhs.type == rhs.type;
}
} // namespace arch

TEST(Mem, TestConstruction) {
  Allocator allocator;
  EXPECT_EQ(0, allocator.GetRegionCount());
}

TEST(Mem, AddMemory) {
  MemoryRegion region = {
      .address = 1, .length = 1000, .type = arch::MemoryRegionType::AVAILABLE};

  Allocator allocator;
  allocator.AddMemory(region);
  allocator.AddMemory(region);

  EXPECT_EQ(2, allocator.GetRegionCount());
}

TEST(Mem, FreeAllocation) {
  MemoryRegion regions[3];
  regions[0] = {
      .address = 1, .length = 1000, .type = arch::MemoryRegionType::AVAILABLE};
  regions[1] = {.address = 1001,
                .length = 2000,
                .type = arch::MemoryRegionType::AVAILABLE};

  Allocator allocator;
  allocator.AddMemory(regions[0]);
  allocator.AddMemory(regions[1]);
  void *ptr = allocator.Allocate(100);

  EXPECT_EQ(1, reinterpret_cast<uint64_t>(ptr));
  EXPECT_EQ(3, allocator.GetRegionCount());
}

TEST(Mem, AddressAllocation) {
  MemoryRegion regions[4];
  regions[0] = {
      .address = 0, .length = 1000, .type = arch::MemoryRegionType::AVAILABLE};
  regions[1] = {.address = 1000,
                .length = 2000,
                .type = arch::MemoryRegionType::AVAILABLE};

  Allocator allocator;
  allocator.AddMemory(regions[0]);
  allocator.AddMemory(regions[1]);
  EXPECT_EQ(0, allocator.Reserve(150, 100));
  EXPECT_EQ(4, allocator.GetRegionCount());
}

int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
