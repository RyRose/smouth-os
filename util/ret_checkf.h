#ifndef UTIL_RET_CHECKF_H
#define UTIL_RET_CHECKF_H

#include "util/overload_macros.h"
#include "util/statusf.h"

#define RET_CHECKF(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_2(RET_CHECKF, __VA_ARGS__)

#define RET_CHECKF_1(expr) RET_CHECK_1(expr)

#define RET_CHECKF_2(expr, message) RET_CHECK_2(expr, message)

#define RET_CHECKF_N(expr, format, ...) \
  _RET_CHECKF_N(expr, format, STRINGIZE(expr), UNIQUE_VARIABLE, __VA_ARGS__)
#define _RET_CHECKF_N(expr, format, expr_string, snprintf_result, ...)         \
  do {                                                                         \
    if ((expr)) {                                                              \
      break;                                                                   \
    }                                                                          \
    return util::Statusf(util::ErrorCode::INTERNAL, __FILE__                   \
                         ":" STRINGIZE(__LINE__) ": " expr_string ": " format, \
                                       __VA_ARGS__);                           \
  } while (0)

#define _RET_CHECKF_OP(lhs, rhs, op) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, op, "%s", "INTERNAL")

#define _RET_CHECKF_OP_MESSAGE(lhs, rhs, op, message) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, op, "%s", message)

#define _RET_CHECKF_OP_FORMAT(lhs, rhs, op, format, ...)        \
  __RET_CHECKF_OP_FORMAT(lhs, rhs, op, format, UNIQUE_VARIABLE, \
                         UNIQUE_VARIABLE, __VA_ARGS__)
#define __RET_CHECKF_OP_FORMAT(lhs, rhs, op, format, lhs_, rhs_, ...) \
  do {                                                                \
    const auto lhs_ = (lhs);                                          \
    const auto rhs_ = (rhs);                                          \
    _RET_CHECKF_N(lhs_ op rhs_, "'%v " #op " %v' not true: " format,  \
                  STRINGIZE(lhs op rhs), UNIQUE_VARIABLE, lhs_, rhs_, \
                  __VA_ARGS__);                                       \
  } while (0)

#define RET_CHECKF_EQ(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_3(RET_CHECKF_EQ, __VA_ARGS__)

#define RET_CHECKF_EQ_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, ==)
#define RET_CHECKF_EQ_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, ==, message)
#define RET_CHECKF_EQ_N(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, ==, __VA_ARGS__)

#define RET_CHECKF_NE(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_3(RET_CHECKF_NE, __VA_ARGS__)

#define RET_CHECKF_NE_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, !=)
#define RET_CHECKF_NE_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, !=, message)
#define RET_CHECKF_NE_N(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, !=, __VA_ARGS__)

#define RET_CHECKF_LE(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_3(RET_CHECKF_LE, __VA_ARGS__)

#define RET_CHECKF_LE_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, <=)
#define RET_CHECKF_LE_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, <=, message)
#define RET_CHECKF_LE_N(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, <=, __VA_ARGS__)

#define RET_CHECKF_LT(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_3(RET_CHECKF_LT, __VA_ARGS__)

#define RET_CHECKF_LT_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, <)
#define RET_CHECKF_LT_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, <, message)
#define RET_CHECKF_LT_N(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, <, __VA_ARGS__)

#define RET_CHECKF_GE(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_3(RET_CHECKF_GE, __VA_ARGS__)

#define RET_CHECKF_GE_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, >=)
#define RET_CHECKF_GE_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, >=, message)
#define RET_CHECKF_GE_N(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, >=, __VA_ARGS__)

#define RET_CHECKF_GT(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_3(RET_CHECKF_GT, __VA_ARGS__)

#define RET_CHECKF_GT_2(lhs, rhs) _RET_CHECKF_OP(lhs, rhs, >)
#define RET_CHECKF_GT_3(lhs, rhs, message) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, >, message)
#define RET_CHECKF_GT_N(lhs, rhs, ...) \
  _RET_CHECKF_OP_FORMAT(lhs, rhs, >, __VA_ARGS__)

#endif  // UTIL_RET_CHECKF_H
