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
	.skip 32768 # 32 KiB
	stack_top:

	# The kernel entry point.
	.section .text
	.global _start
	.type _start, @function
	_start:

    # Set up stack.
	movl $stack_top, %esp

    # Save the pointer twice to multiboot struct to be used in pre_kernel_main since _init
    # modifies the existing stack.
    pushl %ebx
    pushl %ebx

	# Call the global constructors. This modifies the existing stack but it shouldn't.
	# TODO(RyRose): Ensure this doesn't modify stack.
	call _init

    # Call pre-kernel main with multiboot pointer and return the BootInfo
    # struct.
	call PreKernelMain

	# Push pointer of BootInfo struct returned by pre_kernel_main
	# to be used by kernel_main.
	pushl %eax

	# Transfer control to the main kernel.
	call KernelMain

	# Hang if kernel_main unexpectedly returns.
	cli
	hang:	hlt
	jmp hang
	.size _start, . - _start
