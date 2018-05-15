#include "kernel/arch/tty.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "kernel/arch/i386/tty/vga.h"
#include "libc/string/str.h"

namespace {

size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer;

const size_t VGA_WIDTH = 80;
const size_t VGA_HEIGHT = 25;
uint16_t* VGA_MEMORY = reinterpret_cast<uint16_t*>(0xB8000);

void terminal_putentryat(unsigned char c, uint8_t color, size_t x, size_t y) {
  const size_t index = y * VGA_WIDTH + x;
  terminal_buffer[index] = arch::vga_entry(c, color);
}

}

namespace arch {


void terminal_initialize(void) {
  terminal_row = 0;
  terminal_column = 0;
  terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
  terminal_buffer = VGA_MEMORY;
  for (size_t y = 0; y < VGA_HEIGHT; y++) {
    for (size_t x = 0; x < VGA_WIDTH; x++) {
      const size_t index = y * VGA_WIDTH + x;
      terminal_buffer[index] = vga_entry(' ', terminal_color);
    }
  }
}

void terminal_putchar(char c) {
  unsigned char uc = c;
  if (c == '\n') {
    terminal_column = VGA_WIDTH;
  } else {
    ++terminal_column;
    terminal_putentryat(uc, terminal_color, terminal_column, terminal_row);
  }

  if (terminal_column == VGA_WIDTH) {
    terminal_column = 0;
    ++terminal_row;
  }

  if (terminal_row == VGA_HEIGHT) {
    terminal_row = 0;
  }
}

void terminal_write(const char* data, size_t size) {
  for (size_t i = 0; i < size; i++)
    terminal_putchar(data[i]);
}

void terminal_writestring(const char* data) {
  terminal_write(data, libc::strlen(data));
}

} // namespace arch
