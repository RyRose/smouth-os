#ifndef KERNEL_ARCH_I386_PC_SPEAKER_H
#define KERNEL_ARCH_I386_PC_SPEAKER_H

#include <stdint.h>

#include "kernel/arch/i386/io/io_port.h"

namespace arch {

class PCSpeaker {
 public:
  explicit PCSpeaker()
      : system_control_port(0x61),
        pit_command_port(0x43),
        pit_channel_2_port(0x42) {}

  void beep(uint16_t frequency, uint64_t iterations);

 private:
  IoPort system_control_port;
  IoPort pit_command_port;
  IoPort pit_channel_2_port;

  void enableSpeaker();
  void disableSpeaker();
  void setFrequency(uint16_t frequency);
  void delay(uint64_t duration_ms);
};

}  // namespace arch

#endif  // KERNEL_ARCH_I386_PC_SPEAKER_H
