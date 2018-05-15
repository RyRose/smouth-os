#ifndef _KERNEL_UTIL_STATUS_H

namespace util {

enum ErrorCode {
  OK,
  INVALID_ARGUMENT,
  UNIMPLEMENTED,
  UNKNOWN
};

class Status {
  public:
    Status() : Status(ErrorCode::OK, "") {};
    Status(ErrorCode code, const char* message) : code_(code), message_(message) {};

    ErrorCode GetCode();
    const char* GetMessage();
    bool Ok();
  private:
    ErrorCode code_;
    const char* message_;
};

}

#endif
