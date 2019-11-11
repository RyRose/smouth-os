#ifndef LIBC_ASSERT_H
#define LIBC_ASSERT_H

#include "libc/stdio.h"
#include "libc/stdlib.h"

#define assert(expr)                                                    \
  do {                                                                  \
    auto expr_result_ = (expr);                                         \
    if (!expr_result) {                                                 \
      libc::puts("program: " __FILE__ ":" __LINE__ " Assertion `" #expr \
                 "' failed.");                                          \
      libc::abort()                                                     \
    }                                                                   \
  } while (0)

#endif
