#ifndef LIBC_KERNEL_H
#define LIBC_KERNEL_H

#include "util/status.h"

namespace libc {

class KernelPutInterface {
 public:
  virtual util::Status Put(char c) = 0;
};

extern KernelPutInterface* kernel_put;

class KernelPanicInterface {
 public:
  virtual void Panic(const char* message) = 0;
};

extern KernelPanicInterface* kernel_panic;

}  // namespace libc

#endif  // LIBC_KERNEL_H
