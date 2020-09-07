#ifndef KERNEL_TESTING_MACROS_H
#define KERNEL_TESTING_MACROS_H

#include "libc/stdio.h"
#include "libc/stdlib.h"
#include "util/overload_macros.h"
#include "util/status.h"

#define _KERNEL_TESTING_MACRO_STRINGIZE_(a) #a
#define _KERNEL_TESTING_MACRO_STRINGIZE(a) _KERNEL_TESTING_MACRO_STRINGIZE_(a)

// KERNEL_TEST defined a kernel test function for use in integration testing.
#define KERNEL_TEST(name)                         \
  static void KernelMain##name();                 \
  namespace {                                     \
  extern "C" void KernelMain() {                  \
    libc::puts("<< TEST " #name " STARTED >>");   \
    KernelMain##name();                           \
    libc::puts("<< TEST " #name " COMPLETED >>"); \
    libc::puts("<<KERNEL TEST COMPLETE>>");       \
    libc::abort();                                \
  }                                               \
  }                                               \
  static void KernelMain##name()

#define KERNEL_EXPECT(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT(KERNEL_EXPECT, __VA_ARGS__)

#define KERNEL_EXPECT_1(expr)                                               \
  do {                                                                      \
    const bool expr_result_ = (expr);                                       \
    if (expr_result_) {                                                     \
      break;                                                                \
    }                                                                       \
    libc::printf(                                                           \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q] }</ktest>\n",    \
        "expr", #expr, "want", "valid expression", "line",                  \
        _KERNEL_TESTING_MACRO_STRINGIZE(__LINE__), "file", __FILE__, "got", \
        "false");                                                           \
  } while (0)

#define KERNEL_EXPECT_2(expr, want)                                         \
  do {                                                                      \
    const bool expr_result_ = (expr);                                       \
    if (expr_result_) {                                                     \
      break;                                                                \
    }                                                                       \
    libc::printf(                                                           \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q] }</ktest>\n",    \
        "expr", #expr, "want", want, "line",                                \
        _KERNEL_TESTING_MACRO_STRINGIZE(__LINE__), "file", __FILE__, "got", \
        "false");                                                           \
  } while (0)

#define KERNEL_EXPECT_OK(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT(KERNEL_EXPECT_OK, __VA_ARGS__)

#define KERNEL_EXPECT_OK_1(expr)                                             \
  do {                                                                       \
    auto expr_result_ = (expr);                                              \
    if (expr_result_.Ok()) {                                                 \
      break;                                                                 \
    }                                                                        \
    auto expr_status_ = expr_result_.AsStatus();                             \
    libc::printf(                                                            \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q, %q] }</ktest>\n", \
        "expr", #expr, "want", "valid expression", "line",                   \
        _KERNEL_TESTING_MACRO_STRINGIZE(__LINE__), "file", __FILE__, "got",  \
        expr_status_.Message(), util::ErrorCodeName(expr_status_.Code()));   \
  } while (0)

#define KERNEL_EXPECT_OK_2(expr, want)                                       \
  do {                                                                       \
    auto expr_result_ = (expr);                                              \
    if (expr_result_.Ok()) {                                                 \
      break;                                                                 \
    }                                                                        \
    auto expr_status_ = expr_result_.AsStatus();                             \
    libc::printf(                                                            \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q, %q] }</ktest>\n", \
        "expr", #expr, "want", want, "line",                                 \
        _KERNEL_TESTING_MACRO_STRINGIZE(__LINE__), "file", __FILE__, "got",  \
        expr_status_.Message(), util::ErrorCodeName(expr_status_.Code()));   \
  } while (0)

#define KERNEL_ASSERT(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT(KERNEL_ASSERT, __VA_ARGS__)

#define KERNEL_ASSERT_1(expr)                                               \
  do {                                                                      \
    const bool expr_result_ = (expr);                                       \
    if (expr_result_) {                                                     \
      break;                                                                \
    }                                                                       \
    libc::printf(                                                           \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q] }</ktest>\n",    \
        "expr", #expr, "want", "valid expression", "line",                  \
        _KERNEL_TESTING_MACRO_STRINGIZE(__LINE__), "file", __FILE__, "got", \
        "false");                                                           \
  } while (0)

#define KERNEL_ASSERT_2(expr, want)                                         \
  do {                                                                      \
    const bool expr_result_ = (expr);                                       \
    if (expr_result_) {                                                     \
      break;                                                                \
    }                                                                       \
    libc::printf(                                                           \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q] }</ktest>\n",    \
        "expr", #expr, "want", want, "line",                                \
        _KERNEL_TESTING_MACRO_STRINGIZE(__LINE__), "file", __FILE__, "got", \
        "false");                                                           \
  } while (0)

#define KERNEL_ASSERT_OK(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT(KERNEL_ASSERT_OK, __VA_ARGS__)

#define KERNEL_ASSERT_OK_1(expr)                                             \
  do {                                                                       \
    auto expr_result_ = (expr);                                              \
    if (expr_result_.Ok()) {                                                 \
      break;                                                                 \
    }                                                                        \
    auto expr_status_ = expr_result_.AsStatus();                             \
    libc::printf(                                                            \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q, %q] }</ktest>\n", \
        "expr", #expr, "want", "valid expression", "line",                   \
        _KERNEL_TESTING_MACRO_STRINGIZE(__LINE__), "file", __FILE__, "got",  \
        expr_status_.Message(), util::ErrorCodeName(expr_status_.Code()));   \
    libc::abort();                                                           \
  } while (0)

#define KERNEL_ASSERT_OK_2(expr, want)                                       \
  do {                                                                       \
    auto expr_result_ = (expr);                                              \
    if (expr_result_.Ok()) {                                                 \
      break;                                                                 \
    }                                                                        \
    auto expr_status_ = expr_result_.AsStatus();                             \
    libc::printf(                                                            \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q, %q] }</ktest>\n", \
        "expr", #expr, "want", want, "line",                                 \
        _KERNEL_TESTING_MACRO_STRINGIZE(__LINE__), "file", __FILE__, "got",  \
        expr_status_.Message(), util::ErrorCodeName(expr_status_.Code()));   \
    libc::abort();                                                           \
  } while (0)

#define _KERNEL_ASSERT_OK_AND_ASSIGN_INTERNAL(status_or, lhs, expr)          \
  auto status_or = (expr);                                                   \
  do {                                                                       \
    if (status_or.Ok()) {                                                    \
      break;                                                                 \
    }                                                                        \
    auto expr_status_ = status_or.AsStatus();                                \
    libc::printf(                                                            \
        "<ktest>{ %q: %q, %q: %q, %q: %q, %q: %q, %q: [%q, %q] }</ktest>\n", \
        "expr", #expr, "want", "valid expression", "line",                   \
        _KERNEL_TESTING_MACRO_STRINGIZE(__LINE__), "file", __FILE__, "got",  \
        expr_status_.Message(), util::ErrorCodeName(expr_status_.Code()));   \
    libc::abort();                                                           \
  } while (0);                                                               \
  lhs = status_or.Value();

#define _KERNEL_ASSERT_OK_AND_ASSIGN_JOIN_INTERNAL(left, right) left##right
#define _KERNEL_ASSERT_OK_AND_ASSIGN_JOIN(left, right) \
  _KERNEL_ASSERT_OK_AND_ASSIGN_JOIN_INTERNAL(left, right)

#define KERNEL_ASSERT_OK_AND_ASSIGN(lhs, expr) \
  _KERNEL_ASSERT_OK_AND_ASSIGN_INTERNAL(       \
      _KERNEL_ASSERT_OK_AND_ASSIGN_JOIN(status_or, __COUNTER__), lhs, expr)

#endif  //  KERNEL_TESTING_MACROS_H
