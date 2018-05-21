	# Declare constants for the multiboot header.
	.set ALIGN,    1<<0             # align loaded modules on page boundaries
	.set MEMINFO,  1<<1             # provide memory map
	.set FLAGS,    ALIGN | MEMINFO  # this is the Multiboot 'flag' field
	.set MAGIC,    0x1BADB002       # 'magic number' lets bootloader find the header
	.set CHECKSUM, -(MAGIC + FLAGS) # checksum of above, to prove we are multiboot

	# Declare a header as in the Multiboot Standard.
	.section .multiboot
	.align 4
	.long MAGIC
	.long FLAGS
	.long CHECKSUM

	# Reserve a stack for the initial thread.
	.section .bss
	.align 16
	stack_bottom:
	.skip 16384 # 16 KiB
	stack_top:

	# The kernel entry point.
	.section .text
	.global _start
	.type _start, @function
	_start:
	movl $stack_top, %esp

  pushl %ebx

	# Call the global constructors. Must not modify existing stack.
	call _init

  # Pre-main for arch-specific setup. In addition, this function must be called
  # with the initial value of the EBX register pushed onto the stack. This value
  # is a pointer to the multiboot information structure.
  call pre_kernel_main

	# Transfer control to the main kernel.
	call kernel_main

	# Hang if kernel_main unexpectedly returns.
	cli
	hang:	hlt
	jmp hang
	.size _start, . - _start
