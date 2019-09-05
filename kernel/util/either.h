#ifndef KERNEL_UTIL_EITHER_H
#define KERNEL_UTIL_EITHER_H

namespace util {

template <typename Left, typename Right> class Either {
public:
  Either(Left left_) : left(left_), is_left(true) {}
  Either(Right right_) : right(right_), is_left(false) {}
  Either() = delete;

  union {
    Left left;
    Right right;
  };
  bool is_left;
};

} // namespace util

#endif //  KERNEL_UTIL_EITHER_H
