#include "kernel/arch/tty.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "libc/string/str.h"

namespace {

enum vga_color {
  VGA_COLOR_BLACK = 0,
  VGA_COLOR_BLUE = 1,
  VGA_COLOR_GREEN = 2,
  VGA_COLOR_CYAN = 3,
  VGA_COLOR_RED = 4,
  VGA_COLOR_MAGENTA = 5,
  VGA_COLOR_BROWN = 6,
  VGA_COLOR_LIGHT_GREY = 7,
  VGA_COLOR_DARK_GREY = 8,
  VGA_COLOR_LIGHT_BLUE = 9,
  VGA_COLOR_LIGHT_GREEN = 10,
  VGA_COLOR_LIGHT_CYAN = 11,
  VGA_COLOR_LIGHT_RED = 12,
  VGA_COLOR_LIGHT_MAGENTA = 13,
  VGA_COLOR_LIGHT_BROWN = 14,
  VGA_COLOR_WHITE = 15,
};

uint8_t VGAEntryColor(enum vga_color fg, enum vga_color bg) {
  return fg | bg << 4;
}

uint16_t VGAEntry(uint8_t uc, uint8_t color) {
  return static_cast<uint16_t>(uc) | static_cast<uint16_t>(color) << 8;
}

} // namespace

namespace arch {

// The standard TTY size and location for i386.
Terminal TTY(80, 25, reinterpret_cast<uint16_t *>(0xB8000));

void Terminal::Clear() {
  row_ = 0;
  column_ = 0;
  for (size_t i = 0; i < width_ * height_; i++) {
    Put(' ');
  }
}

void Terminal::Put(char c) {
  if (c == '\n') {
    column_ = 0;
    row_++;
  } else {
    buffer_[row_ * width_ + column_] =
        VGAEntry(c, VGAEntryColor(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK));
    column_++;
  }

  if (column_ == width_) {
    column_ = 0;
    row_++;
  }

  if (row_ == height_) {
    row_ = 0;
  }
}

void Terminal::Write(const char *data, size_t size) {
  for (size_t i = 0; i < size; i++) {
    Put(data[i]);
  }
}

void Terminal::Write(const char *data) { Write(data, libc::strlen(data)); }

} // namespace arch
