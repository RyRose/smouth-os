#include "cxx/new.h"

#ifndef CXX_NEW_STUB_CONFIG

#include <stddef.h>

#include "cxx/kernel.h"

namespace {
void panic(const char* message) {
  if (cxx::kernel_panic != nullptr) {
    cxx::kernel_panic(message);
  }
  // Fall back to infinite loop if kernel panic does not exist or returns.
  while (true) {
  }
}
}  // namespace

void* operator new(size_t size) {
  if (cxx::kernel_new == nullptr) {
    panic("kernel new unavailable for new* allocation");
  }
  auto ptr_or = cxx::kernel_new(size);
  if (!ptr_or.Ok()) {
    panic(ptr_or.Status().Message());
  }
  return ptr_or.Value();
}

void* operator new[](size_t size) {
  if (cxx::kernel_new == nullptr) {
    panic("kernel new unavailable for new[] allocation");
  }
  auto ptr_or = cxx::kernel_new(size);
  if (!ptr_or.Ok()) {
    panic(ptr_or.Status().Message());
  }
  return ptr_or.Value();
}

void operator delete(void*) {
  panic("TODO(RyRose): kernel delete unavailable for delete* call");
}

void operator delete[](void*) {
  panic("TODO(RyRose): kernel delete unavailable for delete[] call");
}

// In-place new assumes that caller knows the memory address of p to be valid.
void* operator new(size_t, void* p) throw() { return p; }
void* operator new[](size_t, void* p) throw() { return p; }

// Dummy implementations of delete here to ensure the linker doesn't complain.
void operator delete(void*, size_t) throw() {}
void operator delete[](void*, size_t) throw() {}

#endif  // CXX_NEW_STUB_CONFIG
