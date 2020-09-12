#include "libc/stdio.h"
#include "libc/kernel.h"

namespace libc {

util::StatusOr<int> printf(const char* format) {
  Printer p;
  return p.Printf(format);
}

util::StatusOr<int> puts(const char* string) { return printf("%s\n", string); }

util::Status putchar(int ic) { return printf("%c", static_cast<char>(ic)); }

}  // namespace libc
