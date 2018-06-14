#ifndef KERNEL_UTIL_STATUS_H
#define KERNEL_UTIL_STATUS_H

#include "kernel/util/either.h"

namespace util {

enum class ErrorCode { OK, INVALID_ARGUMENT, UNIMPLEMENTED, UNKNOWN };

// A class to represent if a function either resulted in an error or was ok.
class Status {
 public:
  Status() : Status(ErrorCode::OK) {}
  explicit Status(ErrorCode code) : code_(code) {}

  // Returns the error code.
  ErrorCode GetCode() const;

  // Returns whether the status is ok.
  bool ok() const;

 private:
  // The type of error.
  ErrorCode code_;
};

// A class to store either an error or a useful value.
template <class V>
class StatusOr : public Either<Status, V> {
 public:
  StatusOr(ErrorCode code) : Either<Status, V>(Status(code)) {}
  StatusOr(Status status) : Either<Status, V>(status) {}
  StatusOr(V value) : Either<Status, V>(value) {}
  StatusOr() = delete;

  bool ok() const { return !this->is_left; }
  Status status() const { return this->left; }
  V value() const { return this->right; }
};

}  // namespace util

#endif  // KERNEL_UTIL_STATUS_H
