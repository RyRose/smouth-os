#ifndef TESTING_ASSERT_H
#define TESTING_ASSERT_H

#include <ostream>

#include "util/status.h"

namespace util {

std::ostream& operator<<(std::ostream& stream, const Status& status) {
  const auto& code = util::ErrorCodeName(status.Code());
  const char* msg = status.Message();
  return stream << "{code: " << code << ", message: \"" << msg << "\"}";
}

}  // namespace util

namespace testing {

#define _TESTING_FORMAT_INTERNAL(expr, status) \
  " Literal: " << expr << "\n  Status: " << status

#define EXPECT_NOT_OK(expr)                                          \
  do {                                                               \
    auto expr_result_ = (expr);                                      \
    EXPECT_FALSE(expr_result_.Ok())                                  \
        << _TESTING_FORMAT_INTERNAL(#expr, expr_result_.AsStatus()); \
  } while (0)

#define EXPECT_OK(expr)                                              \
  do {                                                               \
    auto expr_result_ = (expr);                                      \
    EXPECT_TRUE(expr_result_.Ok())                                   \
        << _TESTING_FORMAT_INTERNAL(#expr, expr_result_.AsStatus()); \
  } while (0)

#define ASSERT_NOT_OK(expr)                                          \
  do {                                                               \
    auto expr_result_ = (expr);                                      \
    ASSERT_FALSE(expr_result_.Ok())                                  \
        << _TESTING_FORMAT_INTERNAL(#expr, expr_result_.AsStatus()); \
  } while (0)

#define ASSERT_OK(expr)                                              \
  do {                                                               \
    auto expr_result_ = (expr);                                      \
    ASSERT_TRUE(expr_result_.Ok())                                   \
        << _TESTING_FORMAT_INTERNAL(#expr, expr_result_.AsStatus()); \
  } while (0)

#define _ASSERT_OK_AND_ASSIGN_INTERNAL(status_or, lhs, expr)      \
  auto status_or = (expr);                                        \
  do {                                                            \
    ASSERT_TRUE(status_or.Ok())                                   \
        << _TESTING_FORMAT_INTERNAL(#expr, status_or.AsStatus()); \
  } while (0);                                                    \
  lhs = status_or.Value();

#define _ASSERT_OK_AND_ASSIGN_JOIN_INTERNAL(left, right) left##right

#define _ASSERT_OK_AND_ASSIGN_JOIN(left, right) \
  _ASSERT_OK_AND_ASSIGN_JOIN_INTERNAL(left, right)

#define ASSERT_OK_AND_ASSIGN(lhs, expr) \
  _ASSERT_OK_AND_ASSIGN_INTERNAL(       \
      _ASSERT_OK_AND_ASSIGN_JOIN(status_or, __COUNTER__), lhs, expr)

}  // namespace testing

#endif  // TESTING_ASSERT_H
