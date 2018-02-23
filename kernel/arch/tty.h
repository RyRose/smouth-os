#ifndef KERNEL_ARCH_TTY_H
#define KERNEL_ARCH_TTY_H

#include <stddef.h>

namespace arch {

void terminal_initialize(void);
void terminal_putchar(char c);
void terminal_write(const char* data, size_t size);
void terminal_writestring(const char* data);

} // namespace arch

#endif
