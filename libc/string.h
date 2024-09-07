#ifndef LIBC_STRING_H
#define LIBC_STRING_H

#include <stddef.h>

#include "util/status.h"

namespace libc {

// Returns 0 if equal, -1 if aptr < bptr, and 1 if aptr > bptr for the first
// `size` bytes. Returns an error if aptr or bptr is null.
util::StatusOr<int> memcmp(const void* aptr, const void* bptr, size_t size);

// Copies `size` bytes from srcptr to dstptr. The two pointers may not overlap.
// Returns an error if dstptr or srcptr is null.
util::Status memcpy(void* dstptr, const void* srcptr, size_t size);

// Copies `size` bytes from srcptr to dstptr. The two pointers may overlap.
// Returns an error if dstptr or srcptr is null.
util::Status memmove(void* dstptr, const void* srcptr, size_t size);

// Sets `size` bytes in bufptr to `value`, which is cast to a uint8_t..
// Returns an error if bufptr is null.
util::Status memset(void* bufptr, int value, size_t size);

// Returns a pointer to the first occurrence of c in s, or nullptr if not found.
// Returns an error if s is null.
util::StatusOr<const char*> strchr(const char* s, char c);

// Returns 0 if s1 and s2 are equal, 1 if s1 > s2, -1 if s1 < s2.
// An error is returned if either is null.
util::StatusOr<int> strcmp(const char* s1, const char* s2);

// Returns the length of s.
// Returns an error if s is null.
util::StatusOr<size_t> strlen(const char* s);

}  // namespace libc

#endif  // LIBC_STRING_H
