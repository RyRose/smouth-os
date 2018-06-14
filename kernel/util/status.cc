#include "kernel/util/status.h"

namespace util {

ErrorCode Status::GetCode() const { return code_; }

bool Status::ok() const { return code_ == ErrorCode::OK; }

}  // namespace util
