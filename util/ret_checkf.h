#ifndef UTIL_RET_CHECKF_H
#define UTIL_RET_CHECKF_H

#include "libc/stdio.h"
#include "util/overload_macros.h"
#include "util/status.h"

#define RET_CHECKF(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_3(_RET_CHECKF, __VA_ARGS__)

#define _RET_CHECKF_1(expr) RET_CHECK(expr)

#define _RET_CHECKF_2(expr, message) RET_CHECK(expr, message)

#define _RET_CHECKF_3(expr, format, ...)                                      \
  do {                                                                        \
    if ((expr)) {                                                             \
      break;                                                                  \
    }                                                                         \
    char* _message;                                                           \
    RETURN_IF_ERROR(libc::asprintf(&_message, "%s:%d: %s: " format, __FILE__, \
                                   __LINE__, #expr, __VA_ARGS__));            \
    return util::Status(util::ErrorCode::INTERNAL, _message);                 \
  } while (0)

#define _RET_CHECKF_OP(lhs, rhs, op) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, op, "INTERNAL")

#define _RET_CHECKF_OP_MESSAGE(lhs, rhs, op, message)                       \
  do {                                                                      \
    auto _lhs = (lhs);                                                      \
    auto _rhs = (rhs);                                                      \
    RET_CHECKF(_lhs op _rhs,                                                \
               #lhs " (%v) " #op " " #rhs " (%v) not true: " message, _lhs, \
               _rhs);                                                       \
  } while (0)

#define _RET_CHECKF_OP_FORMAT(lhs, rhs, op, format, ...)                   \
  do {                                                                     \
    auto _lhs = (lhs);                                                     \
    auto _rhs = (rhs);                                                     \
    RET_CHECKF(_lhs op _rhs,                                               \
               #lhs " (%v) " #op " " #rhs " (%v) not true: " format, _lhs, \
               _rhs, __VA_ARGS__);                                         \
  } while (0)

#define RET_CHECKF_EQ(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_4(_RET_CHECKF_EQ, __VA_ARGS__)

#define _RET_CHECKF_EQ_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, ==)
#define _RET_CHECKF_EQ_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, ==, message)
#define _RET_CHECKF_EQ_4(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, ==, __VA_ARGS__)

#define RET_CHECKF_NE(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_4(_RET_CHECKF_NE, __VA_ARGS__)

#define _RET_CHECKF_NE_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, !=)
#define _RET_CHECKF_NE_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, !=, message)
#define _RET_CHECKF_NE_4(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, !=, __VA_ARGS__)

#define RET_CHECKF_LE(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_4(_RET_CHECKF_LE, __VA_ARGS__)

#define _RET_CHECKF_LE_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, <=)
#define _RET_CHECKF_LE_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, <=, message)
#define _RET_CHECKF_LE_4(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, <=, __VA_ARGS__)

#define RET_CHECKF_LT(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_4(_RET_CHECKF_LT, __VA_ARGS__)

#define _RET_CHECKF_LT_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, <)
#define _RET_CHECKF_LT_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, <, message)
#define _RET_CHECKF_LT_4(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, <, __VA_ARGS__)

#define RET_CHECKF_GE(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_4(_RET_CHECKF_GE, __VA_ARGS__)

#define _RET_CHECKF_GE_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, >=)
#define _RET_CHECKF_GE_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, >=, message)
#define _RET_CHECKF_GE_4(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, >=, __VA_ARGS__)

#define RET_CHECKF_GT(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_4(_RET_CHECKF_GT, __VA_ARGS__)

#define _RET_CHECKF_GT_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, >)
#define _RET_CHECKF_GT_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, >, message)
#define _RET_CHECKF_GT_4(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, >, __VA_ARGS__)

#endif  // UTIL_RET_CHECKF_H
