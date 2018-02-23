# Memory

This doc looks at kernel dynamic memory allocation so we don't have awkward large buffers everywhere in the kernel. 

## The First Iteration

We have the MemoryRegion (Found in kernel/arch/memory.h). For i386, this utilizes the same region types from the multiboot/0xe820 memory map. But basically, we just have regions as either AVAILABLE or "not AVAILABLE" e.g. RESERVED, BADRAM, NVS, etc. So, we start off the allocator with these regions as is in an array. Then, when we want to allocate `N` bytes of memory, the allocator does a linear scan of the regions to find an AVAILABLE region whose size > `N`. Then, the region is split such that first `N` bytes is a new RESERVED region and the latter `size - N` bytes is the old free region. It's essentially an arraylist/dynamic array of memory regions.

This doesn't have memory protections of any sort, any nice synchronization tactics, and is O(N) where `N` is the number of memory regions. We can do better but it's technically usable.
