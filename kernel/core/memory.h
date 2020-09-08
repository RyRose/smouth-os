#ifndef KERNEL_CORE_MEMORY_H
#define KERNEL_CORE_MEMORY_H

#include <stdint.h>

#include "kernel/arch/common/memory.h"
#include "util/list.h"
#include "util/status.h"

namespace kernel {

template <size_t N>
class BumpAllocator {
 public:
  // Create makes a bump allocator using the provided list of regions. It
  // assumes the following about the list of regions in order to provide
  // accurate allocations:
  // 1. Each available memory region is disjoint with another available region.
  // 2. If any unavailable memory regions intersects with an available
  //    region, their memory addresses must be aligned in order to
  //    be de-duped. In addition, the aligned available memory region must not
  //    be a subset of the unavailable memory region.
  //
  static util::StatusOr<BumpAllocator<N>> Create(
      const util::List<arch::MemoryRegion, N>& regions) {
    BumpAllocator<N> allocator;
    for (size_t i = 0; i < regions.Size(); i++) {
      ASSIGN_OR_RETURN(const auto& arch_region, regions.At(i));
      if (arch_region->type != arch::MemoryRegionType::AVAILABLE) {
        continue;
      }
      Region region;
      region.length = arch_region->length;
      region.address = arch_region->address;
      RETURN_IF_ERROR(allocator.regions_.Add(region));
    }

    // Subtract out reserved regions from available regions if necessary.
    for (size_t i = 0; i < allocator.regions_.Size(); i++) {
      ASSIGN_OR_RETURN(auto& region, allocator.regions_.At(i));
      for (size_t j = 0; j < regions.Size(); j++) {
        ASSIGN_OR_RETURN(const auto& arch_region, regions.At(j));
        if (arch_region->type != arch::MemoryRegionType::AVAILABLE &&
            arch_region->address == region->address) {
          region->address += arch_region->length;
          region->length -= arch_region->length;
        }
      }
    }
    return allocator;
  }

  util::StatusOr<void*> Allocate(const size_t n) {
    for (size_t i = 0; i < regions_.Size(); i++) {
      ASSIGN_OR_RETURN(auto& region, regions_.At(i));
      if (n > region->length) {
        continue;
      }
      void* address = reinterpret_cast<void*>(region->address);
      region->address += n;
      region->length -= n;
      return address;
    }
    return util::Status(util::ErrorCode::BUFFER_OVERFLOW,
                        "no available memory region");
  }

 private:
  struct Region {
    uint64_t address;
    uint64_t length;
  };
  util::List<Region, N> regions_;
};

}  // namespace kernel

#endif  // KERNEL_CORE_MEMORY_H
