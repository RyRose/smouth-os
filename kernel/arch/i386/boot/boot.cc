#include <stdint.h>

#include "kernel/arch/i386/boot/dummy_isr.h"
#include "kernel/arch/i386/boot/mmap_manager.h"
#include "kernel/arch/i386/boot/multiboot.h"
#include "kernel/arch/i386/gdt/gdt_installer.h"
#include "kernel/arch/i386/instructions/instructions.h"
#include "kernel/arch/i386/interrupt/table.h"
#include "kernel/arch/tty.h"

// We purposefully don't wrap this in a namespace to allow linkage with boot.S
boot::multiboot_info *MULTIBOOT_INFORMATION_POINTER;

namespace arch {

void Initialize() {
  arch::terminal_initialize();
  auto &mmap_manager = boot::MmapManager::GetInstance();
  mmap_manager.Init(*MULTIBOOT_INFORMATION_POINTER);
  gdt::InstallGDT();
  interrupt::GateDescriptor d(
      /*offset=*/reinterpret_cast<uint32_t>(dummy_isr::handleDummyInterrupt),
      /*segment_selector=*/0x8, /*gate_type=*/interrupt::INTERRUPT_32BIT,
      /*dpl=*/0, /*present=*/true);
  interrupt::IDT.Register(d, 0x80);
  uint64_t idtr = interrupt::IDT.IDTR();
  instructions::LoadIDT(idtr);
  instructions::INT<0x80>();
}

} // namespace arch
