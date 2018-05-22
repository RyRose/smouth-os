#ifndef KERNEL_ARCH_I386_BOOT_GDT_H
#define KERNEL_ARCH_I386_BOOT_GDT_H

#include <stdint.h>
#include <stddef.h>

namespace boot {

// An entry in the global descriptor table.
class GdtEntry {
  public:
    // Returns the gdt entry encoded as an 8 byte entry to be inserted into the
    // Global Descriptor Table.
    virtual uint64_t Get() = 0;
};

// A segment selector for the global descriptor table.
class SegmentSelector {
  public:
    SegmentSelector(uint32_t base, uint32_t limit, uint8_t type)
      : base_(base), limit_(limit), type_(type) {}

    uint64_t Get();
  private:

    // The base memory address of the selector
    uint32_t base_;

    // The maximum size the selector can reach.
    uint32_t limit_;

    // The access byte that describes the seelctor.
    // TODO(RyRose): Abstract this into it's own class?
    uint8_t type_;
};

} // namespace boot

#endif // KERNEL_ARCH_I386_BOOT_GDT_H

