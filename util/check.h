#ifndef UTIL_CHECK_H
#define UTIL_CHECK_H

#include "libc/stdlib.h"
#include "util/meta_macros.h"
#include "util/overload_macros.h"
#include "util/status.h"

namespace util {

#define CHECK(...) UTIL_OVERLOAD_MACROS_VA_SELECT_2(CHECK, __VA_ARGS__)

#define CHECK_1(expr) CHECK_2(expr, "INTERNAL")

#define CHECK_2(expr, message)                              \
  do {                                                      \
    if ((expr)) {                                           \
      break;                                                \
    }                                                       \
    libc::puts(__FILE__ ":" STRINGIZE(__LINE__) ": CHECK"); \
    libc::puts("Expression: " #expr);                       \
    libc::printf("Message: %s\n", (message));               \
    libc::abort();                                          \
  } while (0)

#define CHECK_OK(...) UTIL_OVERLOAD_MACROS_VA_SELECT_2(CHECK_OK, __VA_ARGS__)

#define CHECK_OK_1(expr) CHECK_OK_2(expr, "INTERNAL")

#define CHECK_OK_2(expr, message) \
  _CHECK_OK_2(expr, message, UNIQUE_VARIABLE, UNIQUE_VARIABLE)
#define _CHECK_OK_2(expr, message, expr_result, expr_status)                  \
  do {                                                                        \
    const auto expr_result = (expr);                                          \
    if (expr_result.Ok()) {                                                   \
      break;                                                                  \
    }                                                                         \
    const auto expr_status = expr_result.AsStatus();                          \
    libc::puts(__FILE__ ":" STRINGIZE(__LINE__) ": CHECK");                   \
    libc::puts("Expression: " #expr);                                         \
    libc::printf("Message: %s\n", (message));                                 \
    libc::printf("Status(%s): %s\n", util::ErrorCodeName(expr_status.Code()), \
                 expr_status.Message());                                      \
    libc::abort();                                                            \
  } while (0)

#define _CHECK_OR_RETURN_INTERNAL(lhs, expr, status_or, expr_status)          \
  auto status_or = (expr);                                                    \
  do {                                                                        \
    if (status_or.Ok()) {                                                     \
      break;                                                                  \
    }                                                                         \
    const auto expr_status = status_or.AsStatus();                            \
    libc::puts(__FILE__ ":" STRINGIZE(__LINE__) ": CHECK");                   \
    libc::printf("Status(%s): %s\n", util::ErrorCodeName(expr_status.Code()), \
                 expr_status.Message());                                      \
    libc::abort();                                                            \
  } while (0);                                                                \
  lhs = status_or.Value();

#define CHECK_OR_RETURN(lhs, expr) \
  _CHECK_OR_RETURN_INTERNAL(lhs, expr, UNIQUE_VARIABLE, UNIQUE_VARIABLE)

}  // namespace util

#endif