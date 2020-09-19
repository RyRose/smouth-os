#ifndef CXX_NEW_H
#define CXX_NEW_H

#include <stddef.h>

#if __STDC_HOSTED__
#include <new>
#else

namespace std {

struct nothrow_t {
  explicit nothrow_t() = default;
};

const nothrow_t nothrow;

}  // namespace std

void* operator new(size_t count, const std::nothrow_t& tag) noexcept;
void* operator new[](size_t count, const std::nothrow_t& tag) noexcept;

void* operator new(size_t);
void* operator new[](size_t);

void* operator new(size_t, void*) noexcept;
void* operator new[](size_t, void*) noexcept;

void operator delete(void* p) noexcept;
void operator delete[](void* p) noexcept;

void operator delete(void* p, size_t size) throw();
void operator delete[](void* p, size_t size) throw();

#endif

#endif  //  CXX_NEW_H
