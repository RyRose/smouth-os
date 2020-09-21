#ifndef UTIL_RET_CHECKF_H
#define UTIL_RET_CHECKF_H

#include "libc/stdio.h"
#include "util/overload_macros.h"
#include "util/status.h"

namespace util {
// Statically-allocated array of chars for RET_CHECKF to fall back to use if
// unable to allocate the message on the heap.
extern char kRetCheckfMessage[1024];
}  // namespace util

#define RET_CHECKF(...) \
  UTIL_OVERLOAD_MACROS_VA_SELECT_2(RET_CHECKF, __VA_ARGS__)

#define RET_CHECKF_1(expr) RET_CHECK_1(expr)

#define RET_CHECKF_2(expr, message) RET_CHECK_2(expr, message)

#define RET_CHECKF_N(expr, format, ...)                                       \
  _RET_CHECKF_N(expr, format, MAKE_UNIQUE(_asprintf_message),                 \
                MAKE_UNIQUE(_asprintf_result), MAKE_UNIQUE(_snprintf_result), \
                __VA_ARGS__)
#define _RET_CHECKF_N(expr, format, _asprintf_message, _asprintf_result,       \
                      _snprintf_result, ...)                                   \
  do {                                                                         \
    if ((expr)) {                                                              \
      break;                                                                   \
    }                                                                          \
    char* _asprintf_message;                                                   \
    auto _asprintf_result =                                                    \
        libc::asprintf(&_asprintf_message, "%s:%d: %s: " format, __FILE__,     \
                       __LINE__, #expr, __VA_ARGS__);                          \
    if (_asprintf_result.Ok()) {                                               \
      return util::Status(util::ErrorCode::INTERNAL, _asprintf_message);       \
    }                                                                          \
    auto _snprintf_result = libc::snprintf(                                    \
        util::kRetCheckfMessage, sizeof(util::kRetCheckfMessage),              \
        "%s:%d: %s: " format, __FILE__, __LINE__, #expr, __VA_ARGS__);         \
    if (_snprintf_result.Ok()) {                                               \
      return util::Status(util::ErrorCode::INTERNAL, util::kRetCheckfMessage); \
    }                                                                          \
    return util::Status(util::ErrorCode::INTERNAL, format);                    \
  } while (0)

#define _RET_CHECKF_N_NOEXPR(expr, format, ...)                       \
  __RET_CHECKF_N_NOEXPR(expr, format, MAKE_UNIQUE(_asprintf_message), \
                        MAKE_UNIQUE(_asprintf_result),                \
                        MAKE_UNIQUE(_snprintf_result), __VA_ARGS__)
#define __RET_CHECKF_N_NOEXPR(expr, format, _asprintf_message,                 \
                              _asprintf_result, _snprintf_result, ...)         \
  do {                                                                         \
    if ((expr)) {                                                              \
      break;                                                                   \
    }                                                                          \
    char* _asprintf_message;                                                   \
    auto _asprintf_result =                                                    \
        libc::asprintf(&_asprintf_message, "%s:%d: " format, __FILE__,         \
                       __LINE__, __VA_ARGS__);                                 \
    if (_asprintf_result.Ok()) {                                               \
      return util::Status(util::ErrorCode::INTERNAL, _asprintf_message);       \
    }                                                                          \
    auto _snprintf_result = libc::snprintf(                                    \
        util::kRetCheckfMessage, sizeof(util::kRetCheckfMessage),              \
        "%s:%d: " format, __FILE__, __LINE__, __VA_ARGS__);                    \
    if (_snprintf_result.Ok()) {                                               \
      return util::Status(util::ErrorCode::INTERNAL, util::kRetCheckfMessage); \
    }                                                                          \
    return util::Status(util::ErrorCode::INTERNAL, format);                    \
  } while (0)

#define _RET_CHECKF_OP(lhs, rhs, op) \
  _RET_CHECKF_OP_MESSAGE(lhs, rhs, op, "INTERNAL")

#define _RET_CHECKF_OP_MESSAGE(lhs, rhs, op, message)               \
  __RET_CHECKF_OP_MESSAGE(lhs, rhs, op, message, MAKE_UNIQUE(lhs_), \
                          MAKE_UNIQUE(rhs_))
#define __RET_CHECKF_OP_MESSAGE(lhs, rhs, op, message, lhs_, rhs_)           \
  do {                                                                       \
    auto lhs_ = (lhs);                                                       \
    auto rhs_ = (rhs);                                                       \
    _RET_CHECKF_N_NOEXPR(                                                    \
        lhs_ op rhs_, #lhs " (%v) " #op " " #rhs " (%v) not true: " message, \
        lhs_, rhs_);                                                         \
  } while (0)

#define _RET_CHECKF_OP_FORMAT(lhs, rhs, op, format, ...)          \
  __RET_CHECKF_OP_FORMAT(lhs, rhs, op, format, MAKE_UNIQUE(lhs_), \
                         MAKE_UNIQUE(rhs_), __VA_ARGS__)
#define __RET_CHECKF_OP_FORMAT(lhs, rhs, op, format, lhs_, rhs_, ...)          \
  do {                                                                         \
    auto lhs_ = (lhs);                                                         \
    auto rhs_ = (rhs);                                                         \
    _RET_CHECKF_N_NOEXPR(lhs_ op rhs_,                                         \
                         #lhs " (%v) " #op " " #rhs " (%v) not true: " format, \
                         lhs_, rhs_, __VA_ARGS__);                             \
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
