#ifndef UTIL_META_MACROS_H
#define UTIL_META_MACROS_H

// STRINGIZE returns the provided expression as a string.
#define STRINGIZE(expr) _STRINGIZE(expr)
#define _STRINGIZE(expr) #expr

// CONCATENATE returns the expression on the left-hand side (lhs) concatenated
// with the expression on the right-hand side (rhs).
#define CONCATENATE(lhs, rhs) _CONCATENATE(lhs, rhs)
#define _CONCATENATE(lhs, rhs) lhs##rhs

// MAKE_UNIQUE returns the expression such that it can be uniquely identified.
#define MAKE_UNIQUE(expr) CONCATENATE(expr, __COUNTER__)

#endif  // UTIL_META_MACROS_H
