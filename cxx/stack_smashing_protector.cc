
#include "cxx/stack_smashing_protector.h"

#include <stdint.h>

#include "cxx/kernel.h"

#if UINT32_MAX == UINTPTR_MAX
#define STACK_CHK_GUARD 0xDEADA4BC
#else
#define STACK_CHK_GUARD 0xDEADA4BCAFCA3684
#endif

uintptr_t __stack_chk_guard = STACK_CHK_GUARD;

void __attribute__((noreturn)) __stack_chk_fail() {
  cxx::KernelPanic("Stack smashing detected");
}
