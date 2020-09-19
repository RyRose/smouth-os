#ifndef UTIL_CHECK_H
#define UTIL_CHECK_H

#include "util/overload_macros.h"
#include "util/status.h"

#include "libc/stdlib.h"

namespace util {

#define _UTIL_CHECK_STRINGIZE_(a) #a
#define _UTIL_CHECK_STRINGIZE(a) _UTIL_CHECK_STRINGIZE_(a)

#define CHECK(...) UTIL_OVERLOAD_MACROS_VA_SELECT_2(CHECK, __VA_ARGS__)

#define CHECK_1(expr)                                                     \
  do {                                                                    \
    if (!(expr)) {                                                        \
      libc::puts(__FILE__ ":" _UTIL_CHECK_STRINGIZE(__LINE__) ": CHECK"); \
      libc::puts("Expression: " #expr);                                   \
      libc::abort();                                                      \
    }                                                                     \
  } while (0)

#define CHECK_2(expr, message)                                            \
  do {                                                                    \
    if (!(expr)) {                                                        \
      libc::puts(__FILE__ ":" _UTIL_CHECK_STRINGIZE(__LINE__) ": CHECK"); \
      libc::puts("Expression: " #expr);                                   \
      libc::printf("Message: %s\n", (message));                           \
      libc::abort();                                                      \
    }                                                                     \
  } while (0)

#define CHECK_OK(...) UTIL_OVERLOAD_MACROS_VA_SELECT_2(CHECK_OK, __VA_ARGS__)

#define CHECK_OK_1(expr)                                                   \
  do {                                                                     \
    auto expr_result_ = (expr);                                            \
    if (!expr_result_.Ok()) {                                              \
      auto expr_status_ = expr_result_.AsStatus();                         \
      libc::puts(__FILE__ ":" _UTIL_CHECK_STRINGIZE(__LINE__) ": CHECK");  \
      libc::puts("Expression: " #expr);                                    \
      libc::printf("Status(%s): %s\n", ErrorCodeName(expr_status_.Code()), \
                   expr_status_.Message());                                \
      libc::abort();                                                       \
    }                                                                      \
  } while (0)

#define CHECK_OK_2(expr, message)                                          \
  do {                                                                     \
    auto expr_result_ = (expr);                                            \
    if (!expr_result_.Ok()) {                                              \
      auto expr_status_ = expr_result_.AsStatus();                         \
      libc::puts(__FILE__ ":" _UTIL_CHECK_STRINGIZE(__LINE__) ": CHECK");  \
      libc::puts("Expression: " #expr);                                    \
      libc::printf("Message: %s\n", (message));                            \
      libc::printf("Status(%s): %s\n", ErrorCodeName(expr_status_.Code()), \
                   expr_status_.Message());                                \
      libc::abort();                                                       \
    }                                                                      \
  } while (0)

#define _CHECK_OR_RETURN_INTERNAL(status_or, lhs, expr)                    \
  auto status_or = (expr);                                                 \
  do {                                                                     \
    if (!status_or.Ok()) {                                                 \
      auto expr_status_ = status_or.AsStatus();                            \
      libc::puts(__FILE__ ":" _UTIL_CHECK_STRINGIZE(__LINE__) ": CHECK");  \
      libc::printf("Status(%s): %s\n", ErrorCodeName(expr_status_.Code()), \
                   expr_status_.Message());                                \
      libc::abort();                                                       \
    }                                                                      \
  } while (0);                                                             \
  lhs = status_or.Value();

#define _CHECK_OR_RETURN_JOIN_INTERNAL(left, right) left##right
#define _CHECK_OR_RETURN_JOIN(left, right) \
  _CHECK_OR_RETURN_JOIN_INTERNAL(left, right)

#define CHECK_OR_RETURN(lhs, expr)                                         \
  _CHECK_OR_RETURN_INTERNAL(_CHECK_OR_RETURN_JOIN(status_or, __COUNTER__), \
                            lhs, expr)

}  // namespace util

#endif