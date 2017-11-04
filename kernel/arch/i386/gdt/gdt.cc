#include "kernel/arch/gdt.h"

#include <stddef.h>
#include <stdint.h>

#include "kernel/util/status.h"

namespace { 

  struct GdtEntry {
    uint32_t base;
    uint32_t limit;
    uint8_t type;
  };

  // Given a GDT entry and the save target, converts the gdt entry into
  // the correct format.
  // See this link for more details: http://wiki.osdev.org/GDT_Tutorial
  util::Status encodeGdtEntry(uint8_t *target, GdtEntry source) {
    // Check the limit to make sure that it can be encoded
    if ((source.limit > 65536) && ((source.limit & 0xFFF) != 0xFFF)) {
      return util::Status(util::ErrorCode::INVALID_ARGUMENT, "GdtEntry limit is bad.");
    }
    if (source.limit > 65536) {
      // Adjust granularity if required
      source.limit = source.limit >> 12;
      target[6] = 0xC0;
    } else if (source.limit == 0) {
      target[6] = 0;
    } else {
      target[6] = 0x40;
    }
 
    // Encode the limit
    target[0] = source.limit & 0xFF;
    target[1] = (source.limit >> 8) & 0xFF;
    target[6] |= (source.limit >> 16) & 0xF;
 
    // Encode the base 
    target[2] = source.base & 0xFF;
    target[3] = (source.base >> 8) & 0xFF;
    target[4] = (source.base >> 16) & 0xFF;
    target[7] = (source.base >> 24) & 0xFF;
 
    // And... Type
    target[5] = source.type;

    return util::Status();
  }

}

extern "C"
void gdtFlush();

uint64_t gdt_ptr;
uint8_t gdt[3 * sizeof(uint64_t)];

// Installs the global descriptor table into memory.
// See this link for more details:
// http://www.jamesmolloy.co.uk/tutorial_html/4.-The%20GDT%20and%20IDT.html
uint64_t installGdt() {
  gdt_ptr = ((uint32_t) &gdt);
  gdt_ptr <<= 16;
  gdt_ptr |= ((3 * sizeof(uint64_t)) - 1) & 0xFFFF;
  encodeGdtEntry(gdt, {.base=0, .limit=0, .type=0});
  encodeGdtEntry(gdt + sizeof(uint64_t), {.base=0, .limit=0xFFFFFFFF, .type=0x9A});
  encodeGdtEntry(gdt + 2 * sizeof(uint64_t), {.base=0, .limit=0xFFFFFFFF, .type=0x92});
  gdtFlush();
  return gdt_ptr;
}
