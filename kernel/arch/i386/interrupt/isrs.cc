
#include "libc/stdio.h"
#include "libc/stdlib.h"

namespace {

extern "C" void dummy_handler_c() { libc::puts("== Dummy Handler 0x80 =="); }

extern "C" void double_fault_c() {
  libc::puts("== Double Fault ==");
  libc::abort();
}

}  // namespace
