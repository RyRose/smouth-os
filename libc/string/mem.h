#ifndef _LIBC_STRING_MEM_H
#define _LIBC_STRING_MEM_H

#include <stddef.h>

namespace libc {

int memcmp(const void*, const void*, size_t);
void* memcpy(void*, const void*, size_t);
void* memmove(void*, const void*, size_t);
void* memset(void*, int, size_t); 

} // namespace libc

#endif
