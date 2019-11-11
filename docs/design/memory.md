# Memory

This doc looks at kernel dynamic memory allocation so we don't have awkward large buffers everywhere in the kernel.

## The First Iteration

We have the MemoryRegion (Found in kernel/arch/memory.h). For i386, this utilizes the same region types from the multiboot/0xe820 memory map. But basically, we just have regions as either AVAILABLE or "not AVAILABLE" e.g. RESERVED, BADRAM, NVS, etc. So, we start off the allocator with these regions as is in an array. Then, when we want to allocate `N` bytes of memory, the allocator does a linear scan of the regions to find an AVAILABLE region whose size > `N`. Then, the region is split such that first `N` bytes is a new RESERVED region and the latter `size - N` bytes is the old free region. It's essentially an arraylist/dynamic array of memory regions.

This doesn't have memory protections of any sort, any nice synchronization tactics, and is O(N) where `N` is the number of memory regions. We can do better but it's technically usable. This has no paging enabled.

### The GDT

The global descriptor table looks like the following:

| Base | Limit      | Accessed  |
|------|------------|------|
| 0    | 0          | 0    |
| 0    | 0xFFFFFFFF | 0x9A |
| 0    | 0xFFFFFFFF | 0x92 |

The first entry is all zeros (AKA the *null selector*) because the first entry in the GDT is unused by the processor. The second entry corresponds to the code segment selector and the third corresponds to the data selector. The latter two segment selectors allow access across the whol accessible physical address space. This is pretty common when one wants to use paging and virtual address spaces for memory protections instead of segment registers.

In addition, this corresponds to the Basic Flat Model described in section 3.2.1
of the Intel x86 System Programming Guide. This means that there is no hardware
protection by default behind accessing memory that is inaccessible for reasons
that it doesn't exist (less that 4GB of RAM) or an invalid type of memory as
specified by the system memory map returned by calling `INT 0x15, AX=0xE820`.
