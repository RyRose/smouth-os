#ifndef KERNEL_ARCH_MEMORY_DETECTION_H
#define KERNEL_ARCH_MEMORY_DETECTION_H

#include <stdint.h>

namespace memory_detection {

enum MemoryRegionType {
  AVAILABLE = 1,
  RESERVED = 2,
  ACPI_RECLAIMABLE = 3,
  NVS = 4,
  BADRAM = 5,
};

struct MemoryRegion {
  uint64_t address;
  uint64_t length;
  MemoryRegionType type;
};

// Places into the buffer a list of `len` entries.
int DetectMemory(MemoryRegion* regions, int len);

// Returns a pointer to where the kernel image starts.
void* GetKernelStart();

// Returns a pointer to where the kernel image ends.
void* GetKernelEnd();

} // namespace memory_detection

#endif
