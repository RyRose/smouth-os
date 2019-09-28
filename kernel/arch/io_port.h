#ifndef KERNEL_ARCH_IO_PORT_H
#define KERNEL_ARCH_IO_PORT_H

#include <stdint.h>

namespace arch {

// A class that represents an IO port to be read and/or written to.
class IoPort {
public:
  explicit IoPort(uint16_t port_number) : port_number_(port_number) {}

  // Writes a byte to the IO port.
  void outb(uint8_t output);

  // Writes a word (2 bytes) to the IO port.
  void outw(uint16_t output);

  // Writes a long (4 bytes) to the IO port.
  void outl(uint32_t output);

  // Reads a byte from the IO port.
  uint8_t inb();

  // Reads a word (2 bytes) from the IO port.
  uint16_t inw();

  // Reads a long (4 bytes) from the IO port.
  uint32_t inl();

  // The raw port number.
  uint16_t value() { return port_number_; }

private:
  // Integer that specifies the IO port.
  uint16_t port_number_;
};

} // namespace arch

#endif // KERNEL_ARCH_IO_PORT_H
