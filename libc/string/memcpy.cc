#include "libc/string/mem.h"

namespace libc {

void *memcpy(void *dstptr, const void *srcptr, size_t size) {
  unsigned char *dst = static_cast<unsigned char *>(dstptr);
  const unsigned char *src = static_cast<const unsigned char *>(srcptr);
  for (size_t i = 0; i < size; i++)
    dst[i] = src[i];
  return dstptr;
}

} // namespace libc
