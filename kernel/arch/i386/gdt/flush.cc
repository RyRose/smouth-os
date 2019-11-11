#include "kernel/arch/i386/gdt/flush.h"

#include "util/status.h"

#include <stdint.h>

namespace {
extern "C" void InstallAndFlushGDTInternal(uint64_t gdt_ptr);
}  // namespace

namespace arch_internal {

util::Status InstallAndFlushGDT(uint64_t gdt_ptr) {
  RET_CHECK((gdt_ptr >> 16u) != 0, "gdt pointer null");
  RET_CHECK(*reinterpret_cast<uint64_t*>(gdt_ptr >> 16u) == 0,
            "first element in GDT not null");
  InstallAndFlushGDTInternal(gdt_ptr);
  return {};
}

}  // namespace arch_internal
