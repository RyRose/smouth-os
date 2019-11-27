#ifndef LIBC_STRING_H
#define LIBC_STRING_H

#include <stddef.h>

#include "util/status.h"

namespace libc {

util::StatusOr<int> memcmp(const void*, const void*, size_t);
util::Status memcpy(void*, const void*, size_t);
util::Status memmove(void*, const void*, size_t);
util::Status memset(void*, int, size_t);

util::StatusOr<const char*> strchr(const char*, char c);
util::StatusOr<int> strcmp(const char*, const char*);
util::StatusOr<size_t> strlen(const char*);

}  // namespace libc

#endif  // LIBC_STRING_H
