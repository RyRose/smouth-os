
#include "kernel/arch/init.h"
#include "kernel/core/init.h"
#include "libc/stdio.h"
#include "libc/stdlib.h"
#include "util/check.h"

namespace {

extern "C" void KernelMain() {
  libc::puts("== Kernel Main ==");
  CHECK_OR_RETURN(const auto& boot, arch::Initialize());
  CHECK_OK(kernel::Initialize(boot));
  libc::abort();
}

}  // namespace
