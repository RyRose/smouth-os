#include "kernel/arch/i386/boot/multiboot.h"

#include "gtest/gtest.h"

TEST(Multiboot, MmapEntries) {
  uint32_t[150] entries;
  entries[0]= 20;
  entries[2] = 2;
  entries[4] = 4;
  uint8_t multiboot_ptr[120];
  multiboot_ptr[47] = 24;
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
