#include "cxx/kernel.h"
#include "kernel/arch/i386/boot/multiboot.h"
#include "kernel/arch/i386/io/io_port.h"
#include "kernel/arch/i386/io/serial.h"
#include "libc/kernel.h"

namespace arch {

multiboot_info kMultibootInformation;

namespace {

util::Status KernelPut(char c) {
  const uint16_t base = 0x3F8;
  SerialPort com1 = SerialPort::Create(/*port=*/IoPort(base),
                                       /*interrupt=*/IoPort(base + 1),
                                       /*fifo*/ IoPort(base + 2),
                                       /*line_control=*/IoPort(base + 3),
                                       /*modem_control=*/IoPort(base + 4),
                                       /*line_status=*/IoPort(base + 5));
  com1.Write(c);
  return {};
}

void KernelPuts(const char* message) {
  for (const char* ptr = message; *ptr != '\0'; ptr++) {
    KernelPut(*ptr);
  }
  KernelPut('\n');
}

void InitializeStubs() {
  libc::kernel_put = KernelPut;
  libc::kernel_panic = [](const char* message) {
    KernelPuts("Pre-Kernel Panic!");
    KernelPuts("Message: ");
    KernelPuts(message);
    IoPort new_qemu_shutdown_port(0x604);
    new_qemu_shutdown_port.outw(0x2000);
    KernelPuts(
        "QEMU did not shut down. This is expected for older versions of QEMU. "
        "Trying older variant of shutting down QEMU.");
    IoPort old_qemu_shutdown_port(0xB004);
    old_qemu_shutdown_port.outw(0x2000);
    KernelPuts("Could not shut down. Looping forever.");
    while (true) {
    }
  };
  cxx::kernel_panic = libc::kernel_panic;
}

extern "C" void PreKernelMain(multiboot_info* multiboot_ptr) {
  InitializeStubs();
  kMultibootInformation = *multiboot_ptr;
  // Write newline to get output on a different line than preamble text.
  KernelPut('\n');
  KernelPuts("== Initialized Pre-Kernel Main ==");
}

}  // namespace

}  // namespace arch