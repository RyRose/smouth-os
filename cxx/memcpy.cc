#include "cxx/memcpy.h"

#include "stddef.h"

#if !(__STDC_HOSTED__)

extern "C" void* memcpy(void* dest, const void* src, size_t n) {
  char* c1 = static_cast<char*>(dest);
  const char* c2 = static_cast<const char*>(src);
  for (size_t i = 0; i < n; ++i) c1[i] = c2[i];
  return dest;
}

#endif
