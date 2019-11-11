#include "kernel/arch/i386/gdt/table.h"
#include "util/status.h"

#include "libc/string.h"

namespace arch_internal {

util::StatusOr<Descriptor> Descriptor::Create(uint32_t base, uint32_t limit,
                                              uint8_t segment_type,
                                              bool descriptor_type, uint8_t dpl,
                                              bool db, bool granularity) {
  RET_CHECK((limit >> 20u) == 0, "high 12 bit of limit is non-zero");
  RET_CHECK((dpl & 0xFCu) == 0, "high 6 bits of dpl is non-zero");
  RET_CHECK((segment_type & 0xF0u) == 0,
            "high 4 bits of segment type is non-zero");

  Descriptor d;
  d.base0 = base & 0xFFFFFFu;
  d.base1 = (base >> 24u) & 0xFFu;
  d.limit0 = limit & 0xFFFFu;
  d.limit1 = (limit >> 16u) & 0xFu;
  d.segment_type = segment_type;
  d.descriptor_type = descriptor_type;
  d.dpl = dpl;
  d.present = true;
  d.db = db;
  d.granularity = granularity;
  return d;
}

}  // namespace arch_internal