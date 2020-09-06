#ifndef KERNEL_ARCH_SERIAL_H
#define KERNEL_ARCH_SERIAL_H

#include <stdint.h>

namespace arch {

class SerialPortInterface {
 public:
  virtual void Write(uint8_t b) = 0;
};

}  // namespace arch

#endif  //  KERNEL_ARCH_SERIAL_H
