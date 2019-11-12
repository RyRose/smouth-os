#ifndef UTIL_OVERLOAD_MACROS_H
#define UTIL_OVERLOAD_MACROS_H

namespace util {

// See
// https://stackoverflow.com/questions/16683146/can-macros-be-overloaded-by-number-of-arguments?lq=1
// for understanding how overloading macros works.
#define _UTIL_OVERLOAD_MACROS_JOIN(a, b) a##b
#define _UTIL_OVERLOAD_MACROS_SELECT(name, num) \
  _UTIL_OVERLOAD_MACROS_JOIN(name##_, num)
#define _UTIL_OVERLOAD_MACROS_COUNT(_1, _2, count, ...) count
#define _UTIL_OVERLOAD_MACROS_VA_SIZE(...) \
  _UTIL_OVERLOAD_MACROS_COUNT(__VA_ARGS__, 2, 1, 0)
#define UTIL_OVERLOAD_MACROS_VA_SELECT(name, ...)                          \
  _UTIL_OVERLOAD_MACROS_SELECT(name,                                       \
                               _UTIL_OVERLOAD_MACROS_VA_SIZE(__VA_ARGS__)) \
  (__VA_ARGS__)

}  // namespace util

#endif
