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
    Status() : code(ErrorCode::OK), message("") {};
    Status(ErrorCode code, const char* message) : code(code), message(message) {};
    Status(const Status& other)
      : code(other.code),
        message(other.message) {}

    ErrorCode GetCode();
    const char* GetMessage();
    bool Ok();
  private:
    ErrorCode code;
    const char* message;
};

}

#endif
