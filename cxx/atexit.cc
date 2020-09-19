#include "cxx/atexit.h"

#if !(__STDC_HOSTED__)

extern "C" {

int __cxa_atexit(void (*)(void*), void*, void*) { return 0; }

void __cxa_finalize(void*) {}
}

#endif
