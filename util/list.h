#ifndef UTIL_LIST_H
#define UTIL_LIST_H

#include <stddef.h>
#include "libc/string.h"
#include "util/status.h"

namespace util {

template <class V, size_t N>
class List {
 public:
  util::Status Add(const V& value) {
    RET_CHECK(size_ < N);
    array_[size_] = value;
    size_++;
    return {};
  }

  util::StatusOr<V*> At(size_t index) {
    RET_CHECK(0 <= index && index < size_);
    return &array_[index];
  }

  util::StatusOr<V*> At(size_t index) const {
    RET_CHECK(0 <= index && index < size_);
    return const_cast<V*>(&array_[index]);
  }

  util::Status Set(size_t index, const V& value) {
    RET_CHECK(0 <= index && index < N);
    array_[index] = value;
    if (index >= size_) {
      size_ = index + 1;
    }
    return {};
  }

  util::Status Insert(size_t index, const V& value) {
    RET_CHECK(0 <= index && index < N);
    if (index >= size_) {
      array_[index] = value;
      size_ = index + 1;
      return {};
    }
    RETURN_IF_ERROR(
        libc::memmove(&array_[index], &array_[index + 1], size_ - index));
    array_[index] = value;
    size_++;
    return {};
  }

  V* Address() const { return const_cast<V*>(array_); }
  size_t Capacity() const { return N; }
  size_t Size() const { return size_; }

 private:
  V array_[N];
  size_t size_ = 0;
};

}  // namespace util

#endif  // UTIL_LIST_H
