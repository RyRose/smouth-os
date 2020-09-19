
#include "kernel/arch/i386/gdt/table.h"

#include "util/ret_checkf.h"
#include "util/status.h"

namespace arch {

util::StatusOr<Descriptor> Descriptor::Create(uint32_t base, uint32_t limit,
                                              uint8_t segment_type,
                                              bool descriptor_type, uint8_t dpl,
                                              bool db, bool granularity) {
  RET_CHECKF_EQ(limit >> 20u, 0u, "high 12 bits of limit (0x%x) is non-zero",
                limit);
  RET_CHECKF_EQ(dpl & 0xFCu, 0u, "high 6 bits of dpl (0x%x) is non-zero", dpl);
  RET_CHECKF_EQ(segment_type & 0xF0u, 0u,
                "high 4 bits of segment type (0x%x) is non-zero", segment_type);

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

}  // namespace arch