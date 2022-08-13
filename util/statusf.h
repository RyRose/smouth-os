#ifndef KERNEL_UTIL_STATUSF_H
#define KERNEL_UTIL_STATUSF_H

#include "libc/stdio.h"

namespace util {

namespace {
// Statically-allocated array of chars for statusf to use to store messages.
// TODO: Make this thread-safe.
char kStatusfMessage[1024];
}

template<typename T, typename... Args>
class Statusf : public Status {
 public:
  Statusf(
      ErrorCode code,
      const char *format,
      const T &value,
      const Args &... args
  ) {
    const auto result = libc::snprintf(kStatusfMessage, sizeof(kStatusfMessage),
                                       format, value, args...);
    if (result.Ok()) {
      message_ = kStatusfMessage;
    } else {
      message_ = format;
    }
    code_ = code;
  }
};

} // namespace util

#endif //  KERNEL_UTIL_STATUSF_H