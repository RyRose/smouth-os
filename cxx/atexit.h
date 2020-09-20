#ifndef CXX_ATEXIT_H
#define CXX_ATEXIT_H

extern "C" {
int __cxa_atexit(void (*)(void*), void*, void*);
void __cxa_finalize(void*);
}

#endif  // CXX_ATEXIT_H
