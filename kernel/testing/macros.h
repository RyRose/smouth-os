#ifndef KERNEL_TESTING_MACROS_H
#define KERNEL_TESTING_MACROS_H

#include "libc/stdio.h"
#include "libc/stdlib.h"

// KERNEL_TEST defined a kernel test function for use in integration testing.
#define KERNEL_TEST(name)                         \
  static void KernelMain##name();                 \
  namespace {                                     \
  extern "C" void KernelMain() {                  \
    libc::puts("<< TEST " #name " STARTED >>");   \
    KernelMain##name();                           \
    libc::puts("<< TEST " #name " COMPLETED >>"); \
    libc::puts("<<KERNEL TEST COMPLETE>>");       \
    libc::abort();                                \
  }                                               \
  }                                               \
  static void KernelMain##name()

#endif  //  KERNEL_TESTING_MACROS_H
