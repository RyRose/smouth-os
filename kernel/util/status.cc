#include "kernel/util/status.h"

namespace util {

  ErrorCode Status::GetCode() {
    return code;
  }

  const char* Status::GetMessage() {
    return message;
  }

  bool Status::Ok() {
    return code == ErrorCode::OK;
  }
  
}
