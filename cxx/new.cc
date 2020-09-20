#include "cxx/new.h"

#if !(__STDC_HOSTED__)

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

void* operator new(size_t count, const std::nothrow_t&) noexcept {
  if (cxx::kernel_new == nullptr) {
    return nullptr;
  }
  auto ptr_or = cxx::kernel_new(count);
  if (!ptr_or.Ok()) {
    return nullptr;
  }
  return ptr_or.Value();
}

void* operator new[](size_t count, const std::nothrow_t&) noexcept {
  if (cxx::kernel_new == nullptr) {
    return nullptr;
  }
  auto ptr_or = cxx::kernel_new(count);
  if (!ptr_or.Ok()) {
    return nullptr;
  }
  return ptr_or.Value();
}

void* operator new(size_t count) {
  if (cxx::kernel_new == nullptr) {
    panic("kernel new unavailable for new* allocation");
  }
  auto ptr_or = cxx::kernel_new(count);
  if (!ptr_or.Ok()) {
    panic(ptr_or.AsStatus().Message());
  }
  return ptr_or.Value();
}

void* operator new[](size_t count) {
  if (cxx::kernel_new == nullptr) {
    panic("kernel new unavailable for new[] allocation");
  }
  auto ptr_or = cxx::kernel_new(count);
  if (!ptr_or.Ok()) {
    panic(ptr_or.AsStatus().Message());
  }
  return ptr_or.Value();
}

// In-place new assumes that caller knows the memory address of ptr to be valid.
void* operator new(size_t, void* ptr) noexcept { return ptr; }
void* operator new[](size_t, void* ptr) noexcept { return ptr; }

void operator delete(void*)noexcept {
  panic("kernel delete unavailable for delete* call");
}

void operator delete[](void*) noexcept {
  panic("kernel delete unavailable for delete[] call");
}

// Dummy implementations of delete here to ensure the linker doesn't complain.
void operator delete(void*, size_t) throw() {
  panic("kernel delete unavailable for incomplete delete* call");
}
void operator delete[](void*, size_t) throw() {
  panic("kernel delete unavailable for incomplete delete[] call");
}

#endif  // __STDC_HOSTED__
