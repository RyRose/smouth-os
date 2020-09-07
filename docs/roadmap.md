# Roadmap

This document explores the next steps to achieve the goal of playing smash
mouth.

## Work Remaining

- Implement driver to read a file from outside QEMU into memory. I could see
  this being the serial port, CD Rom, floppy disk, or hard disk.
  - Implement and test reading from serial port.
  - Implement and test reading from CD ROM.
  - Create File abstraction that allows creating a file from either.
- Implement driver to interact with the virtual audio device in QEMU.
  - Implement thin driver that wraps functionality of the virtual audio device.
- Implement module that plays file in-memory using the audio driver.
  - Parser for the file format (AVI?) of the music.
  - Interpreter for the parsed data into commands for the driver.
- Play music from emulator out of my speakers.
