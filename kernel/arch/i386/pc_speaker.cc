
#include "kernel/arch/i386/pc_speaker.h"

#include <stdint.h>

#include "kernel/arch/i386/io/io_port.h"

namespace arch {

void PCSpeaker::beep(uint16_t frequency, uint64_t iterations) {
  if (frequency == 0 || iterations == 0) {
    return;  // Invalid input
  }

  enableSpeaker();
  setFrequency(frequency);
  delay(iterations);
  disableSpeaker();
}

void PCSpeaker::enableSpeaker() {
  uint8_t port_value = system_control_port.inb();
  system_control_port.outb(port_value | 0x03);  // Enable speaker
}

void PCSpeaker::disableSpeaker() {
  uint8_t port_value = system_control_port.inb();
  system_control_port.outb(port_value & ~0x03);  // Disable speaker
}

void PCSpeaker::setFrequency(uint16_t frequency) {
  uint16_t divisor = 1193180 / frequency;
  pit_command_port.outb(0xB6);                     // Command byte for channel 2
  pit_channel_2_port.outb(divisor & 0xFF);         // Low byte of divisor
  pit_channel_2_port.outb((divisor >> 8) & 0xFF);  // High byte of divisor
}

void PCSpeaker::delay(uint64_t iterations) {
  for (volatile uint64_t i = 0; i < iterations; ++i) {
    // Simple busy-wait loop for delay
  }
}

}  // namespace arch
