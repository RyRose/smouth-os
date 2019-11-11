#include "kernel/arch/i386/serial/serial.h"
#include "kernel/arch/i386/io_port/io_port.h"

namespace arch_internal {

SerialPort SerialPort::Create(IoPort port, IoPort interrupt, IoPort fifo,
                              IoPort line_control, IoPort modem_control,
                              IoPort line_status) {
  auto serial_port =
      SerialPort(/*port=*/port, /*interrupt=*/interrupt, /*fifo=*/fifo,
                 /*line_control=*/line_control, /*modem_control=*/modem_control,
                 /*line_status=*/line_status);
  serial_port.Initialize();
  return serial_port;
}

void SerialPort::Initialize() {
  interrupt_.outb(0x00);      // Disable all interrupts
  line_control_.outb(0x80);   // Enable DLAB (set baud rate divisor)
  port_.outb(0x03);           // Set divisor to 3 (lo byte) 38400 baud
  interrupt_.outb(0x00);      //                  (hi byte)
  line_control_.outb(0x03);   // 8 bits, no parity, one stop bit
  fifo_.outb(0xC7);           // Enable FIFO, clear them, with 14-byte threshold
  modem_control_.outb(0x0B);  // IRQs enabled, RTS/DSR set
}

bool SerialPort::IsTransmitEmpty() { return (line_status_.inb() & 0x20u) == 0; }

void SerialPort::Write(uint8_t b) {
  while (IsTransmitEmpty()) {
  }
  port_.outb(b);
}

}  // namespace arch_internal
