#include <stdint.h>

#include "kernel/arch/i386/boot/mmap_manager.h"
#include "kernel/arch/i386/boot/multiboot.h"
#include "kernel/arch/i386/gdt/gdt_installer.h"
#include "kernel/arch/i386/instructions/instructions.h"
#include "kernel/arch/i386/interrupt/table.h"
#include "kernel/arch/tty.h"

namespace {

extern "C" {

void handleDummyInterrupt();

void pre_kernel_main(boot::multiboot_info* multiboot_ptr) {
  arch::terminal_initialize();
  auto& mmap_manager = boot::MmapManager::GetInstance();
  mmap_manager.Init(*multiboot_ptr);
  gdt::InstallGDT();
  interrupt::GateDescriptor d(reinterpret_cast<uint32_t>(handleDummyInterrupt),
                              0x8, interrupt::INTERRUPT_32BIT, 0, true);
  interrupt::IDT.Register(d, 0x80);
  uint64_t idtr = interrupt::IDT.IDTR();
  instructions::LoadIDT(idtr);
  instructions::INT<0x80>();
}
}

}  // namespace
