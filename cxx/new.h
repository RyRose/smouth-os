#ifndef CXX_NEW_STUB_CONFIG
#ifndef CXX_NEW_H
#define CXX_NEW_H

#include <stddef.h>

void* operator new(size_t);

void* operator new[](size_t);

void operator delete(void* p) noexcept;

void operator delete[](void* p) noexcept;

void* operator new(size_t, void*) noexcept;
void* operator new[](size_t, void*) noexcept;
void operator delete(void* p, size_t size) throw();
void operator delete[](void* p, size_t size) throw();

#endif  //  CXX_NEW_H
#endif  // CXX_NEW_STUB_CONFIG
