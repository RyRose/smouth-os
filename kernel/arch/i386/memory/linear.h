#ifndef KERNEL_MEMORY_LINEAR_H
#define KERNEL_MEMORY_LINEAR_H

#include <stddef.h>

#include "kernel/arch/i386/boot/multiboot.h"
#include "kernel/arch/memory.h"
#include "util/list.h"
#include "util/status.h"

namespace arch {

enum class MemoryRegionType {
  AVAILABLE = 1,
  RESERVED = 2,
  ACPI_RECLAIMABLE = 3,
  NVS = 4,
  BADRAM = 5,
};

const char* MemoryRegionTypeName(const MemoryRegionType& type);

struct MemoryRegion {
  uint64_t address;
  uint64_t length;
  MemoryRegionType type;
};

// The kernel dynamic memory allocator. Allocates free memory using an array of
// memory regions.
template <size_t N>
class LinearAllocator : public arch::Allocator {
 public:
  static util::StatusOr<LinearAllocator> Create(
      util::List<multiboot_mmap_entry, N>& multiboot_entries) {
    LinearAllocator allocator;
    for (size_t i = 0; i < multiboot_entries.Size(); i++) {
      ASSIGN_OR_RETURN(auto* entry, multiboot_entries.At(i));
      allocator.regions_.Add(
          {/*address=*/entry->addr, /*length=*/entry->len,
           /*type=*/static_cast<MemoryRegionType>(entry->type)});
    }
    return allocator;
  }

  // Attempts to find a spot to allocate `bytes` amount of memory.
  // Returns the starting address to a `bytes` array or nullptr if not possible.
  util::StatusOr<void*> Allocate(size_t bytes) override {
    if (bytes == 0) {
      return nullptr;
    }

    ASSIGN_OR_RETURN(const auto& free_index, FindFreeRegion(bytes));
    return AllocateRegion(free_index, bytes, MemoryRegionType::RESERVED);
  }

  util::List<MemoryRegion, N>& Regions() const {
    return const_cast<util::List<MemoryRegion, N>&>(regions_);
  }

 private:
  util::List<MemoryRegion, N> regions_;

  // Attempts to set first `bytes` to `type`.
  // Returns the address allocated.
  util::StatusOr<void*> AllocateRegion(int index, uint64_t bytes,
                                       MemoryRegionType type) {
    ASSIGN_OR_RETURN(auto* region, regions_.At(index));
    RET_CHECK(bytes < region->length);
    if (region->length == bytes) {
      region->type = MemoryRegionType::RESERVED;
    } else {
      regions_.Insert(index, {
                                 /*address=*/region->address,
                                 /*length=*/bytes,
                                 /*type=*/type,
                             });
      ASSIGN_OR_RETURN(auto* above, regions_.At(index + 1));

      above->address += bytes;
      above->length -= bytes;
    }
    return reinterpret_cast<void*>(region->address);
  }

  // Attempts to find an available region large enough to fit `bytes` bytes.
  // Returns the index in the `regions` array or an error code.
  util::StatusOr<int> FindFreeRegion(uint64_t bytes) const {
    MemoryRegion* region;
    for (size_t i = 0; i < regions_.Size(); i++) {
      ASSIGN_OR_RETURN(region, regions_.At(i));
      if (region->type == MemoryRegionType::AVAILABLE &&
          bytes <= region->length) {
        return i;
      }
    }
    return util::Status(util::ErrorCode::INVALID_ARGUMENT,
                        "no available free region.");
  }
};

}  // namespace arch

#endif  // KERNEL_MEMORY_LINEAR_H
