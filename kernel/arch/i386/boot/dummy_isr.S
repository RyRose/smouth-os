        .global handleDummyInterrupt
        .align  4
handleDummyInterrupt:
        pushal
        cld
        call dummy_handler
        popal
        iret
