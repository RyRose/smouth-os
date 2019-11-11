#ifndef KERNEL_ARCH_COMMON_TTY_H
#define KERNEL_ARCH_COMMON_TTY_H

#include <stddef.h>
#include <stdint.h>

#include "util/status.h"

namespace arch {

class Terminal {
 public:
  static util::StatusOr<Terminal> Create(size_t width, size_t height,
                                         uint16_t* buffer);

  void Clear();
  void Put(char c);
  util::Status Write(const char* data);
  void Write(const char* data, size_t size);

 protected:
  Terminal(size_t width, size_t height, uint16_t* buffer)
      : width_(width), height_(height), buffer_(buffer), row_(0), column_(0) {}

 private:
  size_t width_;
  size_t height_;
  uint16_t* buffer_;

  size_t row_;
  size_t column_;
};

}  // namespace arch

#endif
