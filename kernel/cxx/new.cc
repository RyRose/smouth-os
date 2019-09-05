#include "kernel/cxx/new.h"

#include "kernel/memory/memory.h"

#include <stddef.h>
#include <stdint.h>

void *operator new(size_t size) {
  auto *allocator = memory::GetAllocator();
  return allocator->Allocate(size);
}

void *operator new(size_t size, void *p) throw() {
  auto *allocator = memory::GetAllocator();
  if (allocator->Reserve(reinterpret_cast<uint64_t>(p), size)) {
    return nullptr;
  }
  return p;
}

void *operator new[](size_t size) {
  auto *allocator = memory::GetAllocator();
  return allocator->Allocate(size);
}

void *operator new[](size_t size, void *p) throw() {
  auto *allocator = memory::GetAllocator();
  if (allocator->Reserve(reinterpret_cast<uint64_t>(p), size)) {
    return nullptr;
  }
  return p;
}

// TODO(RyRose): Implement delete once kernel allocator supports it.
void operator delete(void *) {}
void operator delete(void *, size_t) {}

void operator delete[](void *) {}
void operator delete[](void *, size_t) {}
