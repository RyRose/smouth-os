        .extern gdt_ptr
        .global gdtFlush
        .type gdtFlush, @function
gdtFlush:
        lgdt (gdt_ptr)
        ljmp $0x08, $flush2     # Far jumps to set CS register to 0x08

flush2:
        mov $0x10, %ax          # Sets all the segment registers to 0x10
        mov %ax, %ds
        mov %ax, %es
        mov %ax, %fs
        mov %ax, %gs
        mov %ax, %ss
        ret
