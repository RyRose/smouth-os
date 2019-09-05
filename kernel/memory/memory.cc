#include "kernel/memory/memory.h"

#include "libc/string/mem.h"

namespace memory {

int Allocator::AddMemory(arch::MemoryRegion region) {
  if (count >= MAX_MEMORY_REGIONS) {
    return -1; // TODO: Return a better error code.
  }

  regions[count] = region;
  ++count;
  return 0;
}

// TODO: Check for overflow of `regions`.
int Allocator::Reserve(uint64_t address, uint64_t bytes) {
  if (bytes == 0)
    return 0;

  int containing_region_index = FindContainingRegion(address);
  if (containing_region_index < 0 || containing_region_index >= count) {
    return -1; // TODO: Better error for not finding a region.
  }

  arch::MemoryRegion region = regions[containing_region_index];
  if ((region.address + region.length) - address < bytes) {
    return -1; // TODO: Better error for too large to reserve.
  }

  AllocateRegion(containing_region_index, address - region.address,
                 arch::MemoryRegionType::AVAILABLE);
  AllocateRegion(containing_region_index + 1, bytes,
                 arch::MemoryRegionType::RESERVED);

  return 0;
}

// TODO: Check for overflow of `regions`.
void *Allocator::Allocate(uint64_t bytes) {
  if (bytes == 0) {
    return nullptr;
  }

  int free_index = FindFreeRegion(bytes);
  if (free_index < 0 || free_index >= count) {
    return nullptr;
  }
  return AllocateRegion(free_index, bytes, arch::MemoryRegionType::RESERVED);
}

// TODO: Check for overflow of `regions`.
// TODO: Check if bytes > region.length
void *Allocator::AllocateRegion(int index, uint64_t bytes,
                                arch::MemoryRegionType type) {
  arch::MemoryRegion region = regions[index];
  if (region.length == bytes) {
    regions[index].type = arch::MemoryRegionType::RESERVED;
  } else {
    libc::memmove(&regions[index + 1], &regions[index],
                  sizeof(arch::MemoryRegion) * (count - index));
    regions[index] = {
        /*address=*/region.address,
        /*length=*/bytes,
        /*type=*/type,
    };
    regions[index + 1].address += bytes;
    regions[index + 1].length -= bytes;
    ++count;
  }
  return reinterpret_cast<void *>(region.address);
}

int Allocator::FindContainingRegion(uint64_t address) const {
  arch::MemoryRegion region;
  for (int i = 0; i < count; i++) {
    region = regions[i];
    if (address >= region.address && address < region.address + region.length) {
      return i;
    }
  }
  return -1;
}

int Allocator::FindFreeRegion(uint64_t bytes) const {
  arch::MemoryRegion region;
  for (int i = 0; i < count; i++) {
    region = regions[i];
    if (region.type == arch::MemoryRegionType::AVAILABLE &&
        bytes <= region.length) {
      return i;
    }
  }
  return -1;
}

Allocator *GetAllocator() { return &ALLOCATOR; }

} // namespace memory
