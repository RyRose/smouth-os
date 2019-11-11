#ifndef KERNEL_UTIL_OPTIONAL_H
#define KERNEL_UTIL_OPTIONAL_H

#include <stdint.h>
#include "cxx/new.h"

namespace util {

template <typename V>
class Optional {
 public:
  Optional() : value_{}, exists_(false) {}
  Optional(V val) : exists_(true) { new (&value_) V(val); }
  ~Optional() {
    if (Exists()) {
      Value().~V();
    }
  }

  V& Value() { return reinterpret_cast<V&>(value_); }
  bool Exists() { return exists_; }

 private:
  alignas(V) uint8_t value_[sizeof(V)];
  bool exists_;
};

}  // namespace util

#endif  //  KERNEL_UTIL_OPTIONAL_H
