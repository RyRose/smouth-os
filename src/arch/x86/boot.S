// Declare constants for the multiboot header.
.set ALIGN, 1<<0                // align loaded modules on page boundaries
.set MEMINFO, 1<<1              // provide memory map
.set FLAGS, ALIGN | MEMINFO     // this is the Multiboot 'flag' field
.set MAGIC, 0x1BADB002          // 'magic number' lets bootloader find the header
.set CHECKSUM, -(MAGIC + FLAGS) // checksum of above, to prove we are multiboot

// Declare a header as in the Multiboot Standard.
.section .multiboot
.align   4
.long    MAGIC
.long    FLAGS
.long    CHECKSUM

// Reserve a stack for the initial thread.
.section .bss
.align   16
stack_bottom:
	.skip 16384 // 16 KiB
stack_top:

// The kernel entry point.
.section .text
.global  _start
.type    _start, @function
_start:

	// Set up stack.
	movl $stack_top, %esp

	// Save the pointer to the multiboot struct to be used in PreKernelMain.
	// pushl %ebx

	// Transfer control to the kernel main function
	call kmain

// Hang if kernel_main unexpectedly returns.
hang:
	// Disable interrupts.
	cli
	// Try to halt.
	hlt
	// Repeat.
	jmp hang
.size _start, . - _start
