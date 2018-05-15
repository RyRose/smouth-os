#include "kernel/util/status.h"

namespace util {

  ErrorCode Status::GetCode() {
    return code_;
  }

  const char* Status::GetMessage() {
    return message_;
  }

  bool Status::Ok() {
    return code_ == ErrorCode::OK;
  }
  
}
