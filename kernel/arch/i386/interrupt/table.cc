#include "kernel/arch/i386/interrupt/table.h"

#include "util/status.h"

namespace arch_internal {

util::StatusOr<GateDescriptor> GateDescriptor::Create(uint32_t offset,
                                                      uint16_t segment_selector,
                                                      GateType gate_type,
                                                      uint8_t dpl) {
  RET_CHECK((dpl & 0xF0u) == 0,
            "descriptor privilege level must only be four bits");

  GateDescriptor descriptor;
  descriptor.offset_first = offset & 0xFFFFu;
  descriptor.offset_second = offset >> 16u;
  descriptor.segment_selector = segment_selector;
  descriptor.gate_type = gate_type;
  descriptor.dpl = dpl;
  descriptor.present = true;
  return descriptor;
}

}  // namespace arch_internal
