#include "kernel/arch/serial.h"
#include "kernel/arch/io_port.h"

namespace arch {

void SerialPort::Initialize() {
  interrupt_.outb(0x00);     // Disable all interrupts
  line_control_.outb(0x80);  // Enable DLAB (set baud rate divisor)
  port_.outb(0x03);          // Set divisor to 3 (lo byte) 38400 baud
  interrupt_.outb(0x00);     //                  (hi byte)
  line_control_.outb(0x03);  // 8 bits, no parity, one stop bit
  fifo_.outb(0xC7);          // Enable FIFO, clear them, with 14-byte threshold
  modem_control_.outb(0x0B); // IRQs enabled, RTS/DSR set
}

bool SerialPort::IsTransmitEmpty() { return line_status_.inb() & 0x20 == 0; }

void SerialPort::Write(uint8_t b) {
  while (IsTransmitEmpty()) {
  }
  port_.outb(b);
}

SerialPort COM1(IoPort(0x3F8));

} // namespace arch
