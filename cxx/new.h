#ifndef CXX_NEW_H
#define CXX_NEW_H

#if __STDC_HOSTED__
#include <new>
#else

#include <stddef.h>

namespace std {

struct nothrow_t {
  explicit nothrow_t() = default;
};

constexpr const nothrow_t nothrow;

}  // namespace std

void* operator new(size_t count, const std::nothrow_t& tag) noexcept;
void* operator new[](size_t count, const std::nothrow_t& tag) noexcept;

void* operator new(size_t count);
void* operator new[](size_t count);

void* operator new(size_t count, void* ptr) noexcept;
void* operator new[](size_t count, void* ptr) noexcept;

void operator delete(void* ptr) noexcept;
void operator delete[](void* ptr) noexcept;

void operator delete(void* ptr, size_t sz) throw();
void operator delete[](void* ptr, size_t sz) throw();

#endif

#endif  //  CXX_NEW_H
