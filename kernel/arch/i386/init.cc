#include "kernel/arch/init.h"

#include "cxx/kernel.h"
#include "kernel/arch/i386/boot/boot.h"
#include "kernel/arch/i386/boot/multiboot.h"
#include "kernel/arch/i386/gdt/flush.h"
#include "kernel/arch/i386/gdt/table.h"
#include "kernel/arch/i386/instructions/instructions.h"
#include "kernel/arch/i386/interrupt/macros.h"
#include "kernel/arch/i386/interrupt/table.h"
#include "kernel/arch/i386/memory/linear.h"
#include "kernel/arch/i386/serial/serial.h"
#include "libc/assert.h"
#include "libc/kernel.h"
#include "util/check.h"
#include "util/optional.h"
#include "util/status.h"

namespace arch {

namespace {

REGISTER_INTERRUPT_SERVICE_ROUTINE(DummyHandler);
INTERRUPT_SERVICE_ROUTINE(DummyHandler,
                          { libc::puts("== Dummy Handler 0x80 =="); });

REGISTER_INTERRUPT_SERVICE_ROUTINE(DoubleFault);
INTERRUPT_SERVICE_ROUTINE(DoubleFault, {
  libc::puts("== Double Fault ==");
  libc::abort();
});

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

GlobalDescriptorTable<8> gdt;

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
  // Write newline to get output on a different line than preamble text.
  com1.Value().Write('\n');
}

LinearAllocator<100> linear_allocator;

template <size_t N>
util::Status InitializeAllocator(multiboot_info* multiboot_ptr) {
  RET_CHECK(multiboot_ptr != nullptr);
  libc::printf("Multiboot Pointer: 0x%p\n", multiboot_ptr);

  libc::puts("Initializing entries.");
  util::List<multiboot_mmap_entry, N> entries;
  const auto* mmap_address =
      reinterpret_cast<multiboot_mmap_entry*>(multiboot_ptr->mmap_addr);
  libc::printf("Memory map address: 0x%p\n", mmap_address);
  const size_t mmap_entry_count =
      multiboot_ptr->mmap_length / sizeof(multiboot_mmap_entry);
  libc::printf("Memory map entry count: %d\n", mmap_entry_count);
  for (size_t i = 0; i < mmap_entry_count; i++) {
    RETURN_IF_ERROR(entries.Add(mmap_address[i]));
  }
  RET_CHECK(entries.Size() == mmap_entry_count, "mmap entry mismatch");
  ASSIGN_OR_RETURN(linear_allocator, LinearAllocator<N>::Create(entries));
  libc::printf("Memory Regions Found: %d\n", linear_allocator.Regions().Size());
  for (size_t i = 0; i < linear_allocator.Regions().Size(); i++) {
    ASSIGN_OR_RETURN(const auto* region, linear_allocator.Regions().At(i));
    libc::printf("Region %d: {address=0x%x, length=0x%x, type=%s}\n", i,
                 region->address, region->length,
                 MemoryRegionTypeName(region->type));
  }
  return {};
}

void InitializeStubs() {
  cxx::kernel_new = [](size_t n) { return linear_allocator.Allocate(n); };
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

util::Status PrintMultibootInfo(multiboot_info* multiboot_ptr) {
  RETURN_IF_ERROR(libc::printf(
      "cmdline: %s\n", reinterpret_cast<const char*>(multiboot_ptr->cmdline)));
  RETURN_IF_ERROR(
      libc::printf("mmap_length: %d\n", multiboot_ptr->mmap_length));
  RETURN_IF_ERROR(libc::printf(
      "boot_loader_name: %s\n",
      reinterpret_cast<const char*>(multiboot_ptr->boot_loader_name)));
  RETURN_IF_ERROR(
      libc::printf("framebuffer_addr: %d\n", multiboot_ptr->framebuffer_addr));
  RETURN_IF_ERROR(libc::printf("flags: 0x%X\n", multiboot_ptr->flags));
  return {};
}

}  // namespace

util::StatusOr<BootInfo> Initialize() {
  InitializeStubs();
  libc::puts("== Initializing Serial Port ==");
  InitializeCOM1();
  libc::puts("== Initializing Terminal ==");
  RETURN_IF_ERROR(InitializeTTY(reinterpret_cast<uint16_t*>(0xB8000)));
  libc::puts("== Multiboot Info ==");
  RETURN_IF_ERROR(PrintMultibootInfo(&multiboot_information));
  libc::puts("== Initializing Memory Allocator ==");
  RETURN_IF_ERROR(InitializeAllocator<100>(&multiboot_information));
  libc::puts("== Initializing Kernel New ==");
  libc::puts("== Initializing GDT ==");
  RETURN_IF_ERROR(InitializeGlobalDescriptorTable());
  libc::puts("== Initializing Interrupts ==");
  RETURN_IF_ERROR(InitializeInterrupts());
  libc::printf(
      "== Returning BootInfo {tty=0x%p, com1=0x%p, allocator=0x%p} ==\n",
      &tty.Value(), &com1.Value(), &linear_allocator);
  return BootInfo(/*tty=*/&tty.Value(), /*com1=*/&com1.Value(),
                  /*allocator=*/&linear_allocator);
}

}  // namespace arch