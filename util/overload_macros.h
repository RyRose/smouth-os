#ifndef UTIL_OVERLOAD_MACROS_H
#define UTIL_OVERLOAD_MACROS_H

#include "util/meta_macros.h"

// Overload Macros
//
// The UTIL_OVERLOAD_MACROS_VA_SELECT_* macros enable the construction of
// variadic macros that call another macro dependent on the number of arguments
// provided. The choice of which UTIL_OVERLOAD_MACROS_VA_SELECT_*N* to use is
// dependent on the number of arguments you want to support. For example, let's
// look at converting a collection of macros to use this:
//
// #define ADD_1(a) (a)
// #define ADD_2(a, b) (a) + (b)
// #define ADD_3(a, b, c) (a) + (b) + (c)
// #define ADD_N(a, b, c, ...) (a) + (b) + (c) + add(__VA_ARGS__)
//
// In order to use these macros, the consumer must individually call each macro.
// However, if we define the following in addition to the macros above:
//
// #define ADD(...) UTIL_OVERLOAD_MACROS_VA_SELECT_3(ADD, __VA_ARGS__)
//
// Now, the following invocations can be made:
//
// ADD(1) -> ADD_1(1) -> (1)
// ADD(1, 2) -> ADD_2(1, 2) -> (1) + (2)
// ADD(1, 2, 3) -> ADD_3(1, 2, 3) -> (1) + (2) + (3)
// ADD(1, 2, 3, 4, 5) -> ADD_N(1, 2, 3, 4, 5) -> (1) + (2) + (3) + add(4, 5)
//
// See
// https://stackoverflow.com/questions/16683146/can-macros-be-overloaded-by-number-of-arguments
// for more details on how this works.
//

namespace util {

#define _UTIL_OVERLOAD_MACROS_SELECT(name, num) \
  CONCATENATE(CONCATENATE(name, _), num)
#define _UTIL_OVERLOAD_MACROS_VA_COUNT(_1, _2, _3, _4, _5, _6, _7, _8, _9,     \
                                       _10, _11, _12, _13, _14, _15, _16, _17, \
                                       _18, _19, _20, count, ...)              \
  count

#define _UTIL_OVERLOAD_MACROS_VA_SIZE_2(...)                                   \
  _UTIL_OVERLOAD_MACROS_VA_COUNT(__VA_ARGS__, N, N, N, N, N, N, N, N, N, N, N, \
                                 N, N, N, N, N, N, N, 2, 1, 0)
#define UTIL_OVERLOAD_MACROS_VA_SELECT_2(name, ...)                          \
  _UTIL_OVERLOAD_MACROS_SELECT(name,                                         \
                               _UTIL_OVERLOAD_MACROS_VA_SIZE_2(__VA_ARGS__)) \
  (__VA_ARGS__)

#define _UTIL_OVERLOAD_MACROS_VA_SIZE_3(...)                                   \
  _UTIL_OVERLOAD_MACROS_VA_COUNT(__VA_ARGS__, N, N, N, N, N, N, N, N, N, N, N, \
                                 N, N, N, N, N, N, 3, 2, 1, 0)
#define UTIL_OVERLOAD_MACROS_VA_SELECT_3(name, ...)                          \
  _UTIL_OVERLOAD_MACROS_SELECT(name,                                         \
                               _UTIL_OVERLOAD_MACROS_VA_SIZE_3(__VA_ARGS__)) \
  (__VA_ARGS__)

}  // namespace util

#endif
