#ifndef KERNEL_ARCH_I386_GDT_GDT_H
#define KERNEL_ARCH_I386_GDT_GDT_H

#include <stddef.h>
#include <stdint.h>

#include "util/list.h"
#include "util/status.h"

namespace arch_internal {

// Descriptor is a class that represents a Global Descriptor Table (GDT) segment
// descriptor. It provides the processor with size, location, access, and status
// information about a segment. It is correctly packed and thus usable directly
// in the GDT. It is formatted as follows:
//
//  31          24 23 22 21  20 19 16 15 14 13 12 11   8 7               0
// |----------------------------------------------------------------------|
// |  base 31:24  |G |DB|L |AVL|limit|P | DPL |S | type |   base 23:16    | 4
// |----------------------------------------------------------------------|
//  31                              16 15                                0
// |----------------------------------------------------------------------|
// |          base 15:00              |            limit 15:00            | 0
// |----------------------------------------------------------------------|
//
// Where each map to the following:
// limit => limit0, limit1
//    limit is the max number of (4-kilo)bytes the segment described addresses.
//    If granularity is true, then the unit is 4-kilobytes. Else, bytes. It is
//    20 bits.
// base => base0, base1
//    base is the base linear memory address for which the segment described
//    addresses.
// type => segment_type
//    type corresponds whether the segment is for data or code along with read,
//    write, execute permissions.
//
//            Bit Index
//    Hex Dec 11 10 9 8
//    0   0   0  0  0 0 Data Read-Only
//    1   1   0  0  0 1 Data Read-Only, accessed
//    2   2   0  0  1 0 Data Read/Write
//    3   3   0  0  1 1 Data Read/Write, accessed
//    4   4   0  1  0 0 Data Read-Only, expand-down
//    5   5   0  1  0 1 Data Read-Only, expand-down, accessed
//    6   6   0  1  1 0 Data Read/Write, expand-down
//    7   7   0  1  1 1 Data Read/Write, expand-down, accessed
//    8   8   1  0  0 0 Code Execute-Only
//    9   9   1  0  0 1 Code Execute-Only, accessed
//    A   10  1  0  1 0 Code Execute/Read
//    B   11  1  0  1 1 Code Execute/Read, accessed
//    C   12  1  1  0 0 Code Execute-Only, conforming
//    D   13  1  1  0 1 Code Execute-Only, conforming, accessed
//    E   14  1  1  1 0 Code Execute/Read, conforming
//    F   15  1  1  1 1 Code Execute/Read, conforming, accessed
//
// S => descriptor_type
//   True if the segment is a code/data segment. Else, it's a system segment.
// DPL => dpl
//   DPL is the descriptor privilege level.
// P => present
//   P indicates whether the segment should be considered present by the
//   processor.
// AVL => available
//   AVL is set when the descriptor should be used for system software.
//   Always set to false. Should only be used by the processor.
//   TODO(RyRose): Why would this ever be true?
// L => bit64
//   If set, the segment type must be a code segment and it indicates the
//   segment contains 64-bit code. Since we don't use IA-32e mode and this is
//   for i386 processors, this is always set to false.
// DB => db
//   db stands for for Default/Big and has different meanings based on the
//   segment and descriptor type. Should always be set for 32-bit code/data
//   segments and never set for 16-bit code/data segments.
// G => granularity
//   G determines the scaling of the limit field as described above.
//
class Descriptor {
 public:
  // Creates a present Descriptor and validates the provided arguments.
  static util::StatusOr<Descriptor> Create(uint32_t base, uint32_t limit,
                                           uint8_t segment_type,
                                           bool descriptor_type, uint8_t dpl,
                                           bool db, bool granularity);

  // Creates a null Descriptor.
  Descriptor()
      : limit0(0),
        base0(0),
        segment_type(0),
        descriptor_type(false),
        dpl(0),
        present(false),
        limit1(0),
        available(false),
        bit64(false),
        db(false),
        granularity(false),
        base1(0) {}

  uint16_t limit0 : 16;
  uint32_t base0 : 24;
  uint8_t segment_type : 4;
  bool descriptor_type : 1;
  uint8_t dpl : 2;
  bool present : 1;
  uint8_t limit1 : 4;
  bool available : 1;
  bool bit64 : 1;
  bool db : 1;
  bool granularity : 1;
  uint8_t base1 : 8;
} __attribute__((packed));

static_assert(sizeof(Descriptor) == 8, "GDT descriptors must be eight bytes!");

template <size_t N>
class GlobalDescriptorTable {
 public:
  util::Status Register(size_t index, Descriptor descriptor) {
    return table_.Insert(index, descriptor);
  }

  uint64_t Pointer() {
    auto gdt_ptr = reinterpret_cast<uint64_t>(table_.Address());
    gdt_ptr <<= 16u;
    gdt_ptr |= (3u * sizeof(uint64_t)) & 0xFFFFu;
    return gdt_ptr;
  }

 private:
  util::List<Descriptor, N> table_;
};

}  // namespace arch_internal

#endif  // KERNEL_ARCH_I386_GDT_GDT_H
