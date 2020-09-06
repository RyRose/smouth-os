#include "kernel/arch/i386/boot/multiboot.h"

namespace arch {

multiboot_info multiboot_information;

namespace {

extern "C" void PreKernelMain(multiboot_info* multiboot_ptr) {
  multiboot_information = *multiboot_ptr;
}

}  // namespace

}  // namespace arch