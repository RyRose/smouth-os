#ifndef KERNEL_ARCH_I386_SERIAL_H
#define KERNEL_ARCH_I386_SERIAL_H

#include "kernel/arch/i386/io/io_port.h"
#include "kernel/arch/serial.h"

namespace arch {

class SerialPort : public arch::SerialPortInterface {
 public:
  static SerialPort Create(IoPort port, IoPort interrupt, IoPort fifo,
                           IoPort line_control, IoPort modem_control,
                           IoPort line_status);

  void Write(uint8_t b) override;

 protected:
  SerialPort(IoPort port, IoPort interrupt, IoPort fifo, IoPort line_control,
             IoPort modem_control, IoPort line_status)
      : port_(port),
        interrupt_(interrupt),
        fifo_(fifo),
        line_control_(line_control),
        modem_control_(modem_control),
        line_status_(line_status) {}

 private:
  void Initialize();

  bool IsTransmitEmpty();

  IoPort port_;
  IoPort interrupt_;
  IoPort fifo_;
  IoPort line_control_;
  IoPort modem_control_;
  IoPort line_status_;
};

}  // namespace arch

#endif  // KERNEL_ARCH_I386_SERIAL_H
