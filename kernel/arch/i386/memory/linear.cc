
#include "kernel/arch/i386/memory/linear.h"

namespace arch_internal {

const char* MemoryRegionTypeName(const MemoryRegionType& type) {
  switch (type) {
    case MemoryRegionType::AVAILABLE:
      return "available";
    case MemoryRegionType::RESERVED:
      return "reserved";
    case MemoryRegionType::ACPI_RECLAIMABLE:
      return "acpi_reclaimable";
    case MemoryRegionType::NVS:
      return "nvs";
    case MemoryRegionType::BADRAM:
      return "badram";
    default:
      return "TODO(RyRose): unknown memory type";
  }
}

}  // namespace arch_internal