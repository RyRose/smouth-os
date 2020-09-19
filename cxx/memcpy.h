#ifndef CXX_MEMCPY_H
#define CXX_MEMCPY_H

#include <stddef.h>

#if !(__STDC_HOSTED__)

// memcpy is used for generating trivial copy-constructors for array member
// variables. We explicitly do not put this in a namespace to ensure the
// compiler properly calls it.
extern "C" void* memcpy(void* dest, const void* src, size_t len);

#endif

#endif