#ifndef _KERNEL_MEMORY_MEMORY_H
#define _KERNEL_MEMORY_MEMORY_H

#include "kernel/arch/memory.h"

namespace memory {

// The maximum number of regions of memory available to use.
const int MAX_MEMORY_REGIONS = 100;

// The kernel dynamic memory allocator. Allocates free memory using an array of memory regions.
// TODO: Make a better memory allocator.
class Allocator {
  public:

    // Makes a region of memory known to the allocator.
    // Returns an error code.
    // TODO: Specify error codes.
    int AddMemory(arch::MemoryRegion region);

    // Attempts to find a spot to allocate `bytes` amount of memory.
    // Returns the starting address to a `bytes` array or nullptr if not possible.
    void* Allocate(uint64_t bytes);

    // Attempts to reserve the specified block of memory.
    // Returns an error code.
    // TODO: Specify error codes.
    int Reserve(uint64_t address, uint64_t bytes);

    // Returns the total number of memory regions.
    int GetRegionCount() { return count; }

    Allocator() = default;
    Allocator &operator=(const Allocator&) = delete;
    Allocator(const Allocator& that) = delete;
  private:

    // An array of all the regions of memory.
    arch::MemoryRegion regions[MAX_MEMORY_REGIONS];

    // The number of regions of memory.
    int count = 0;

    // Attempts to set first `bytes` to `type`.
    // Returns the address allocated.
    void* AllocateRegion(int index, uint64_t bytes, arch::MemoryRegionType type);

    // Attempts to find any region containing `address`.
    // Returns the index in the `regions` array or an error code.
    // TODO: error code
    int FindContainingRegion(uint64_t address);

    // Attempts to find an available region large enough to fit `bytes` bytes.
    // Returns the index in the `regions` array or an error code.
    // TODO: error code
    int FindFreeRegion(uint64_t bytes);
};

// Returns singleton allocator.
const Allocator* GetAllocator(); 

} // namespace memory

namespace {
  memory::Allocator ALLOCATOR;
} // namespace


#endif // _KERNEL_MEMORY_MEMORY_H
