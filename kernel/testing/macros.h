#ifndef KERNEL_TESTING_MACROS_H
#define KERNEL_TESTING_MACROS_H

#include "libc/stdio.h"
#include "libc/stdlib.h"
#include "util/check.h"
#include "util/meta_macros.h"
#include "util/overload_macros.h"
#include "util/status.h"

// KERNEL_TEST defined a kernel test function for use in integration testing.
#define KERNEL_TEST(name)                                   \
  static void name();                                       \
  namespace {                                               \
  extern "C" void KernelMain() {                            \
    CHECK_OK(libc::puts("<< TEST " #name " STARTED >>"));   \
    name();                                                 \
    CHECK_OK(libc::puts("<< TEST " #name " COMPLETED >>")); \
    CHECK_OK(libc::puts("<<KERNEL TEST COMPLETE>>"));       \
    libc::abort();                                          \
  }                                                         \
  }                                                         \
  static void name()

#define KERNEL_EXPECT(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_2(KERNEL_EXPECT, __VA_ARGS__)

#define KERNEL_EXPECT_1(expr) KERNEL_EXPECT_2(expr, "valid expression")

#define KERNEL_EXPECT_2(expr, want) \
  _KERNEL_EXPECT_2(expr, want, UNIQUE_VARIABLE)
#define _KERNEL_EXPECT_2(expr, want, expr_result)                         \
  do {                                                                    \
    const bool expr_result = (expr);                                      \
    if (expr_result) {                                                    \
      break;                                                              \
    }                                                                     \
    CHECK_OK_1(libc::printf(                                              \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q] }</ktest>\n",  \
        "expr", #expr, "want", want, "line", STRINGIZE(__LINE__), "file", \
        __FILE__, "got", "false"));                                       \
  } while (0)

#define KERNEL_EXPECT_OK(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_2(KERNEL_EXPECT_OK, __VA_ARGS__)

#define KERNEL_EXPECT_OK_1(expr) KERNEL_EXPECT_OK_2(expr, "valid expression")

#define KERNEL_EXPECT_OK_2(expr, want) \
  _KERNEL_EXPECT_OK_2_(expr, want, UNIQUE_VARIABLE, UNIQUE_VARIABLE)
#define _KERNEL_EXPECT_OK_2_(expr, want, expr_result_, expr_status_)         \
  do {                                                                       \
    auto expr_result_ = (expr);                                              \
    if (expr_result_.Ok()) {                                                 \
      break;                                                                 \
    }                                                                        \
    auto expr_status_ = expr_result_.AsStatus();                             \
    CHECK_OK_1(libc::printf(                                                 \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q, %q] }</ktest>\n", \
        "expr", #expr, "want", want, "line", STRINGIZE(__LINE__), "file",    \
        __FILE__, "got", expr_status_.Message(),                             \
        util::ErrorCodeName(expr_status_.Code())));                          \
  } while (0)

#define KERNEL_ASSERT(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_2(KERNEL_ASSERT, __VA_ARGS__)

#define KERNEL_ASSERT_1(expr) KERNEL_ASSERT_2(expr, "valid expression")

#define KERNEL_ASSERT_2(expr, want) \
  _KERNEL_ASSERT_2(expr, want, UNIQUE_VARIABLE)
#define _KERNEL_ASSERT_2(expr, want, expr_result_)                        \
  do {                                                                    \
    const bool expr_result_ = (expr);                                     \
    if (expr_result_) {                                                   \
      break;                                                              \
    }                                                                     \
    CHECK_OK_1(libc::printf(                                              \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q] }</ktest>\n",  \
        "expr", #expr, "want", want, "line", STRINGIZE(__LINE__), "file", \
        __FILE__, "got", "false"));                                       \
    libc::abort();                                                        \
  } while (0)

#define KERNEL_ASSERT_OK(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_2(KERNEL_ASSERT_OK, __VA_ARGS__)

#define KERNEL_ASSERT_OK_1(expr) KERNEL_ASSERT_OK_2(expr, "valid expression")

#define KERNEL_ASSERT_OK_2(expr, want) \
  _KERNEL_ASSERT_OK_2(expr, want, UNIQUE_VARIABLE, UNIQUE_VARIABLE)
#define _KERNEL_ASSERT_OK_2(expr, want, expr_result, expr_status)            \
  do {                                                                       \
    auto expr_result = (expr);                                               \
    if (expr_result.Ok()) {                                                  \
      break;                                                                 \
    }                                                                        \
    auto expr_status = expr_result.AsStatus();                               \
    CHECK_OK_1(libc::printf(                                                 \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q, %q] }</ktest>\n", \
        "expr", #expr, "want", want, "line", STRINGIZE(__LINE__), "file",    \
        __FILE__, "got", expr_status.Message(),                              \
        util::ErrorCodeName(expr_status.Code())));                           \
    libc::abort();                                                           \
  } while (0)

#define KERNEL_ASSERT_OK_AND_ASSIGN(lhs, expr) \
  _KERNEL_ASSERT_OK_AND_ASSIGN(lhs, expr, UNIQUE_VARIABLE, UNIQUE_VARIABLE)

#define _KERNEL_ASSERT_OK_AND_ASSIGN(lhs, expr, status_or, expr_status)      \
  auto status_or = (expr);                                                   \
  do {                                                                       \
    if (status_or.Ok()) {                                                    \
      break;                                                                 \
    }                                                                        \
    auto expr_status = status_or.AsStatus();                                 \
    CHECK_OK_1(libc::printf(                                                 \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q, %q] }</ktest>\n", \
        "expr", #expr, "want", "valid expression", "line",                   \
        STRINGIZE(__LINE__), "file", __FILE__, "got", expr_status.Message(), \
        util::ErrorCodeName(expr_status.Code())));                           \
    libc::abort();                                                           \
  } while (0);                                                               \
  lhs = status_or.Value()

#endif  //  KERNEL_TESTING_MACROS_H
