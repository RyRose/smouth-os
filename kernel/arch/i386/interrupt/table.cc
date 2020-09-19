#include "kernel/arch/i386/interrupt/table.h"

#include "util/ret_checkf.h"
#include "util/status.h"

namespace arch {

util::StatusOr<GateDescriptor> GateDescriptor::Create(uint32_t offset,
                                                      uint16_t segment_selector,
                                                      GateType gate_type,
                                                      uint8_t dpl) {
  RET_CHECKF_EQ((dpl & 0xF0u), 0u,
                "descriptor privilege level (0x%x) must only be four bits",
                dpl);

  GateDescriptor descriptor;
  descriptor.offset_first = offset & 0xFFFFu;
  descriptor.offset_second = offset >> 16u;
  descriptor.segment_selector = segment_selector;
  descriptor.gate_type = static_cast<uint8_t>(gate_type);
  descriptor.dpl = dpl;
  descriptor.present = true;
  return descriptor;
}

}  // namespace arch
