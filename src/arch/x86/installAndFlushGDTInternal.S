// void installAndFlushGDTInternal(gdt_ptr: u64): Installs a new Global Descriptor Table (GDT)
// using the provided pointer.
.global installAndFlushGDTInternal
.type   installAndFlushGDTInternal, @function
installAndFlushGDTInternal:
	pushl %ebp
	movl  %esp, %ebp
	lgdt  8(%ebp)
	ljmp  $0x08, $flush // Far jumps to set CS register to 0x08

flush:
	mov  $0x10, %ax // Sets all the segment registers to 0x10
	mov  %ax, %ds
	mov  %ax, %es
	mov  %ax, %fs
	mov  %ax, %gs
	mov  %ax, %ss
	movl %ebp, %esp
	popl %ebp
	ret
