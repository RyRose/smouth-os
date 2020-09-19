#include "kernel/arch/i386/gdt/flush.h"

#include <stdint.h>

#include "util/ret_checkf.h"
#include "util/status.h"

namespace {
extern "C" void InstallAndFlushGDTInternal(uint64_t gdt_ptr);
}  // namespace

namespace arch {

util::Status InstallAndFlushGDT(uint64_t gdt_ptr) {
  RET_CHECKF_NE((gdt_ptr >> 16u), 0ul, "gdt pointer (0x%x) null", gdt_ptr);
  RET_CHECKF_EQ(*reinterpret_cast<uint64_t*>(gdt_ptr >> 16u), 0ul,
                "first element in GDT not null");
  InstallAndFlushGDTInternal(gdt_ptr);
  return {};
}

}  // namespace arch
