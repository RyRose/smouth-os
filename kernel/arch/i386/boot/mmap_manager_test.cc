#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include <array>

#define KERNEL_ARCH_I386_BOOT_MMAP_MANAGER_TEST
#include "kernel/arch/i386/boot/mmap_manager.h"

namespace boot {

bool operator==(const multiboot_mmap_entry &lhs,
                const multiboot_mmap_entry &rhs) {
  return lhs.size == rhs.size && lhs.addr == rhs.addr && lhs.len == rhs.len &&
         lhs.type == rhs.type;
}

TEST(MmapManager, TestConstruction) {
  MmapManager manager = MmapManager::GetInstance();
  EXPECT_EQ(0, manager.CopyTo(nullptr, 100));
}

TEST(MmapManager, TestInit) {
  MmapManager manager = MmapManager::GetInstance();
  multiboot_mmap_entry entries[3];
  multiboot_info multiboot_ptr;
  multiboot_ptr.mmap_addr = entries;
  multiboot_ptr.mmap_length = 3 * sizeof(multiboot_mmap_entry);
  EXPECT_TRUE(manager.Init(multiboot_ptr));
}

TEST(MmapManager, TestExceedMax) {
  MmapManager manager = MmapManager::GetInstance();
  multiboot_mmap_entry entries[101];
  multiboot_info multiboot_ptr;
  multiboot_ptr.mmap_addr = entries;
  multiboot_ptr.mmap_length = 101 * sizeof(multiboot_mmap_entry);
  EXPECT_FALSE(manager.Init(multiboot_ptr));
}

TEST(MmapManager, TestCopiesCorrectly) {
  MmapManager manager = MmapManager::GetInstance();
  multiboot_mmap_entry entries[3];
  entries[0] = {1, 1, 1, 1};
  entries[1] = {2, 2, 2, 2};
  entries[2] = {3, 3, 3, 3};
  multiboot_info multiboot_ptr;
  multiboot_ptr.mmap_addr = entries;
  multiboot_ptr.mmap_length = 3 * sizeof(multiboot_mmap_entry);
  ASSERT_TRUE(manager.Init(multiboot_ptr));
  multiboot_mmap_entry copied_entries[3];
  manager.CopyTo(copied_entries, 3);
  for (int i = 0; i < 3; i++) {
    EXPECT_EQ(entries[i], copied_entries[i]);
  }
}

} // namespace boot

int main(int argc, char **argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
