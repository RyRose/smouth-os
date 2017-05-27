.extern kernel_main
 
.set MB_MAGIC, 0x1BADB002          // This is a 'magic' constant that GRUB will use to detect our kernel's location.
.set MB_FLAGS, (1 << 0) | (1 << 1) // This tells GRUB to 1: load modules on page boundaries and 2: provide a memory map (this is useful later in development)
.set MB_CHECKSUM, -(MB_MAGIC + MB_FLAGS)
 
.section .multiboot
	.align 4 // Make sure the following data is aligned on a multiple of 4 bytes
	.long MB_MAGIC
	.long MB_FLAGS
	.long MB_CHECKSUM
 
.section .bss
	.align 16
	stack_bottom:
		.skip 16384 // Reserve a 1024-byte (16K) stack
	stack_top:
 
.section .text
	.global start
	.type start, @function
	start:
		mov $stack_top, %esp // Set the stack pointer to the top of the stack
		call kernel_main
 
	hang:
		cli      // Disable CPU interrupts
		hlt      // Halt the CPU
		jmp hang // If that didn't work, loop around and try again.

.size start, . - start
