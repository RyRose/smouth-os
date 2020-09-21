#ifndef KERNEL_UTIL_STATUS_H
#define KERNEL_UTIL_STATUS_H

#include "util/either.h"
#include "util/meta_macros.h"
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

template <class T>
class StatusOr;

// A class to represent if a function either resulted in an error or was ok.
class Status {
 public:
  Status() : Status(ErrorCode::OK) {}
  template <class T>
  Status(StatusOr<T> status_or) : Status(status_or.AsStatus()) {}
  explicit Status(ErrorCode code) : Status(code, "") {}
  // TODO(RyRose): Free the memory from strings passed in this way.
  explicit Status(char* message) : Status(const_cast<const char*>(message)) {}
  explicit Status(const char* message) : Status(ErrorCode::UNKNOWN, message) {}

  Status(ErrorCode code, const char* message)
      : code_(code), message_(message) {}

  Status(const util::Status&) = default;

  // Returns the error code.
  ErrorCode Code() const { return code_; }

  // Returns the error message.
  const char* Message() const { return message_; }

  // Returns whether the status is ok.
  bool Ok() const { return code_ == ErrorCode::OK; }

  Status AsStatus() const { return *this; }

 private:
  // The type of error.
  ErrorCode code_;
  const char* message_;
};

// A class to store either an error or an useful value.
template <typename V>
class StatusOr : public Either<util::Status, V> {
 public:
  StatusOr(const ErrorCode& code)
      : Either<util::Status, V>(util::Status(code)) {}
  StatusOr(const util::Status& status) : Either<util::Status, V>(status) {}
  StatusOr(const V& value) : Either<util::Status, V>(value) {}
  StatusOr() = delete;

  bool Ok() const { return !this->is_left; }
  util::Status AsStatus() const {
    if (this->Ok()) {
      return {};
    }
    return this->left;
  }
  const V& Value() const { return this->right; }
};

#define RETURN_IF_ERROR(expr) _RETURN_IF_ERROR(expr, MAKE_UNIQUE(expr_result_))
#define _RETURN_IF_ERROR(expr, expr_result_) \
  do {                                       \
    auto expr_result_ = (expr);              \
    if (expr_result_.Ok()) {                 \
      break;                                 \
    }                                        \
    return expr_result_.AsStatus();          \
  } while (0)

#define ASSIGN_OR_RETURN(lhs, expr) \
  _ASSIGN_OR_RETURN(lhs, expr, MAKE_UNIQUE(status_or_))
#define _ASSIGN_OR_RETURN(lhs, expr, status_or_)      \
  auto status_or_ = (expr);                           \
  if (!status_or_.Ok()) return status_or_.AsStatus(); \
  lhs = status_or_.Value();

#define RET_CHECK(...) UTIL_OVERLOAD_MACROS_VA_SELECT_2(RET_CHECK, __VA_ARGS__)

#define RET_CHECK_1(expr)                                                  \
  do {                                                                     \
    if ((expr)) {                                                          \
      break;                                                               \
    }                                                                      \
    return util::Status(util::ErrorCode::INTERNAL, __FILE__                \
                        ":" STRINGIZE(__LINE__) ": '" #expr "' not true"); \
  } while (0)

#define RET_CHECK_2(expr, message)                                       \
  do {                                                                   \
    if ((expr)) {                                                        \
      break;                                                             \
    }                                                                    \
    return util::Status(util::ErrorCode::INTERNAL, __FILE__              \
                        ":" STRINGIZE(__LINE__) ": '" #expr              \
                                                "' not true: " message); \
  } while (0)

}  // namespace util

#endif  // KERNEL_UTIL_STATUS_H
