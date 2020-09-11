        .global interrupt_service_routine
        .type interrupt_service_routine, @object
        .extern interrupt_service_routine_c
        .align 4
interrupt_service_routine:
        pushal
        cld
        call interrupt_service_routine_c
        popal
        iret
