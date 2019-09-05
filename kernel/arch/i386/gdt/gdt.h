#ifndef KERNEL_ARCH_I386_GDT_GDT_H
#define KERNEL_ARCH_I386_GDT_GDT_H

#include <stddef.h>
#include <stdint.h>

namespace gdt {

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
// limit => limit0_, limit1_
//    limit is the max number of (4-kilo)bytes the segment described addresses.
//    If granularity is true, then the unit is 4-kilobytes. Else, bytes. It is
//    20 bits.
// base => base0_, base1_
//    base is the base linear memory address for which the segment described
//    addresses.
// type => segment_type_
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
// S => descriptor_type_
//   True if the segment is a code/data segment. Else, it's a system segment.
// DPL => dpl_
//   DPL is the descriptor privilege level.
// P => present_
//   P indicates whether the segment should be considered present by the
//   processor.
// AVL => available_
//   AVL is set when the descriptor should be used for system software.
//   Always set to false. Should only be used by the processor.
//   TODO(RyRose): Why would this ever be true?
// L => bit64_
//   If set, the segment type must be a code segment and it indicates the
//   segment contains 64-bit code. Since we don't use IA-32e mode and this is
//   for i386 processors, this is always set to false.
// DB => db_
//   db stands for for Default/Big and has different meanings based on the
//   segment and descriptor type. Should always be set for 32-bit code/data
//   segments and never set for 16-bit code/data segments.
// G => granularity_
//   G determines the scaling of the limit field as described above.
//

class Descriptor {
public:
  Descriptor()
      : limit0_(0), base0_(0), segment_type_(0), descriptor_type_(false),
        dpl_(0), db_(0), present_(false), limit1_(0), available_(false),
        bit64_(false), granularity_(false), base1_(0) {}

  Descriptor(uint32_t base, uint32_t limit, uint8_t segment_type,
             bool descriptor_type, uint8_t dpl, bool db, bool present,
             bool granularity)
      : limit0_(limit & 0xFFFF), base0_(base & 0xFFFFFF),
        segment_type_(segment_type), descriptor_type_(descriptor_type),
        dpl_(dpl), present_(present), limit1_((limit >> 16) & 0xF),
        available_(false), bit64_(false), db_(db), granularity_(granularity),
        base1_(base >> 24) {}

private:
  uint16_t limit0_ : 16;
  uint32_t base0_ : 24;
  uint8_t segment_type_ : 4;
  bool descriptor_type_ : 1;
  uint8_t dpl_ : 2;
  bool present_ : 1;
  uint8_t limit1_ : 4;
  bool available_ : 1;
  bool bit64_ : 1;
  bool db_ : 1;
  bool granularity_ : 1;
  uint8_t base1_ : 8;
} __attribute__((packed));

static_assert(sizeof(Descriptor) == 8, "GDT descriptors must be eight bytes!");

// THE global descriptor table.
extern Descriptor GDT[];

} // namespace gdt

#endif // KERNEL_ARCH_I386_GDT_GDT_H
