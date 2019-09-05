#ifndef KERNEL_CXX_NEW_H
#define KERNEL_CXX_NEW_H

#include <stddef.h>

void *operator new(size_t);
void *operator new(size_t, void *) throw();

void *operator new[](size_t);
void *operator new[](size_t, void *) throw();

void operator delete(void *p);
void operator delete(void *p, size_t size);

void operator delete[](void *p);
void operator delete[](void *p, size_t size);

#endif //  LIBC_NEW_H
