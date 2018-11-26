        .global gdtFlush
        .type gdtFlush, @function
gdtFlush:
        pushl %ebp
        movl %esp, %ebp
        lgdt 8(%ebp)
        ljmp $0x08, $flush2     # Far jumps to set CS register to 0x08

flush2:
        mov $0x10, %ax          # Sets all the segment registers to 0x10
        mov %ax, %ds
        mov %ax, %es
        mov %ax, %fs
        mov %ax, %gs
        mov %ax, %ss
        movl %ebp, %esp
        popl %ebp
        ret
