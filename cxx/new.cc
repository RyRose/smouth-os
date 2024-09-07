#include "cxx/new.h"

#include <stddef.h>

#include "cxx/kernel.h"

#if !(__STDC_HOSTED__)

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
    cxx::KernelPanic("kernel new unavailable for new* allocation");
  }
  auto ptr_or = cxx::kernel_new(count);
  if (!ptr_or.Ok()) {
    cxx::KernelPanic(ptr_or.AsStatus().Message());
  }
  return ptr_or.Value();
}

void* operator new[](size_t count) {
  if (cxx::kernel_new == nullptr) {
    cxx::KernelPanic("kernel new unavailable for new[] allocation");
  }
  auto ptr_or = cxx::kernel_new(count);
  if (!ptr_or.Ok()) {
    cxx::KernelPanic(ptr_or.AsStatus().Message());
  }
  return ptr_or.Value();
}

// In-place new assumes that caller knows the memory address of ptr to be valid.
void* operator new(size_t, void* ptr) noexcept { return ptr; }
void* operator new[](size_t, void* ptr) noexcept { return ptr; }

void operator delete(void*) noexcept {
  cxx::KernelPanic("kernel delete unavailable for delete* call");
}

void operator delete[](void*) noexcept {
  cxx::KernelPanic("kernel delete unavailable for delete[] call");
}

// Dummy implementations of delete here to ensure the linker doesn't complain.
void operator delete(void*, size_t) throw() {
  cxx::KernelPanic("kernel delete unavailable for incomplete delete* call");
}
void operator delete[](void*, size_t) throw() {
  cxx::KernelPanic("kernel delete unavailable for incomplete delete[] call");
}

#endif  // __STDC_HOSTED__
