.global interrupt_service_routine
.type   interrupt_service_routine, @function
.extern interrupt_service_routine_c
.align  4

interrupt_service_routine:
	pushal                           // Save all registers before entering the C portion of the ISR.
	call interrupt_service_routine_c // Call the C portion of the ISR.
	popal                            // Restore all registers.
	iret                             // Return back to the original code that triggered the interrupt.
