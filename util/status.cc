
#include "util/status.h"

namespace util {

const char* ErrorCodeName(const ErrorCode& code) {
  switch (code) {
    case ErrorCode::OK:
      return "ok";
    case ErrorCode::INVALID_ARGUMENT:
      return "invalid argument";
    case ErrorCode::BUFFER_OVERFLOW:
      return "buffer overflow";
    case ErrorCode::INTERNAL:
      return "internal error";
    case ErrorCode::UNKNOWN:
      return "unknown error";
    default:
      return "TODO(RyRose): error case unhandled";
  }
}

}  // namespace util