#include "kernel/arch/boot.h"

#include "cxx/kernel.h"

#include "libc/assert.h"
#include "libc/kernel.h"

#include "kernel/arch/i386/gdt/flush.h"
#include "kernel/arch/i386/gdt/table.h"
#include "kernel/arch/i386/init/dummy_isr.h"
#include "kernel/arch/i386/init/multiboot.h"
#include "kernel/arch/i386/instructions/instructions.h"
#include "kernel/arch/i386/interrupt/table.h"
#include "kernel/arch/i386/memory/linear.h"
#include "kernel/arch/i386/serial/serial.h"

#include "util/check.h"
#include "util/optional.h"
#include "util/status.h"

namespace arch_internal {

namespace {

InterruptDescriptorTable<256> idt;

util::Status InitializeInterrupts() {
  ASSIGN_OR_RETURN(
      GateDescriptor d,
      GateDescriptor::Create(
          /*offset=*/reinterpret_cast<uint32_t>(handleDummyInterrupt),
          /*segment_selector=*/0x8, /*gate_type=*/INTERRUPT_32BIT,
          /*dpl=*/0));
  libc::printf("Registering dummy interrupt: 0x%p.\n", handleDummyInterrupt);
  RETURN_IF_ERROR(idt.Register(0x80, d));
  libc::printf("Loading IDT with IDTR 0x%x.\n", idt.IDTR());
  RETURN_IF_ERROR(LoadIDT(idt.IDTR()));
  libc::puts("Triggering interrupt handler 0x80.");
  INT<0x80>();
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

util::Optional<arch::Terminal> tty;

util::StatusOr<arch::Terminal*> InitializeTTY() {
  ASSIGN_OR_RETURN(tty, arch::Terminal::Create(
                            80, 25, reinterpret_cast<uint16_t*>(0xB8000)));
  tty.Value().Clear();
  return &tty.Value();
}

util::Optional<SerialPort> com1;

SerialPort* InitializeCOM1() {
  const uint16_t base = 0x3F8;
  com1 = SerialPort::Create(/*port=*/IoPort(base),
                            /*interrupt=*/IoPort(base + 1),
                            /*fifo*/ IoPort(base + 2),
                            /*line_control=*/IoPort(base + 3),
                            /*modem_control=*/IoPort(base + 4),
                            /*line_status=*/IoPort(base + 5));
  return &com1.Value();
}

class KernelPut : public libc::KernelPutInterface {
 public:
  KernelPut(arch::Terminal* terminal, arch::SerialPortInterface* serial)
      : terminal_(terminal), serial_(serial) {}

  util::Status Put(char c) override {
    if (terminal_) {
      terminal_->Put(c);
    }
    if (serial_) {
      serial_->Write(c);
    }
    return {};
  }

 private:
  arch::Terminal* terminal_;
  arch::SerialPortInterface* serial_;
};

util::Optional<KernelPut> kernel_put;

void InitializePrintf(arch::Terminal* terminal,
                      arch::SerialPortInterface* serial) {
  kernel_put = KernelPut(terminal, serial);
  libc::kernel_put = &kernel_put.Value();
}

LinearAllocator<100> linear_allocator;

template <size_t N>
util::StatusOr<arch::Allocator*> InitializeAllocator(
    multiboot_info* multiboot_ptr) {
  libc::printf("Multiboot Pointer: 0x%p\n", multiboot_ptr);
  RET_CHECK(multiboot_ptr != nullptr);

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
    libc::printf("Region %d: {address=0x%x, length=%d, type=", i,
                 region->address, region->length);
    libc::printf("%s}\n", MemoryRegionTypeName(region->type));
  }
  return &linear_allocator;
}

util::StatusOr<void*> KernelNew(size_t n) {
  return linear_allocator.Allocate(n);
}

util::StatusOr<arch::BootInfo> pre_kernel_main_internal(
    multiboot_info* multiboot_ptr) {
  ASSIGN_OR_RETURN(auto* terminal, InitializeTTY());
  InitializePrintf(terminal, nullptr);
  libc::puts("== Initialized Terminal ==");
  libc::puts("== Initializing Serial Port ==");
  auto* serial_port = InitializeCOM1();
  serial_port->Write('\n');
  InitializePrintf(terminal, serial_port);
  libc::puts("== Initialized Serial Port ==");
  ASSIGN_OR_RETURN(auto* allocator, InitializeAllocator<100>(multiboot_ptr));
  libc::puts("== Initializing Kernel New ==");
  cxx::kernel_new = KernelNew;
  libc::puts("== Initializing GDT ==");
  RETURN_IF_ERROR(InitializeGlobalDescriptorTable());
  libc::puts("== Initializing Interrupts ==");
  RETURN_IF_ERROR(InitializeInterrupts());
  libc::printf(
      "== Returning BootInfo {tty=0x%p, com1=0x%p, allocator=0x%p} ==\n",
      terminal, serial_port, allocator);
  return arch::BootInfo(/*tty=*/terminal, /*com1=*/serial_port,
                        /*allocator=*/allocator);
}

extern "C" arch::BootInfo pre_kernel_main(multiboot_info* multiboot_ptr) {
  CHECK_OR_RETURN(const auto boot_info,
                  pre_kernel_main_internal(multiboot_ptr));
  return boot_info;
}

}  // namespace

}  // namespace arch_internal