#include "cxx/atexit.h"

extern "C" {

int __cxa_atexit(void (*)(void*), void*, void*) { return 0; }

void __cxa_finalize(void*) {}
}
