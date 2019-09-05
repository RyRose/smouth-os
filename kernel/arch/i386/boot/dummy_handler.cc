#include "libc/stdio/printf.h"

namespace {

extern "C" void dummy_handler() { libc::printf("dummy handler works!\n"); }

} // namespace
