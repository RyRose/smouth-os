#include "libc/kernel.h"

namespace libc {

KernelPutInterface* kernel_put = nullptr;
KernelPanicInterface* kernel_panic = nullptr;

}  // namespace libc