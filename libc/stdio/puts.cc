#include "libc/stdio.h"
#include "util/status.h"

namespace libc {

util::StatusOr<int> puts(const char* string) { return printf("%s\n", string); }

}  // namespace libc
