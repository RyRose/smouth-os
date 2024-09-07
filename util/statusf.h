#ifndef KERNEL_UTIL_STATUSF_H
#define KERNEL_UTIL_STATUSF_H

#include "libc/stdio.h"

namespace util {

namespace {
// Statically-allocated array of chars for statusf to use to store messages.
// TODO: Make this thread-safe.
char kStatusfMessage[1024];
size_t kStatusfCount = 0;
}  // namespace

class Statusf : public Status {
 public:
  Statusf(ErrorCode code, const char* format)
      : statusf_index_(0), raw_format_(format) {
    code_ = code;
    message_ = format;
  }

  template <typename T, typename... Args>
  Statusf(ErrorCode code, const char* format, const T& value,
          const Args&... args)
      : statusf_index_(0), raw_format_(format) {
    const auto result = libc::snprintf(kStatusfMessage, sizeof(kStatusfMessage),
                                       format, value, args...);
    if (result.Ok()) {
      kStatusfCount += 1;
      statusf_index_ = kStatusfCount;
      message_ = kStatusfMessage;
    } else {
      message_ = format;
    }
    code_ = code;
  }

  const char* Message() const override {
    if (kStatusfCount == statusf_index_) {
      return message_;
    } else {
      return raw_format_;
    }
  }

 private:
  size_t statusf_index_;
  const char* raw_format_;
};

}  // namespace util

#endif  //  KERNEL_UTIL_STATUSF_H