#include <stdint.h>

#include "kernel/arch/i386/boot/multiboot.h"
#include "kernel/arch/i386/boot/mmap_manager.h"
#include "kernel/arch/i386/boot/gdt_installer.h"

namespace {

extern "C"
void pre_kernel_main(boot::multiboot_info* multiboot_ptr) {
  auto& mmap_manager = boot::MmapManager::GetInstance();
  mmap_manager.Init(*multiboot_ptr);
  boot::installGdt();
}

}
