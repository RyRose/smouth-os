#ifndef KERNEL_ARCH_I386_INTERRUPT_MACROS_H
#define KERNEL_ARCH_I386_INTERRUPT_MACROS_H

#define _INTERRUPT_SERVICE_ROUTINE_STRINGIZE(x) #x

#define REGISTER_INTERRUPT_SERVICE_ROUTINE(name) extern "C" void name()

#define INTERRUPT_SERVICE_ROUTINE(name, function) \
  namespace {                                     \
  extern "C" void name##Internal() function       \
  }                                               \
  asm(".global " #name                              \
      "\n"                                          \
      ".align 4\n" #name                            \
      ":\n"                                         \
      "pushal\n"                                    \
      "cld\n"                                       \
      "call " _INTERRUPT_SERVICE_ROUTINE_STRINGIZE(name##Internal)   \
      "\n"                                          \
      "popal\n"                                     \
      "iret\n")

#endif  // KERNEL_ARCH_I386_INTERRUPT_MACROS_H
