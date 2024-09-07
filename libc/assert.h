#ifndef LIBC_ASSERT_H
#define LIBC_ASSERT_H

#include "libc/stdio.h"
#include "libc/stdlib.h"

#ifndef NDEBUG

// assert that expr is true else abort the kernel.
#define assert(expr)                                                    \
  do {                                                                  \
    auto expr_result_ = (expr);                                         \
    if (!expr_result) {                                                 \
      libc::puts("program: " __FILE__ ":" __LINE__ " Assertion `" #expr \
                 "' failed.");                                          \
      libc::abort()                                                     \
    }                                                                   \
  } while (0)

#endif  // NDEBUG

#ifdef NDEBUG
#define assert(expr) \
  do {               \
  } while (0)
#endif

#endif  // LIBC_ASSERT_H
