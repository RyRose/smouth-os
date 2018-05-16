#include "kernel/arch/io_port.h"

#include <stdint.h>

namespace arch {

void IoPort::outb(uint8_t output) {
  asm volatile ("outb %0, %1" : /* No outputs */
                              : "a" (output), "Nd" (port_number_)
      );
}

void IoPort::outw(uint16_t output) {
  asm volatile ("outw %0, %1" : /* No outputs */
                              : "a" (output), "Nd" (port_number_)
      );
}

void IoPort::outl(uint32_t output) {
  asm volatile ("outl %0, %1" : /* No outputs */
                              : "a" (output), "Nd" (port_number_)
      );
}

uint8_t IoPort::inb() {
  uint8_t ret;
  asm volatile ("inb %1, %0" : "=r" (ret)
                             : "Nd" (port_number_)
      );
  return ret;
}

uint16_t IoPort::inw() {
  uint16_t ret;
  asm volatile ("inw %1, %0" : "=r" (ret)
                             : "Nd" (port_number_)
      );
  return ret;
}

uint32_t IoPort::inl() {
  uint32_t ret;
  asm volatile ("inl %1, %0" : "=r" (ret)
                             : "Nd" (port_number_)
      );
  return ret;
}

}
