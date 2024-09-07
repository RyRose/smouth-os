#include "libc/stdio.h"

#include "libc/kernel.h"

namespace libc {

util::StatusOr<int> printf(const char* format) {
  Printer p;
  return p.Printf(format);
}

util::StatusOr<int> sprintf(char* buffer, const char* format) {
  Printer p(PrintType::BUFFER, buffer);
  return p.Printf(format);
}

util::StatusOr<int> snprintf(char* buffer, size_t bufsz, const char* format) {
  Printer p(PrintType::BUFFER_MAXIMUM, buffer, bufsz);
  return p.Printf(format);
}

util::StatusOr<int> asprintf(char** strp, const char* format) {
  Printer dry_runner(PrintType::DRY_RUN);
  ASSIGN_OR_RETURN(const int len, dry_runner.Printf(format));
  *strp = new (std::nothrow) char[len];
  RET_CHECK(*strp != nullptr);
  Printer p(PrintType::BUFFER, *strp);
  return p.Printf(format);
}

util::StatusOr<int> puts(const char* string) { return printf("%s\n", string); }

util::Status putchar(int ic) { return printf("%c", static_cast<char>(ic)); }

}  // namespace libc
