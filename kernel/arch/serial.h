#ifndef KERNEL_ARCH_SERIAL_H
#define KERNEL_ARCH_SERIAL_H

#include "kernel/arch/io_port.h"
#include <stdint.h>

namespace arch {

class SerialPort {
public:
  SerialPort(IoPort port)
      : port_(port), interrupt_(IoPort(port.value() + 1)),
        fifo_(IoPort(port.value() + 2)),
        line_control_(IoPort(port.value() + 3)),
        modem_control_(IoPort(port.value() + 4)),
        line_status_(IoPort(port.value() + 5)) {}

  void Initialize();
  void Write(uint8_t b);

private:
  bool IsTransmitEmpty();

  IoPort port_;
  IoPort interrupt_;
  IoPort fifo_;
  IoPort line_control_;
  IoPort modem_control_;
  IoPort line_status_;
};

extern SerialPort COM1;

} // namespace arch

#endif //  KERNEL_ARCH_SERIAL_H
