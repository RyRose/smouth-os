#ifndef KERNEL_UTIL_PANIC_H

namespace util {

// Stops the kernel and displays a message.
__attribute__((noreturn)) void panic(const char* message);
}  // namespace util

#endif  //  KERNEL_UTIL_PANIC_H
