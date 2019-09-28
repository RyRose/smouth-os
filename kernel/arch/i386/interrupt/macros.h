#ifndef KERNEL_ARCH_I386_INTERRUPT_MACROS_H
#define KERNEL_ARCH_I386_INTERRUPT_MACROS_H

#define INTERRUPT_SERVICE_ROUTINE(NAME, C_FUNCTION)                            \
  asm(".global " #NAME "\n"                                                    \
      ".align 4\n" #NAME ":\n"                                                 \
      "pushal\n"                                                               \
      "cld\n"                                                                  \
      "call " #C_FUNCTION "\n"                                                 \
      "popal\n"                                                                \
      "iret\n");

#endif // KERNEL_ARCH_I386_INTERRUPT_MACROS_H
