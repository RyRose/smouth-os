#ifndef LIBC_MOCK_KERNEL_H
#define LIBC_MOCK_KERNEL_H

#include "libc/kernel.h"

#include "util/status.h"

#include "gmock/gmock.h"

namespace libc {

class MockKernelPut : public KernelPutInterface {
 public:
  MOCK_METHOD(util::Status, Put, (char c), (override));
};

}

#endif  // LIBC_MOCK_KERNEL_H
