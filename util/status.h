#ifndef KERNEL_UTIL_STATUS_H
#define KERNEL_UTIL_STATUS_H

#include "util/either.h"
#include "util/overload_macros.h"

namespace util {

enum class ErrorCode {
  OK,
  INVALID_ARGUMENT,
  BUFFER_OVERFLOW,
  INTERNAL,
  UNKNOWN
};

const char* ErrorCodeName(const ErrorCode& code);

// A class to represent if a function either resulted in an error or was ok.
class Status {
 public:
  Status() : Status(ErrorCode::OK) {}
  explicit Status(ErrorCode code) : Status(code, "") {}
  explicit Status(const char* message) : Status(ErrorCode::UNKNOWN, message) {}
  Status(ErrorCode code, const char* message)
      : code_(code), message_(message) {}

  // Returns the error code.
  ErrorCode Code() const { return code_; }

  // Returns the error message.
  const char* Message() const { return message_; }

  // Returns whether the status is ok.
  bool Ok() const { return code_ == ErrorCode::OK; }

  const Status& AsStatus() const { return *this; }

  // The type of error.
  ErrorCode code_;
  const char* message_;
};

// A class to store either an error or an useful value.
template <typename V>
class StatusOr : public Either<util::Status, V> {
 public:
  StatusOr(ErrorCode code) : Either<util::Status, V>(util::Status(code)) {}
  StatusOr(util::Status status) : Either<util::Status, V>(status) {}
  StatusOr(V value) : Either<util::Status, V>(value) {}
  StatusOr() = delete;

  bool Ok() const { return !this->is_left; }
  util::Status Status() const { return this->left; }
  const util::Status& AsStatus() const { return this->left; }
  V Value() const { return this->right; }
};

#define RETURN_IF_ERROR(expr)         \
  do {                                \
    auto _expr_result = (expr);       \
    if (!_expr_result.Ok()) {         \
      return _expr_result.AsStatus(); \
    }                                 \
  } while (0)

#define _ASSIGN_OR_RETURN_INTERNAL(status_or, lhs, expr) \
  auto status_or = (expr);                               \
  if (!status_or.Ok()) return status_or.AsStatus();      \
  lhs = status_or.Value();

#define _ASSIGN_OR_RETURN_JOIN_INTERNAL(left, right) left##right
#define _ASSIGN_OR_RETURN_JOIN(left, right) \
  _ASSIGN_OR_RETURN_JOIN_INTERNAL(left, right)

#define ASSIGN_OR_RETURN(lhs, expr)                                          \
  _ASSIGN_OR_RETURN_INTERNAL(_ASSIGN_OR_RETURN_JOIN(status_or, __COUNTER__), \
                             lhs, expr)

#define _RET_CHECK_STRINGIZE_(x) #x
#define _RET_CHECK_STRINGIZE(x) _RET_CHECK_STRINGIZE_(x)

#define RET_CHECK(...) UTIL_OVERLOAD_MACROS_VA_SELECT(RET_CHECK, __VA_ARGS__)

#define RET_CHECK_1(expr)                                                   \
  do {                                                                      \
    if (!(expr)) {                                                          \
      return util::Status(util::ErrorCode::INTERNAL, __FILE__               \
                          ":" _RET_CHECK_STRINGIZE(__LINE__) ": '" #expr    \
                                                             "' not true"); \
    }                                                                       \
  } while (0)

#define RET_CHECK_2(expr, message)                                           \
  do {                                                                       \
    if (!(expr)) {                                                           \
      return util::Status(util::ErrorCode::INTERNAL,                         \
                          __FILE__ ":" _RET_CHECK_STRINGIZE(                 \
                              __LINE__) ": '" #expr "' not true: " message); \
    }                                                                        \
  } while (0)

}  // namespace util

#endif  // KERNEL_UTIL_STATUS_H