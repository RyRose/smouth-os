#include "kernel/arch/init.h"

#include "cxx/kernel.h"
#include "kernel/arch/i386/boot/boot.h"
#include "kernel/arch/i386/boot/multiboot.h"
#include "kernel/arch/i386/gdt/flush.h"
#include "kernel/arch/i386/gdt/table.h"
#include "kernel/arch/i386/instructions/instructions.h"
#include "kernel/arch/i386/interrupt/macros.h"
#include "kernel/arch/i386/interrupt/table.h"
#include "kernel/arch/i386/io/serial.h"
#include "libc/kernel.h"
#include "libc/stdio.h"
#include "util/check.h"
#include "util/optional.h"
#include "util/status.h"

namespace arch {

namespace {

INTERRUPT_SERVICE_ROUTINE(DummyHandler) {
  libc::puts("== Dummy Handler 0x80 ==");
}

INTERRUPT_SERVICE_ROUTINE(DoubleFault) {
  libc::puts("== Double Fault ==");
  libc::abort();
}

InterruptDescriptorTable<256> idt;

util::Status InitializeInterrupts() {
  ASSIGN_OR_RETURN(const auto& dummy_handler,
                   GateDescriptor::Create(
                       /*offset=*/reinterpret_cast<uintptr_t>(DummyHandler),
                       /*segment_selector=*/0x8, /*gate_type=*/INTERRUPT_32BIT,
                       /*dpl=*/0));
  ASSIGN_OR_RETURN(const auto& double_fault,
                   GateDescriptor::Create(
                       /*offset=*/reinterpret_cast<uintptr_t>(DoubleFault),
                       /*segment_selector=*/0x8, /*gate_type=*/INTERRUPT_32BIT,
                       /*dpl=*/0));
  RETURN_IF_ERROR(idt.Register(0x8, double_fault));
  RETURN_IF_ERROR(idt.Register(0x80, dummy_handler));
  libc::printf("Loading IDT with IDTR 0x%x.\n", idt.IDTR());
  RETURN_IF_ERROR(instructions::LIDT(idt.IDTR()));
  libc::puts("Triggering interrupt handler 0x80.");
  instructions::INT<0x80>();
  return {};
}

GlobalDescriptorTable<3> gdt;

util::Status InitializeGlobalDescriptorTable() {
  ASSIGN_OR_RETURN(Descriptor code_descriptor,
                   Descriptor::Create(
                       /*base=*/0, /*limit=*/0xFFFFF, /*segment_type=*/0xA,
                       /*descriptor_type=*/true, /*dpl=*/0,
                       /*db=*/true, /*granularity=*/true));
  ASSIGN_OR_RETURN(Descriptor data_descriptor,
                   Descriptor::Create(
                       /*base=*/0, /*limit=*/0xFFFFF, /*segment_type=*/0x2,
                       /*descriptor_type=*/true, /*dpl=*/0,
                       /*db=*/true, /*granularity=*/true));
  gdt.Register(1, code_descriptor);
  gdt.Register(2, data_descriptor);
  return InstallAndFlushGDT(gdt.Pointer());
}

util::Optional<Terminal> tty;

util::Status InitializeTTY(uint16_t* framebuffer) {
  ASSIGN_OR_RETURN(tty, Terminal::Create(80, 25, framebuffer));
  tty.Value().Clear();
  return {};
}

util::Optional<SerialPort> com1;

void InitializeCOM1() {
  const uint16_t base = 0x3F8;
  com1 = SerialPort::Create(/*port=*/IoPort(base),
                            /*interrupt=*/IoPort(base + 1),
                            /*fifo*/ IoPort(base + 2),
                            /*line_control=*/IoPort(base + 3),
                            /*modem_control=*/IoPort(base + 4),
                            /*line_status=*/IoPort(base + 5));
}

util::StatusOr<util::List<MemoryRegion, 100>> InitializeMemoryRegions(
    multiboot_info* multiboot_ptr) {
  RET_CHECK(multiboot_ptr != nullptr);

  util::List<MemoryRegion, 100> entries;

  const auto* mmap_entries =
      reinterpret_cast<multiboot_mmap_entry*>(multiboot_ptr->mmap_addr);
  const size_t mmap_entry_count =
      multiboot_ptr->mmap_length / sizeof(multiboot_mmap_entry);
  for (size_t i = 0; i < mmap_entry_count; i++) {
    MemoryRegion region;
    region.address = mmap_entries[i].addr;
    region.length = mmap_entries[i].len;
    if (mmap_entries[i].type == MULTIBOOT_MEMORY_AVAILABLE) {
      region.type = MemoryRegionType::AVAILABLE;
    } else {
      region.type = MemoryRegionType::RESERVED;
    }
    RETURN_IF_ERROR(entries.Add(region));
  }

  MemoryRegion kernel_region;
  kernel_region.address = reinterpret_cast<uint64_t>(&kKernelStart);
  kernel_region.length =
      reinterpret_cast<uint64_t>(&kKernelEnd) - kernel_region.address;
  kernel_region.type = MemoryRegionType::RESERVED;
  RETURN_IF_ERROR(entries.Add(kernel_region));
  return entries;
}

void InitializeStubs() {
  libc::kernel_put = [](char c) -> util::Status {
    if (tty.Exists()) {
      tty.Value().Put(c);
    }
    if (com1.Exists()) {
      com1.Value().Write(c);
    }
    return {};
  };
  libc::kernel_panic = [](const char* message) {
    libc::puts("Kernel Panic!");
    libc::printf("Message: %s\n", message);
    IoPort new_qemu_shutdown_port(0x604);
    new_qemu_shutdown_port.outw(0x2000);
    libc::puts(
        "QEMU did not shut down. This is expected for older versions of QEMU. "
        "Trying older variant of shutting down QEMU.");
    IoPort old_qemu_shutdown_port(0xB004);
    old_qemu_shutdown_port.outw(0x2000);
    libc::puts("Could not shut down. Looping CLI/HLT forever.");
    while (true) {
      instructions::CLI();
      instructions::HLT();
    }
  };
  cxx::kernel_panic = libc::kernel_panic;
}

util::StatusOr<const char*> MultibootMmapEntryTypeName(
    multiboot_uint32_t type) {
  switch (type) {
    case MULTIBOOT_MEMORY_AVAILABLE:
      return "available";
    case MULTIBOOT_MEMORY_RESERVED:
      return "reserved";
    case MULTIBOOT_MEMORY_ACPI_RECLAIMABLE:
      return "acpi reclaimable";
    case MULTIBOOT_MEMORY_NVS:
      return "nvs";
    case MULTIBOOT_MEMORY_BADRAM:
      return "bad ram";
    default:
      return util::Status("invalid multiboot memory type");
  }
}

util::Status PrintMultibootInfo(multiboot_info* multiboot_ptr) {
  RET_CHECK(multiboot_ptr);
  libc::puts("Multiboot Info: {");
  libc::printf("  flags: 0x%x\n", multiboot_ptr->flags);
  libc::printf("  mem_lower: %d KiB\n", multiboot_ptr->mem_lower);
  libc::printf("  mem_upper: %d KiB\n", multiboot_ptr->mem_upper);
  libc::printf("  cmdline: %q\n",
               reinterpret_cast<const char*>(multiboot_ptr->cmdline));
  libc::printf("  mmap_addr: 0x%p\n", multiboot_ptr->mmap_addr);
  libc::printf("  mmap_length: %d\n", multiboot_ptr->mmap_length);

  libc::puts("  mmap_entries: [");
  const auto* mmap_entries =
      reinterpret_cast<multiboot_mmap_entry*>(multiboot_ptr->mmap_addr);
  const size_t mmap_entry_count =
      multiboot_ptr->mmap_length / sizeof(multiboot_mmap_entry);
  for (size_t i = 0; i < mmap_entry_count; i++) {
    ASSIGN_OR_RETURN(const char* type,
                     MultibootMmapEntryTypeName(mmap_entries[i].type));
    libc::printf("  {addr=0x%x, len=0x%x (%d KiB), type=%s},\n",
                 mmap_entries[i].addr, mmap_entries[i].len,
                 mmap_entries[i].len / 1024, type);
  }
  libc::puts("  ]");

  libc::printf("  boot_loader_name: %q\n",
               reinterpret_cast<const char*>(multiboot_ptr->boot_loader_name));
  libc::printf("  framebuffer_addr: %d\n", multiboot_ptr->framebuffer_addr);
  libc::puts("}");
  return {};
}

}  // namespace

util::StatusOr<BootInfo> Initialize() {
  BootInfo info;

  libc::puts("== Initializing Stubs ==");
  InitializeStubs();

  libc::puts("== Initializing Serial Port ==");
  InitializeCOM1();
  info.com1 = &com1.Value();

  libc::puts("== Initializing Terminal ==");
  RETURN_IF_ERROR(InitializeTTY(reinterpret_cast<uint16_t*>(0xB8000)));
  info.tty = &tty.Value();

  libc::puts("== Multiboot Info ==");
  RETURN_IF_ERROR(PrintMultibootInfo(&kMultibootInformation));

  libc::puts("== Initializing Memory Regions ==");
  ASSIGN_OR_RETURN(info.memory_regions,
                   InitializeMemoryRegions(&kMultibootInformation));

  libc::puts("== Initializing GDT ==");
  RETURN_IF_ERROR(InitializeGlobalDescriptorTable());

  libc::puts("== Initializing Interrupts ==");
  RETURN_IF_ERROR(InitializeInterrupts());

  return info;
}

}  // namespace arch