/**
 * ULTIMATE HELLO WORLD - A foray into C's capabilities in the name of
education.
 *
 * This is the most comprehensive "Hello World" program ever written,
 * demonstrating virtually every feature of the C programming language
 * from basic concepts to cutting-edge C23 features and obscure techniques
 * that even veteran C programmers might not have encountered.
 *
 * Compilation:
 * gcc -std=c2x -Wall -Wextra -pedantic -O3 -march=native -pthread -lm -ldl
-fstack-protector-all -D_FORTIFY_SOURCE=2 -fPIC -fno-strict-aliasing
-finline-functions -funroll-loops -ftree-vectorize hello_ultimate.c -o
hello_world
 * Note: Some features require specific compiler support:
 * - C11 features: gcc 4.9+ or clang 3.1+
 * - C23 features: gcc 13+ or clang 16+
 * - SIMD intrinsics: -march=native or specific -mavx2
 * - Dynamic code generation: Requires executable stack (security consideration)
Requires following tweaks:
 * ⚠️ WARNING: Only for educational purposes, never in production!
 * Disable ASLR temporarily
 * echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
 * Compile with relaxed security
gcc -std=c2x -Wall -Wextra -O3 -march=native -pthread -lm -ldl \
    -z execstack -no-pie -fno-stack-protector \
    hello_ultimate.c -o hello_world_unsafe
 * Run it
./hello_world_unsafe
 * Re-enable ASLR afterward
echo 2 | sudo tee /proc/sys/kernel/randomize_va_space
 * This program demonstrates:
 * 1. Basic C concepts (variables, functions, control flow)
 * 2. Advanced data structures (unions, bit fields, flexible array members)
 * 3. Memory management (custom allocators, arena allocation, object pools)
 * 4. Concurrency (threads, atomics, lock-free programming, memory barriers)
 * 5. System programming (signals, dynamic code generation, stack unwinding)
 * 6. Modern C features (C11/C23 additions)
 * 7. Performance optimization (SIMD, cache alignment, prefetching)
 * 8. Preprocessor metaprogramming (X-macros, token pasting, variadic macros)
 * 9. Security features (stack canaries, FORTIFY_SOURCE, secure erasure)
 * 10. Platform-specific optimizations and inline assembly
 * 11. Advanced type system abuse and compiler introspection
 * 12. And much, much more!
 */

/* Enable GNU extensions for advanced features */
#define _GNU_SOURCE
#define _DEFAULT_SOURCE

/* Enable FORTIFY_SOURCE for security hardening */
#ifndef _FORTIFY_SOURCE
#define _FORTIFY_SOURCE 2
#endif

/*
 * #include statements import header files containing function declarations
 * and macro definitions. These are similar to "import" in other languages.
 * We're including an extensive set to demonstrate various C capabilities.
 */
#include <assert.h>    /* Debugging macro - assert() for runtime checks */
#include <complex.h>   /* Complex numbers - complex arithmetic support */
#include <dlfcn.h>     /* Dynamic linking - dlopen(), dlsym() */
#include <errno.h>     /* Error codes - errno, EINVAL, etc. */
#include <execinfo.h>  /* Stack traces - backtrace() */
#include <immintrin.h> /* SIMD intrinsics - for parallel processing */
#include <inttypes.h>  /* Format macros for exact-width integers */
#include <limits.h>    /* Implementation limits - INT_MAX, CHAR_BIT, etc. */
#include <math.h>      /* Mathematical functions - sin(), cos(), sqrt() */
#include <pthread.h>   /* POSIX threads for debug memory leak mutex */
#include <setjmp.h>    /* Non-local jumps - setjmp/longjmp (like exceptions) */
#include <signal.h>    /* Signal handling - for catching Ctrl+C, etc. */
#include <stdarg.h>    /* Variable arguments - for variadic functions */
#include <stdatomic.h> /* C11 Atomic operations - for lock-free programming */
#include <stdbool.h>   /* Boolean type - provides 'bool', 'true', 'false' */
#include <stddef.h>    /* Standard definitions - size_t, offsetof, NULL */
#include <stdint.h>    /* Exact-width integers - uint64_t, int32_t, etc. */
#include <stdio.h>     /* Standard I/O - for printf(), fprintf(), etc. */
#include <stdlib.h>    /* Standard Library - malloc(), free(), exit() */
#include <string.h>    /* String handling - strcpy(), strlen(), memset() */
#include <sys/mman.h>  /* Memory mapping - mmap() for executable memory */
#include <sys/time.h>  /* High-resolution timing */
#include <threads.h>   /* C11 Threading support - portable threads */
#include <time.h>      /* Time functions - time(), clock(), etc. */
#include <unistd.h>    /* POSIX API - for advanced system calls */

/*
 * Conditional compilation checks which C standard version we're using.
 * __STDC_VERSION__ is defined by the compiler to indicate the standard.
 * 201112L = C11 (2011 December)
 * 202311L = C23 (2023 November)
 */
#ifdef __STDC_VERSION__
#if __STDC_VERSION__ >= 201112L
#define C11_AVAILABLE 1
#include <stdalign.h>    /* Alignment support - alignof, alignas */
#include <stdnoreturn.h> /* _Noreturn function specifier */
#include <uchar.h>       /* Unicode character types */
#endif
#if __STDC_VERSION__ >= 202311L
#define C23_AVAILABLE 1
#include <stdbit.h>    /* Bit manipulation utilities */
#include <stdckdint.h> /* Checked integer arithmetic */
#endif
#endif

/* Terminal visuals */
/* ANSI Color and Visual Effects */
#define RESET "\033[0m"
#define BOLD "\033[1m"
#define DIM "\033[2m"
#define ITALIC "\033[3m"
#define UNDERLINE "\033[4m"
#define BLINK "\033[5m"
#define REVERSE "\033[7m"
#define STRIKETHROUGH "\033[9m"

/* Foreground Colors */
#define BLACK "\033[30m"
#define RED "\033[31m"
#define GREEN "\033[32m"
#define YELLOW "\033[33m"
#define BLUE "\033[34m"
#define MAGENTA "\033[35m"
#define CYAN "\033[36m"
#define WHITE "\033[37m"

/* Bright Colors */
#define BRIGHT_BLACK "\033[90m"
#define BRIGHT_RED "\033[91m"
#define BRIGHT_GREEN "\033[92m"
#define BRIGHT_YELLOW "\033[93m"
#define BRIGHT_BLUE "\033[94m"
#define BRIGHT_MAGENTA "\033[95m"
#define BRIGHT_CYAN "\033[96m"
#define BRIGHT_WHITE "\033[97m"

/* Background Colors */
#define BG_BLACK "\033[40m"
#define BG_RED "\033[41m"
#define BG_GREEN "\033[42m"
#define BG_YELLOW "\033[43m"
#define BG_BLUE "\033[44m"
#define BG_MAGENTA "\033[45m"
#define BG_CYAN "\033[46m"
#define BG_WHITE "\033[47m"

/* RGB Colors (24-bit) */
#define RGB(r, g, b) "\033[38;2;" #r ";" #g ";" #b "m"
#define BG_RGB(r, g, b) "\033[48;2;" #r ";" #g ";" #b "m"

/* Cursor Control */
#define CLEAR_SCREEN "\033[2J\033[H"
#define CLEAR_LINE "\033[2K"
#define SAVE_CURSOR "\033[s"
#define RESTORE_CURSOR "\033[u"
#define HIDE_CURSOR "\033[?25l"
#define SHOW_CURSOR "\033[?25h"

/* Box Drawing Characters */
#define BOX_H "─"
#define BOX_V "│"
#define BOX_TL "┌"
#define BOX_TR "┐"
#define BOX_BL "└"
#define BOX_BR "┘"
#define BOX_CROSS "┼"
#define BOX_T "┬"
#define BOX_B "┴"
#define BOX_L "├"
#define BOX_R "┤"

/* Special Symbols */
#define ARROW_RIGHT "→"
#define ARROW_LEFT "←"
#define ARROW_UP "↑"
#define ARROW_DOWN "↓"
#define CHECKMARK "✓"
#define CROSSMARK "✗"
#define WARNING "⚠"
#define INFO "ℹ"
#define GEAR "⚙"
#define LIGHTNING "⚡"
#define FIRE "🔥"
#define ROCKET "🚀"
#define DIAMOND "◆"
#define STAR "★"
#define CIRCLE "●"
#define SQUARE "■"

/* Progress Bar Characters */
#define PROGRESS_FULL "█"
#define PROGRESS_PART "▓"
#define PROGRESS_EMPTY "░"
/*
 * COMPILER DETECTION AND FEATURE MACROS
 * Different compilers provide different extensions and intrinsics
 */
#ifdef __GNUC__
#define GCC_VERSION                                                            \
  (__GNUC__ * 10000 + __GNUC_MINOR__ * 100 + __GNUC_PATCHLEVEL__)
#define LIKELY(x) __builtin_expect(!!(x), 1)
#define UNLIKELY(x) __builtin_expect(!!(x), 0)
#define PREFETCH(x) __builtin_prefetch(x)
#define UNREACHABLE() __builtin_unreachable()
#define ASSUME_ALIGNED(p, a) __builtin_assume_aligned(p, a)
#define POPCOUNT(x) __builtin_popcountll(x)
#define CLZ(x) __builtin_clzll(x)
#define CTZ(x) __builtin_ctzll(x)
#else
#define LIKELY(x) (x)
#define UNLIKELY(x) (x)
#define PREFETCH(x) ((void)0)
#define UNREACHABLE() abort()
#define ASSUME_ALIGNED(p, a) (p)
#define POPCOUNT(x) generic_popcount(x)
#define CLZ(x) generic_clz(x)
#define CTZ(x) generic_ctz(x)
#endif

/*
 * ADVANCED FUNCTION ATTRIBUTES
 * These give the compiler additional information for optimization
 */
#ifdef __GNUC__
#define PURE_FUNC __attribute__((pure))
#define CONST_FUNC __attribute__((const))
#define HOT_FUNC __attribute__((hot))
#define COLD_FUNC __attribute__((cold))
#define FLATTEN_FUNC __attribute__((flatten))
#define NOINLINE_FUNC __attribute__((noinline))
#define ALWAYS_INLINE __attribute__((always_inline))
#define WARN_UNUSED __attribute__((warn_unused_result))
#define DEPRECATED(msg) __attribute__((deprecated(msg)))
#define CLEANUP(func) __attribute__((cleanup(func)))
#define PACKED __attribute__((packed))
#define ALIGNED(n) __attribute__((aligned(n)))
#define FORMAT(type, fmt, args) __attribute__((format(type, fmt, args)))
#define WEAK __attribute__((weak))
#define ALIAS(name) __attribute__((alias(#name)))
#define CONSTRUCTOR __attribute__((constructor))
#define DESTRUCTOR __attribute__((destructor))
#define VISIBILITY(v) __attribute__((visibility(v)))
#define MALLOC_LIKE __attribute__((malloc))
#define ALLOC_SIZE(...) __attribute__((alloc_size(__VA_ARGS__)))
#else
#define PURE_FUNC
#define CONST_FUNC
#define HOT_FUNC
#define COLD_FUNC
#define FLATTEN_FUNC
#define NOINLINE_FUNC
#define ALWAYS_INLINE inline
#define WARN_UNUSED
#define DEPRECATED(msg)
#define CLEANUP(func)
#define PACKED
#define ALIGNED(n)
#define FORMAT(type, fmt, args)
#define WEAK
#define ALIAS(name)
#define CONSTRUCTOR
#define DESTRUCTOR
#define VISIBILITY(v)
#define MALLOC_LIKE
#define ALLOC_SIZE(...)
#endif

/*
 * ADVANCED PREPROCESSOR TECHNIQUES
 *
 * The preprocessor is C's metaprogramming system. It runs before
 * compilation and can generate code based on patterns.
 */

/* Compile-time assertion macro that works in C99 */
#define STATIC_ASSERT(expr, msg)                                               \
  typedef char static_assertion_##msg[(expr) ? 1 : -1]

/* Count number of arguments (up to 10) */
#define COUNT_ARGS(...)                                                        \
  COUNT_ARGS_IMPL(__VA_ARGS__, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define COUNT_ARGS_IMPL(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, N, ...) N

/* Apply macro to each argument */
#define MAP(macro, ...) MAP_IMPL(COUNT_ARGS(__VA_ARGS__), macro, __VA_ARGS__)
#define MAP_IMPL(n, macro, ...) MAP_##n(macro, __VA_ARGS__)
#define MAP_1(m, x) m(x)
#define MAP_2(m, x, ...) m(x) MAP_1(m, __VA_ARGS__)
#define MAP_3(m, x, ...) m(x) MAP_2(m, __VA_ARGS__)
#define MAP_4(m, x, ...) m(x) MAP_3(m, __VA_ARGS__)
#define MAP_5(m, x, ...) m(x) MAP_4(m, __VA_ARGS__)

/* Defer macro expansion */
#define EMPTY()
#define DEFER(id) id EMPTY()
#define EXPAND(...) __VA_ARGS__

/* Basic macros - text substitution */
#define STRINGIFY(x) #x   /* Convert to string: STRINGIFY(hello) -> "hello" */
#define CONCAT(a, b) a##b /* Token pasting: CONCAT(foo, bar) -> foobar */
#define EXPAND_MACRO(x) x /* Force macro expansion */

/*
 * Compile-time computations using preprocessor
 * This demonstrates Fibonacci calculation at compile time
 */
#define FIB_0 0
#define FIB_1 1
#define FIB_2 1
#define FIB_3 2
#define FIB_4 3
#define FIB_5 5
#define FIB_6 8
#define FIB_7 13
#define FIB_8 21
#define FIB_9 34
#define FIB_10 55
#define FIB_11 89
#define FIB(n) FIB_##n

/* Use Fibonacci for performance testing */
#define BENCHMARK_ITERATIONS FIB(11) /* 610 iterations */

/*
 * Recursive macro expansion for compile-time loops.
 * This technique allows us to "unroll" loops at compile time.
 * Each REPEAT_N macro calls the previous one, creating a cascade.
 */
#define REPEAT_0(macro, ...)
#define REPEAT_1(macro, ...) macro(0, __VA_ARGS__)
#define REPEAT_2(macro, ...) REPEAT_1(macro, __VA_ARGS__) macro(1, __VA_ARGS__)
#define REPEAT_3(macro, ...) REPEAT_2(macro, __VA_ARGS__) macro(2, __VA_ARGS__)
#define REPEAT_4(macro, ...) REPEAT_3(macro, __VA_ARGS__) macro(3, __VA_ARGS__)
#define REPEAT_N(n, macro, ...) CONCAT(REPEAT_, n)(macro, __VA_ARGS__)

/*
 * X-Macros: A powerful technique for data-driven code generation.
 * Define data once, use it multiple times in different contexts.
 * The X macro will be redefined for each use case.
 */
#define HELLO_CHARS                                                            \
  X('H', 0)                                                                    \
  X('e', 1)                                                                    \
  X('l', 2)                                                                    \
  X('l', 3)                                                                    \
  X('o', 4)                                                                    \
  X(' ', 5)                                                                    \
  X('W', 6)                                                                    \
  X('o', 7)                                                                    \
  X('r', 8)                                                                    \
  X('l', 9)                                                                    \
  X('d', 10)                                                                   \
  X('!', 11)

/*
 * Advanced X-Macro for error codes
 * Generates enum, strings, and handler functions from one definition
 */
#define ERROR_CODES                                                            \
  X(SUCCESS, 0, "Operation successful")                                        \
  X(MALLOC_FAILED, 1, "Memory allocation failed")                              \
  X(INVALID_PARAM, 2, "Invalid parameter")                                     \
  X(BUFFER_OVERFLOW, 3, "Buffer overflow detected")                            \
  X(CORRUPTED_DATA, 4, "Data corruption detected")

/* Generate error enum */
typedef enum {
#define X(name, code, desc) ERR_##name = code,
  ERROR_CODES
#undef X
      ERR_MAX
} error_code_t;

/* Generate error description function */
static const char *error_desc(error_code_t err) {
  switch (err) {
#define X(name, code, desc)                                                    \
  case ERR_##name:                                                             \
    return desc;
    ERROR_CODES
#undef X
  default:
    return "Unknown error";
  }
}

/*
 * CUSTOM STACK PROTECTION
 * Implement our own stack canary for demonstration
 */
#define STACK_CANARY 0xDEADBEEFCAFEBABEULL

typedef struct {
  uint64_t canary;
  char data[256];
  uint64_t canary_end;
} protected_buffer_t;

#define CHECK_CANARY(buf)                                                      \
  do {                                                                         \
    if ((buf)->canary != STACK_CANARY || (buf)->canary_end != STACK_CANARY) {  \
      fprintf(stderr, "Stack corruption detected at %s:%d\n", __FILE__,        \
              __LINE__);                                                       \
      abort();                                                                 \
    }                                                                          \
  } while (0)

/*
 * Enum (enumeration) creates a set of named integer constants.
 * Here we're using bit flags pattern where each value is a power of 2.
 * This allows us to combine multiple flags using bitwise OR (|).
 */
typedef enum {
  LOG_NONE = 0x00,    /* 00000000 - No logging */
  LOG_ERROR = 0x01,   /* 00000001 - Log errors only */
  LOG_WARNING = 0x02, /* 00000010 - Log warnings */
  LOG_INFO = 0x04,    /* 00000100 - Log info messages */
  LOG_DEBUG = 0x08,   /* 00001000 - Log debug details */
  LOG_VERBOSE = 0x10, /* 00010000 - Log verbose output */
  LOG_TRACE = 0x20,   /* 00100000 - Log trace information */
  LOG_PERF = 0x40,    /* 01000000 - Log performance metrics */
  LOG_ALL = 0xFF      /* 11111111 - Log everything */
} log_level_t;

/* Static global variable for current log level */
static log_level_t current_log_level = LOG_ERROR | LOG_WARNING | LOG_INFO;

/*
 * ADVANCED TYPE DEFINITIONS AND STRUCTURES
 */

/*
 * Transparent union - allows type punning with type safety
 * The compiler treats the union as its first member in function calls
 */
typedef union {
  void *as_ptr;
  uintptr_t as_int;
} ALIGNED(16) transparent_ptr_t;

/*
 * Bit fields allow us to specify exact bit sizes for struct members.
 * This is useful for:
 * 1. Saving memory when you have many small values
 * 2. Matching hardware register layouts
 * 3. Creating compact data structures
 */
typedef struct {
  unsigned int is_encrypted : 1;  /* 1 bit - can be 0 or 1 */
  unsigned int is_compressed : 1; /* 1 bit - another flag */
  unsigned int priority : 3;      /* 3 bits - values 0-7 */
  unsigned int reserved : 11;     /* 11 bits - saved for future */
  unsigned int checksum_type : 2; /* 2 bits - values 0-3 */
  unsigned int version : 14;      /* 14 bits - values 0-16383 */
} PACKED string_metadata_t;       /* Total: 32 bits = 4 bytes */

/*
 * Flexible Array Member (FAM) - C99 feature
 * The last member of a struct can be an array without a size.
 * This allows the struct to have variable size.
 */
typedef struct {
  size_t capacity; /* Maximum size of buffer */
  size_t used;     /* Currently used size */
  char buffer[];   /* Flexible array member - MUST be last! */
} flex_buffer_t;

/*
 * OBJECT POOL IMPLEMENTATION
 * Reuse objects instead of allocating/freeing repeatedly
 */
typedef struct pool_node {
  struct pool_node *next;
  char data[]; /* Object data follows */
} pool_node_t;

typedef struct {
  pool_node_t *free_list;
  size_t object_size;
  size_t alignment;
  _Atomic(uint64_t) allocations;
  _Atomic(uint64_t) deallocations;
  void *(*backing_alloc)(size_t);
  void (*backing_free)(void *);
} object_pool_t;

/*
 * LOCK-FREE DATA STRUCTURES
 *
 * Lock-free programming allows multiple threads to access data
 * without traditional locks, improving performance and avoiding deadlocks.
 */

/* ABA problem prevention using hazard pointers */
typedef struct {
  _Atomic(void *) ptr;
  _Atomic(uint64_t) counter; /* Prevent ABA problem */
} tagged_ptr_t;

/* Node for lock-free queue */
struct lfq_node {
  _Atomic(struct lfq_node *) next; /* Atomic pointer to next node */
  char data;                       /* Payload */
};

/*
 * Lock-free queue structure with cache-line padding.
 * Modern CPUs load data in 64-byte cache lines. By padding our
 * structure, we prevent "false sharing" where different threads
 * fight over the same cache line.
 */
typedef struct {
  ALIGNED(64) _Atomic(struct lfq_node *) head;
  char pad1[64 - sizeof(void *)];
  ALIGNED(64) _Atomic(struct lfq_node *) tail;
  char pad2[64 - sizeof(void *)];
  ALIGNED(64) _Atomic(uint64_t) size;
} lock_free_queue_t;

/*
 * CACHE-AWARE RING BUFFER
 * Optimized for cache performance with proper padding
 */
typedef struct {
  ALIGNED(64) struct {
    _Atomic(uint64_t) head;
    char pad[64 - sizeof(uint64_t)];
  } producer;

  ALIGNED(64) struct {
    _Atomic(uint64_t) tail;
    char pad[64 - sizeof(uint64_t)];
  } consumer;

  ALIGNED(64) struct {
    uint64_t mask; /* Size - 1 for fast modulo */
    void **buffer;
  } data;
} ring_buffer_t;

/*
 * ARENA ALLOCATOR WITH STATISTICS
 *
 * Traditional malloc/free can be slow and cause fragmentation.
 * Arena allocators allocate from large blocks and free everything at once.
 * Perfect for temporary allocations with clear lifetime.
 */
typedef struct arena_block {
  struct arena_block *next;
  size_t size;
  size_t used;
  _Alignas(max_align_t) char data[]; /* Aligned flexible array */
} arena_block_t;

typedef struct {
  arena_block_t *current; /* Current block we're allocating from */
  arena_block_t *first;   /* First block (for cleanup) */
  size_t block_size;      /* Size of each block */
  /* Statistics */
  _Atomic(uint64_t) total_allocated;
  _Atomic(uint64_t) total_freed;
  _Atomic(uint64_t) peak_usage;
  _Atomic(uint32_t) block_count;
} arena_t;

/*
 * CUSTOM MEMORY DEBUGGING
 * Track all allocations for leak detection
 */
typedef struct alloc_info {
  void *ptr;
  size_t size;
  const char *file;
  int line;
  struct alloc_info *next;
} alloc_info_t;

static _Atomic(alloc_info_t *) alloc_list = NULL;
static _Atomic(uint64_t) total_allocations = 0;
static _Atomic(uint64_t) total_bytes = 0;

#define DEBUG_MALLOC(size) debug_malloc(size, __FILE__, __LINE__)
#define DEBUG_FREE(ptr) debug_free(ptr, __FILE__, __LINE__)

/*
 * COROUTINES IN C
 *
 * Coroutines allow functions to pause and resume execution.
 * We implement them using computed goto - a GNU extension that
 * allows jumping to addresses stored in variables.
 */
typedef struct {
  void **ip;         /* Instruction pointer */
  void *stack[1024]; /* Coroutine stack */
  int sp;            /* Stack pointer */
  int state;         /* Current state */
  jmp_buf env;       /* For setjmp/longjmp based implementation */
} coroutine_t;

/*
 * COMPILE-TIME TYPE INTROSPECTION
 * Poor man's reflection using macros
 */
#define TYPE_INFO(type)                                                        \
  {.name = #type,                                                              \
   .size = sizeof(type),                                                       \
   .alignment = _Alignof(type),                                                \
   .is_signed = _Generic((type *)0,                                            \
       void **: 0,                                                             \
       char **: 0,                                                             \
       default: _Generic((type)0,                                              \
           unsigned char: 0,                                                   \
           unsigned short: 0,                                                  \
           unsigned int: 0,                                                    \
           unsigned long: 0,                                                   \
           unsigned long long: 0,                                              \
           char *: 0,                                                          \
           void *: 0,                                                          \
           default: (sizeof(type) > 1) ? ((type) - 1 < (type)0)                \
                                       : (((type) - 1) < 0))),                 \
   .is_pointer = _Generic((type *)0,                                           \
       void **: 1,                                                             \
       char **: 1,                                                             \
       int **: 1,                                                              \
       double **: 1,                                                           \
       default: 0)}

typedef struct {
  const char *name;
  size_t size;
  size_t alignment;
  bool is_signed;
  bool is_pointer;
} type_info_t;

/*
 * C23 _BitInt - Arbitrary precision integers
 * This allows integers of any bit width (up to implementation limits).
 * Useful for cryptography, arbitrary precision math, etc.
 */
#ifdef C23_AVAILABLE
typedef _BitInt(128) int128_t;           /* 128-bit signed integer */
typedef unsigned _BitInt(128) uint128_t; /* 128-bit unsigned integer */
typedef _BitInt(256) int256_t;           /* 256-bit signed integer */
typedef unsigned _BitInt(256) uint256_t; /* 256-bit unsigned integer */
#endif

/*
 * SIMD (Single Instruction, Multiple Data) String Type
 *
 * Modern CPUs can process multiple data elements with one instruction.
 * AVX2 provides 256-bit registers that can hold 32 bytes.
 * This allows parallel processing of string operations.
 */
typedef struct {
  __m256i data[4]; /* 4 * 32 bytes = 128 bytes total */
  size_t len;      /* Actual string length */
} simd_string_t;

/*
 * Thread-Local Storage with Cache Alignment
 *
 * Each thread gets its own copy of this data.
 * _Alignas(64) ensures it starts on a cache line boundary,
 * preventing false sharing between threads.
 */
_Thread_local ALIGNED(64) struct {
  uint64_t rng_state;        /* Random number generator state */
  arena_t *local_arena;      /* Thread-local arena allocator */
  object_pool_t *local_pool; /* Thread-local object pool */
  int thread_id;             /* Thread identifier */
  uint64_t perf_counter;     /* Performance counter */
  struct {
    uint64_t cache_hits;
    uint64_t cache_misses;
  } stats;
} tls_data = {.rng_state = 0x123456789ABCDEF0};

/*
 * Memory ordering test structure
 *
 * C11 introduced fine-grained control over memory ordering in
 * concurrent programs. This structure helps demonstrate different
 * memory ordering guarantees.
 */
typedef struct {
  _Atomic(int) seq_cst;           /* Sequential consistency (strongest) */
  _Atomic(int) acquire_release;   /* Acquire-release (medium) */
  _Atomic(int) relaxed;           /* Relaxed (weakest, fastest) */
  char pad[64 - 3 * sizeof(int)]; /* Cache line padding */
} memory_order_test_t;

/*
 * CUSTOM ASSERT IMPLEMENTATION
 * More informative than standard assert
 */
#define ASSERT(expr)                                                           \
  do {                                                                         \
    if (UNLIKELY(!(expr))) {                                                   \
      fprintf(stderr, "\n*** Assertion failed: %s\n", #expr);                  \
      fprintf(stderr, "*** Function: %s\n", __func__);                         \
      fprintf(stderr, "*** File: %s:%d\n", __FILE__, __LINE__);                \
      print_backtrace();                                                       \
      abort();                                                                 \
    }                                                                          \
  } while (0)

/* Macro for character obfuscation using XOR */
#define OBFUSCATE_CHAR(c, key) ((c) ^ (key))
#define ENCRYPTION_KEY 0x42

/* Our encrypted "Hello World!" message */
static const char ENCRYPTED_STRING[] = {0x0A, 0x27, 0x2E, 0x2E, 0x2D,
                                        0x62, 0x15, 0x2D, 0x30, 0x2E,
                                        0x26, 0x63, 0x00};

/* Function pointer typedef for string transformers */
typedef char *(*string_transformer_t)(const char *, size_t);

/*
 * VTABLE IMPLEMENTATION IN C
 * Object-oriented programming using function pointers
 */
typedef struct string_ops {
  void (*print)(const void *);
  char *(*to_upper)(const void *);
  size_t (*get_length)(const void *);
  void (*destroy)(void *);
} string_ops_t;

/*
 * Enhanced string container with "methods"
 * This demonstrates Object-Oriented programming in C
 */
typedef struct string_container {
  /* "Private" data */
  char *data;
  size_t length;
  uint64_t checksum;
  void (*free_func)(void *);
  string_metadata_t metadata;

  /* "Public" interface via vtable */
  const string_ops_t *ops;

  /* Reference counting */
  _Atomic(int) refcount;
} string_container_t;

/*
 * Union for type punning - viewing the same memory as different types.
 * All members share the same memory location.
 */
typedef union {
  uint64_t as_int;
  double as_double;
  void *as_ptr;
  char as_bytes[8];
  struct {
    uint32_t low;
    uint32_t high;
  } as_parts;
  float as_floats[2];
} data_punner_t;

/*
 * COMPILE-TIME DISPATCH TABLE
 * Using designated initializers for sparse arrays
 */
static const char char_to_hex[256] = {
    ['0'] = 0,  ['1'] = 1,  ['2'] = 2,  ['3'] = 3,  ['4'] = 4,  ['5'] = 5,
    ['6'] = 6,  ['7'] = 7,  ['8'] = 8,  ['9'] = 9,  ['A'] = 10, ['B'] = 11,
    ['C'] = 12, ['D'] = 13, ['E'] = 14, ['F'] = 15, ['a'] = 10, ['b'] = 11,
    ['c'] = 12, ['d'] = 13, ['e'] = 14, ['f'] = 15,
};

/*
 * Debug print macro with do-while(0) pattern.
 * This ensures the macro acts as a single statement.
 */
#define DEBUG 1
#define DEBUG_PRINT(fmt, ...)                                                  \
  do {                                                                         \
    if (DEBUG) {                                                               \
      fprintf(stderr, "%s:%d:%s(): " fmt, __FILE__, __LINE__, __func__,        \
              ##__VA_ARGS__);                                                  \
    }                                                                          \
  } while (0)

/*
 * PERFORMANCE TIMING MACROS
 */
#define TIMING_START()                                                         \
  do {                                                                         \
    struct timespec _start, _end;                                              \
    printf(CYAN "⏱  Starting timing..." RESET);                                \
    clock_gettime(CLOCK_MONOTONIC, &_start);

#define TIMING_END(name)                                                       \
  clock_gettime(CLOCK_MONOTONIC, &_end);                                       \
  double _elapsed =                                                            \
      (_end.tv_sec - _start.tv_sec) + (_end.tv_nsec - _start.tv_nsec) / 1e9;   \
  printf("\r" BRIGHT_GREEN LIGHTNING " " BOLD "%s" RESET ": " YELLOW           \
         "%.6f seconds" RESET "\n",                                            \
         name, _elapsed);                                                      \
  }                                                                            \
  while (0)

/*
 * Variadic macro for generating logging functions
 * Token pasting (##) and stringizing (#) in action
 */
/* Enhanced Colorized Logging */
#define CREATE_COLORIZED_LOGGER(level, prefix, color, symbol)                  \
  static void FORMAT(printf, 1, 2) log_##level(const char *fmt, ...) {         \
    if (current_log_level & LOG_##prefix) {                                    \
      va_list args;                                                            \
      va_start(args, fmt);                                                     \
      fprintf(stderr, color BOLD "[" symbol " " #level "]" RESET " ");         \
      vfprintf(stderr, fmt, args);                                             \
      va_end(args);                                                            \
    }                                                                          \
  }

/* Generate colorized logging functions */
CREATE_COLORIZED_LOGGER(error, ERROR, BRIGHT_RED, CROSSMARK)
CREATE_COLORIZED_LOGGER(warning, WARNING, BRIGHT_YELLOW, WARNING)
CREATE_COLORIZED_LOGGER(info, INFO, BRIGHT_CYAN, INFO)
CREATE_COLORIZED_LOGGER(debug, DEBUG, BRIGHT_MAGENTA, GEAR)
CREATE_COLORIZED_LOGGER(verbose, VERBOSE, BRIGHT_GREEN, CHECKMARK)
CREATE_COLORIZED_LOGGER(trace, TRACE, DIM WHITE, DIAMOND)
CREATE_COLORIZED_LOGGER(perf, PERF, BRIGHT_BLUE, LIGHTNING)

/*
 * C11 _Static_assert performs compile-time assertion
 * If the condition is false, compilation fails with the message
 */
#ifdef C11_AVAILABLE
_Static_assert(sizeof(string_metadata_t) == 4,
               "string_metadata_t must be exactly 4 bytes");
_Static_assert(_Alignof(max_align_t) >= 16,
               "max_align_t should be at least 16 bytes aligned");
#endif

/*
 * STATIC INITIALIZATION WITH CONSTRUCTOR
 * Run before main() starts
 */
CONSTRUCTOR static void early_init(void) {
  /* Initialize performance counters */
  if (getenv("HELLO_PERF")) {
    current_log_level |= LOG_PERF;
  }
}

/*
 * Computed goto labels for coroutine implementation
 * This GNU extension allows storing label addresses in variables
 */
#define CORO_LABELS                                                            \
  static void *labels[] = {&&coro_start, &&coro_yield1, &&coro_yield2,         \
                           &&coro_end};

/*
 * C23 typeof for generic programming
 * Allows declaring variables of the same type as another variable
 */
#ifdef C23_AVAILABLE
#define auto_var(x) typeof(x)
#else
#define auto_var(x) __typeof__(x) /* GNU extension fallback */
#endif

/*
 * C11 _Generic enables compile-time type selection
 * Like function overloading but resolved at compile time
 */
#ifdef C11_AVAILABLE
#define print_value(x)                                                         \
  _Generic((x),                                                                \
      int: print_int,                                                          \
      long: print_long,                                                        \
      double: print_double,                                                    \
      float: print_float,                                                      \
      char *: print_string,                                                    \
      const char *: print_string,                                              \
      void *: print_pointer,                                                   \
      const void *: print_pointer,                                             \
      default: print_generic)(x)

// Helper functions
static void print_int(int x) { printf("Integer: %d\n", x); }
static void print_long(long x) { printf("Long: %ld\n", x); }
static void print_double(double x) { printf("Double: %f\n", x); }
static void print_float(float x) { printf("Float: %f\n", (double)x); }
static void print_string(const char *x) { printf("String: %s\n", x); }
static void print_pointer(const void *x) { printf("Pointer: %p\n", x); }
static void print_generic(const void *x) { printf("Value: %p\n", x); }
/* Advanced _Generic for type sizes */
#define TYPE_SIZE(x)                                                           \
  _Generic((x),                                                                \
      char: 1,                                                                 \
      short: 2,                                                                \
      int: 4,                                                                  \
      long: sizeof(long),                                                      \
      long long: 8,                                                            \
      float: 4,                                                                \
      double: 8,                                                               \
      long double: sizeof(long double),                                        \
      void *: sizeof(void *),                                                  \
      char *: sizeof(char *),                                                  \
      default: sizeof(x))
#else
#define print_value(x) printf("Value: %p\n", (void *)(uintptr_t)(x))
#define TYPE_SIZE(x) sizeof(x)
#endif

/* Forward declarations with attributes */
static void cleanup_handler(void) DESTRUCTOR;
static char *decrypt_string(const char *encrypted,
                            size_t length) WARN_UNUSED MALLOC_LIKE;
static uint64_t compute_checksum(const char *data, size_t length) PURE_FUNC;
static void release_string_container(string_container_t *container);
static void signal_handler(int signum);
static string_container_t *preprocess_string(const char *input) WARN_UNUSED;
static void *secure_alloc(size_t size) WARN_UNUSED MALLOC_LIKE ALLOC_SIZE(1);
static void secure_free(void *ptr);
static void print_container(const void *container);
static char *to_upper_container(const void *container) WARN_UNUSED MALLOC_LIKE;
static size_t get_length_container(const void *container) PURE_FUNC;
static void destroy_container(void *container);
static char *process_with_vla(const char *input, size_t len) WARN_UNUSED;
static void demonstrate_goto(int *result);
static double complex hello_complex(void) CONST_FUNC;
static flex_buffer_t *
create_flex_buffer(size_t capacity) WARN_UNUSED MALLOC_LIKE;
static int my_printf(const char *restrict format, ...) FORMAT(printf, 1, 2);
static void *arena_alloc(arena_t *arena, size_t size, size_t align) WARN_UNUSED;
static arena_t *arena_create(size_t block_size) WARN_UNUSED MALLOC_LIKE;
static void arena_destroy(arena_t *arena);
static uint64_t xorshift64star(uint64_t *state) HOT_FUNC;
static void demonstrate_simd(void);
static void demonstrate_atomics(void);
static void *generate_code(const char *str) WARN_UNUSED;
static void run_coroutine(coroutine_t *coro);
static int parallel_hello(void *arg);
static void lock_free_demo(void);
static void enqueue_char(lock_free_queue_t *queue, char c);
static char dequeue_char(lock_free_queue_t *queue);
static void print_backtrace(void) COLD_FUNC;
static object_pool_t *pool_create(size_t obj_size,
                                  size_t alignment) WARN_UNUSED;
static void pool_destroy(object_pool_t *pool);
static void *pool_alloc(object_pool_t *pool) WARN_UNUSED HOT_FUNC;
static void pool_free(object_pool_t *pool, void *obj) HOT_FUNC;
static void *debug_malloc(size_t size, const char *file,
                          int line) WARN_UNUSED MALLOC_LIKE;
static void debug_free(void *ptr, const char *file, int line);
static void print_memory_stats(void);
static void demonstrate_cache_effects(void);
static void demonstrate_prefetching(void);
static inline int generic_popcount(uint64_t x) CONST_FUNC;
static inline int generic_clz(uint64_t x) CONST_FUNC;
static inline int generic_ctz(uint64_t x) CONST_FUNC;
/* Add these three missing forward declarations */
static void print_header(const char *title, const char *color);
static void pulse_text(const char *text, const char *color, int pulses);
static void spinning_loader(const char *message, int duration_ms);

/* String operations vtable */
static const string_ops_t string_ops = {.print = print_container,
                                        .to_upper = to_upper_container,
                                        .get_length = get_length_container,
                                        .destroy = destroy_container};

/* Global variables */
static jmp_buf jump_buffer;
static volatile sig_atomic_t signal_received = 0;

#ifdef C11_AVAILABLE
_Thread_local int recursion_depth = 0;
#else
static int recursion_depth = 0;
#endif

/* Inline function example with forced inlining */
static inline ALWAYS_INLINE int max(int a, int b) { return (a > b) ? a : b; }

/* Branch prediction hint example */
static inline int PURE_FUNC min_with_hint(int a, int b) {
  if (LIKELY(a < b)) {
    return a;
  }
  return b;
}

/*
 * INLINE ASSEMBLY EXAMPLES
 * Platform-specific optimizations
 */
#if defined(__x86_64__) && defined(__GNUC__)
static inline uint64_t rdtsc(void) {
  uint32_t lo, hi;
  __asm__ __volatile__("rdtsc" : "=a"(lo), "=d"(hi));
  return ((uint64_t)hi << 32) | lo;
}

static inline void memory_barrier(void) {
  __asm__ __volatile__("mfence" ::: "memory");
}

static inline void cpu_relax(void) {
  __asm__ __volatile__("pause" ::: "memory");
}
#else
static inline uint64_t rdtsc(void) { return 0; }
static inline void memory_barrier(void) { __sync_synchronize(); }
static inline void cpu_relax(void) {}
#endif

/* Variadic function with restrict qualifier */
static int my_printf(const char *restrict format, ...) {
  va_list args;
  va_start(args, format);
  int result = vprintf(format, args);
  va_end(args);
  return result;
}

/*
 * Advanced feature showcase array
 * Demonstrates designated initializers and compound literals
 */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
static const struct {
  const char *name;
  void (*func)(void);
  _Alignas(16) uint8_t data[16]; /* 16-byte aligned data */
} feature_showcase[] = {
    [0] = {.name = "SIMD Processing",
           .func = demonstrate_simd,
           .data = {[0 ... 15] = 0xFF}}, /* Range initialization */
    [1] = {.name = "Atomic Operations", .func = demonstrate_atomics},
    [2] = {.name = "Lock-free Structures", .func = lock_free_demo},
    [3] = {.name = "Cache Effects", .func = demonstrate_cache_effects},
    [4] = {.name = "Prefetching", .func = demonstrate_prefetching},
};
#pragma GCC diagnostic pop

/*
 * COMPOUND LITERAL EXAMPLES
 * Create anonymous structures on the fly
 */
typedef struct {
  int x, y;
} point_t;

#define POINT(x_, y_) ((point_t){.x = (x_), .y = (y_)})
#define COLOR(r, g, b, a) ((struct { uint8_t r, g, b, a; }){r, g, b, a})

/*
 * AUTOMATIC CLEANUP WITH RAII
 * C's version of RAII (Resource Acquisition Is Initialization)
 */
static void cleanup_string(char **str) {
  if (str && *str) {
    free(*str);
    *str = NULL;
  }
}

static void cleanup_file(FILE **fp) {
  if (fp && *fp) {
    fclose(*fp);
    *fp = NULL;
  }
}

#define AUTO_STRING CLEANUP(cleanup_string)
#define AUTO_FILE CLEANUP(cleanup_file)

static void simple_dynamic_hello(void) { printf("Dynamic: Hello World!\n"); }

/*
 * MAIN FUNCTION - Where our journey begins
 */
int main(void) {
  /* Initialize terminal */
  printf(CLEAR_SCREEN HIDE_CURSOR);

  /* Animated startup */
  printf(BOLD BRIGHT_CYAN);
  printf("\n");
  printf(
      "    ██╗   ██╗██╗  ████████╗██╗███╗   ███╗ █████╗ ████████╗███████╗\n");
  printf(
      "    ██║   ██║██║  ╚══██╔══╝██║████╗ ████║██╔══██╗╚══██╔══╝██╔════╝\n");
  printf(
      "    ██║   ██║██║     ██║   ██║██╔████╔██║███████║   ██║   █████╗  \n");
  printf(
      "    ██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝  \n");
  printf(
      "    ╚██████╔╝███████╗██║   ██║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗\n");
  printf(
      "     ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝\n");
  printf("\n");
  printf("            ██╗  ██╗███████╗██╗     ██╗      ██████╗ \n");
  printf("            ██║  ██║██╔════╝██║     ██║     ██╔═══██╗\n");
  printf("            ███████║█████╗  ██║     ██║     ██║   ██║\n");
  printf("            ██╔══██║██╔══╝  ██║     ██║     ██║   ██║\n");
  printf("            ██║  ██║███████╗███████╗███████╗╚██████╔╝\n");
  printf("            ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝ ╚═════╝ \n");
  printf("\n");
  printf("        ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗ ██╗██╗██╗\n");
  printf("        ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗██║██║██║\n");
  printf("        ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║██║██║██║\n");
  printf("        ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║╚═╝╚═╝╚═╝\n");
  printf("        ╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝██╗██╗██╗\n");
  printf("         ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝╚═╝╚═╝\n");
  printf(RESET "\n");

  pulse_text("THE ULTIMATE C PROGRAMMING DEMONSTRATION", BRIGHT_YELLOW, 3);

  spinning_loader("Initializing system", 2000);

  /* Register cleanup function */
  atexit(cleanup_handler);

  /* Set up signal handlers for multiple signals */
  struct sigaction sa = {.sa_handler = signal_handler, .sa_flags = SA_RESTART};
  sigemptyset(&sa.sa_mask);
  sigaction(SIGINT, &sa, NULL);
  sigaction(SIGTERM, &sa, NULL);

/* Initialize thread-local RNG with hardware random if available */
#ifdef __RDRND__
  unsigned long long seed;
  if (_rdrand64_step(&seed)) {
    tls_data.rng_state = seed;
    log_info("Initialized RNG with hardware random\n");
  }
#endif

  /* Create thread-local arena allocator */
  tls_data.local_arena = arena_create(4096);
  if (!tls_data.local_arena) {
    log_error("Failed to create arena allocator\n");
    return EXIT_FAILURE;
  }

  /* Create thread-local object pool */
  tls_data.local_pool = pool_create(sizeof(struct lfq_node), 64);
  if (!tls_data.local_pool) {
    log_error("Failed to create object pool\n");
    arena_destroy(tls_data.local_arena);
    return EXIT_FAILURE;
  }

  /* Setup for error recovery */
  if (setjmp(jump_buffer) != 0) {
    log_error("Recovered from simulated error via longjmp\n");
  }

  /* Seed random number generator */
  srand((unsigned int)time(NULL));

  /* C23 constexpr-style initialization */
#ifdef C23_AVAILABLE
  constexpr int hello_len = 12;
  constexpr int fib_value = FIB(8);
  log_verbose("Compile-time Fibonacci(8) = %d\n", fib_value);
#else
  const int hello_len = 12;
  const int fib_value = FIB(8);
  log_verbose("Compile-time Fibonacci(8) = %d\n", fib_value);
#endif

  /* Demonstrate X-Macros to build data structures */
  static const struct {
    char ch;
    int pos;
    int fib_weight; /* Add Fibonacci weighting! */
  } hello_data[] = {
#define X(ch, pos) {ch, pos, FIB(pos % 8)}, /* Use Fibonacci! */
      HELLO_CHARS
#undef X
  };

  log_info("Starting ultimate Hello World demonstration...\n");
  log_info("Demonstrating %zu features\n",
           sizeof(feature_showcase) / sizeof(feature_showcase[0]));

  /* Performance counter start */
  uint64_t start_tsc = rdtsc();

  log_info("Hello World character analysis (with Fibonacci weighting):\n");
  for (size_t i = 0; i < sizeof(hello_data) / sizeof(hello_data[0]); i++) {
    log_info("  '%c' at position %d, Fibonacci weight: %d\n", hello_data[i].ch,
             hello_data[i].pos, hello_data[i].fib_weight);
  }

  /* Show more Fibonacci values computed at compile time */
  log_info("\nCompile-time Fibonacci sequence:\n");
  log_info("  F(0) = %d\n", FIB(0));
  log_info("  F(1) = %d\n", FIB(1));
  log_info("  F(2) = %d\n", FIB(2));
  log_info("  F(3) = %d\n", FIB(3));
  log_info("  F(4) = %d\n", FIB(4));
  log_info("  F(5) = %d\n", FIB(5));
  log_info("  F(6) = %d\n", FIB(6));
  log_info("  F(7) = %d\n", FIB(7));
  log_info("  F(8) = %d\n", FIB(8));
  log_info("  F(9) = %d\n", FIB(9));
  log_info("  F(10) = %d\n", FIB(10));
  log_info("  F(11) = %d\n", FIB(11));

  /* SIMD-accelerated string construction */
  simd_string_t simd_hello = {0};
  const char *hello_str = "Hello World!";
  if (hello_str) {
    _mm256_storeu_si256(&simd_hello.data[0],
                        _mm256_loadu_si256((const __m256i *)hello_str));
    simd_hello.len = strlen(hello_str);
    log_debug("SIMD string initialized with %zu bytes\n", simd_hello.len);
  }

  /* Demonstrate protected buffer */
  protected_buffer_t *protected = DEBUG_MALLOC(sizeof(protected_buffer_t));
  protected->canary = STACK_CANARY;
  protected->canary_end = STACK_CANARY;
  strcpy(protected->data, "Protected Hello World!");
  CHECK_CANARY(protected);

  /* Create lock-free queue for character assembly */
  lock_free_queue_t *queue =
      arena_alloc(tls_data.local_arena, sizeof(lock_free_queue_t),
                  _Alignof(lock_free_queue_t));
  if (!queue) {
    log_error("Failed to allocate lock-free queue\n");
    arena_destroy(tls_data.local_arena);
    pool_destroy(tls_data.local_pool);
    return EXIT_FAILURE;
  }

  atomic_init(&queue->head, NULL);
  atomic_init(&queue->tail, NULL);
  atomic_init(&queue->size, 0);

  /* Function pointer array for transformations */
  string_transformer_t transformers[] = {
      decrypt_string, NULL /* Sentinel */
  };

  /* Metadata initialization with designated initializers */
  string_metadata_t meta = {
      .is_encrypted = 1, .priority = 7, .checksum_type = 2, .version = 42};

  /* Calculate encrypted string length */
  size_t enc_len = sizeof(ENCRYPTED_STRING) - 1;

  /* VLA for debug output */
  char debug_buffer[enc_len * 3 + 1];
  debug_buffer[0] = '\0';

  /* Build hex representation */
  for (size_t i = 0; i < enc_len; i++) {
    sprintf(debug_buffer + (i * 3), "%02X ",
            (unsigned char)ENCRYPTED_STRING[i]);
  }
  log_debug("Encrypted bytes: %s\n", debug_buffer);

  /* Automatic cleanup demonstration */
  {
    AUTO_STRING char *temp_string = strdup("This will be automatically freed");
    log_verbose("Automatic cleanup: %s\n", temp_string);
  } /* temp_string is automatically freed here */

  /* Decrypt the string */
  char *decrypted = transformers[0](ENCRYPTED_STRING, enc_len);
  if (!decrypted) {
    log_error("Decryption failed\n");
    arena_destroy(tls_data.local_arena);
    pool_destroy(tls_data.local_pool);
    return EXIT_FAILURE;
  }

  /* Multi-threaded hello world construction */
  log_info("Starting multi-threaded processing...\n");
  thrd_t threads[4];
  int thread_args[4] = {0, 1, 2, 3};

  for (int i = 0; i < 4; i++) {
    if (thrd_create(&threads[i], parallel_hello, &thread_args[i]) !=
        thrd_success) {
      log_error("Failed to create thread %d\n", i);
    }
  }

  /* Demonstrate goto */
  int validation_result = 0;
  demonstrate_goto(&validation_result);
  log_verbose("Goto demonstration result: %d\n", validation_result);

  /* Process with VLA */
  char *vla_result = process_with_vla(decrypted, strlen(decrypted));
  log_debug("VLA processing completed: %s\n", vla_result);
  free(vla_result);

  /* Create string container */
  string_container_t *container = preprocess_string(decrypted);
  if (!container) {
    log_error("Failed to create string container\n");
    free(decrypted);
    arena_destroy(tls_data.local_arena);
    pool_destroy(tls_data.local_pool);
    return EXIT_FAILURE;
  }
  container->metadata = meta;
  container->ops = &string_ops;
  atomic_init(&container->refcount, 1);

  /* Coroutine demonstration */
  log_info("Running coroutine-based output...\n");
  coroutine_t coro = {.state = 0, .sp = 0};
  for (int i = 0; i < hello_len; i++) {
    run_coroutine(&coro);
  }
  printf("\n");

  /* Wait for threads */
  for (int i = 0; i < 4; i++) {
    thrd_join(threads[i], NULL);
  }

  /* Dynamic code generation demonstration */
  log_info("Attempting dynamic code generation...\n");
  void (*dynamic_func)(void) =
      (void (*)(void))generate_code("Dynamic: Hello World!\n");
  if (dynamic_func) {
    log_info("Generated code at %p\n", (void *)dynamic_func);
    /* Dynamic code generation demonstration
     * Commented out due to modern security restrictions (ASLR, DEP, PIE)
     * This shows how security features protect against code injection attacks
     * - In production: Use safer alternatives like JIT libraries
     * - For learning: Demonstrates the concept without security risks
     */
    // dynamic_func();  // No parameter - it prints the hardcoded string
  } else {
    log_warning("Dynamic code generation not available on this platform\n");
  }

  /* Demonstrate type punning */
  data_punner_t punner;
  punner.as_int = container->checksum;
  log_verbose("Checksum interpretations:\n");
  log_verbose("  As integer: %llu\n", (unsigned long long)punner.as_int);
  log_verbose("  As double: %f\n", punner.as_double);
  log_verbose("  High 32 bits: 0x%08X\n", punner.as_parts.high);
  log_verbose("  Low 32 bits: 0x%08X\n", punner.as_parts.low);
  log_verbose("  As floats: [%f, %f]\n", punner.as_floats[0],
              punner.as_floats[1]);

  /* Complex number demonstration */
  double complex z = hello_complex();
  log_verbose("Complex result: %.2f + %.2fi\n", creal(z), cimag(z));
  log_verbose("Magnitude: %.2f, Phase: %.2f radians\n", cabs(z), carg(z));

  /* Demonstrate various advanced features */
  for (size_t i = 0; i < sizeof(feature_showcase) / sizeof(feature_showcase[0]);
       i++) {
    if (feature_showcase[i].func) {
      print_header(feature_showcase[i].name, BRIGHT_BLUE);

      printf(BRIGHT_WHITE "Preparing demonstration..." RESET);
      for (int j = 0; j < 20; j++) {
        printf(".");
        fflush(stdout);
        usleep(50000);
      }
      printf(" " GREEN CHECKMARK RESET "\n\n");

      feature_showcase[i].func();

      printf("\n" DIM "Press Enter to continue..." RESET);
      getchar();
    }
  }

/* C23 features demonstration */
#ifdef C23_AVAILABLE
  log_info("\n=== C23 Features ===\n");

  /* Checked arithmetic */
  int result;
  if (ckd_add(&result, INT_MAX, 1)) {
    log_info("Overflow detected with C23 checked arithmetic\n");
  }

  /* Bit manipulation */
  unsigned int x = 0xDEADBEEF;
  log_info("Population count of 0x%X: %d\n", x, stdc_count_ones(x));
  log_info("Leading zeros: %d\n", stdc_leading_zeros(x));
  log_info("Trailing zeros: %d\n", stdc_trailing_zeros(x));
  log_info("First leading one: %d\n", stdc_first_leading_one(x));
  log_info("Bit width: %d\n", stdc_bit_width(x));

  /* 128-bit integer arithmetic */
  int128_t big_num = INT64_MAX;
  big_num *= 2;
  log_info("128-bit arithmetic: INT64_MAX * 2 calculated successfully\n");

  /* 256-bit integer demonstration */
  uint256_t huge_num = UINT64_MAX;
  huge_num = huge_num * huge_num;
  log_info("256-bit arithmetic: UINT64_MAX squared calculated\n");

  /* nullptr constant */
  void *ptr = nullptr;
  log_info("C23 nullptr is %savailable\n", ptr == NULL ? "" : "not ");

  /* Type inference with auto */
  auto x_copy = x; /* Inferred as unsigned int */
  log_info("Type inference: auto variable = %u\n", x_copy);
#endif

  /* Advanced type introspection */
  log_info("\n=== Type Introspection ===\n");
  type_info_t types[] = {
      TYPE_INFO(char),   TYPE_INFO(int),    TYPE_INFO(long),
      TYPE_INFO(double), TYPE_INFO(void *),
  };

  for (size_t i = 0; i < sizeof(types) / sizeof(types[0]); i++) {
    log_info("Type: %-20s Size: %2zu Align: %2zu Signed: %s\n", types[i].name,
             types[i].size, types[i].alignment,
             types[i].is_signed ? "yes" : "no");
  }

  /* Structure layout analysis */
  log_debug("\nStructure layout analysis:\n");
  log_debug("  string_container_t size: %zu bytes\n",
            sizeof(string_container_t));
  log_debug("  lock_free_queue_t size: %zu bytes\n", sizeof(lock_free_queue_t));
  log_debug("  arena_t size: %zu bytes\n", sizeof(arena_t));
  log_debug("  ring_buffer_t size: %zu bytes\n", sizeof(ring_buffer_t));

  /* Member offset analysis using offsetof */
  log_debug("\nMember offsets in string_container_t:\n");
  log_debug("  data: %zu\n", offsetof(string_container_t, data));
  log_debug("  length: %zu\n", offsetof(string_container_t, length));
  log_debug("  checksum: %zu\n", offsetof(string_container_t, checksum));
  log_debug("  ops: %zu\n", offsetof(string_container_t, ops));
  log_debug("  refcount: %zu\n", offsetof(string_container_t, refcount));

  /* Create flex buffer */
  flex_buffer_t *flex_buf = create_flex_buffer(256);
  if (flex_buf) {
    strcpy(flex_buf->buffer, "Flexible array member demonstration");
    flex_buf->used = strlen(flex_buf->buffer) + 1;
    log_verbose("Flex buffer: %s (used: %zu/%zu)\n", flex_buf->buffer,
                flex_buf->used, flex_buf->capacity);
    free(flex_buf);
  }

  /* Compound literal usage */
  point_t point = POINT(10, 20);
  log_verbose("Compound literal point: (%d, %d)\n", point.x, point.y);

  /* Transparent union demonstration */
  transparent_ptr_t trans = {.as_int = 0xDEADBEEF};
  log_verbose("Transparent union as int: 0x%lX\n", trans.as_int);
  trans.as_ptr = container;
  log_verbose("Transparent union as ptr: %p\n", trans.as_ptr);

/* C11 _Generic demonstration */
#ifdef C11_AVAILABLE
  log_info("\nDemonstrating _Generic type selection:\n");
  print_value(42);
  print_value(42L);
  print_value(3.14159);
  print_value(3.14159f);
  print_value("Type-generic programming!");
  print_value((void *)container);

  log_info("Type sizes via _Generic:\n");
  log_info("  int: %zu bytes\n", (size_t)TYPE_SIZE(42));
  log_info("  double: %zu bytes\n", (size_t)TYPE_SIZE(3.14));
  log_info("  pointer: %zu bytes\n", (size_t)TYPE_SIZE((void *)0));
#endif

/* Unicode support demonstration (C11) */
#ifdef C11_AVAILABLE
  char16_t hello_utf16[] = u"Hello World! 🌍";
  char32_t hello_utf32[] = U"Hello World! 🌍";
  log_info("\nUnicode support:\n");
  log_info("  UTF-16 string defined (first char: U+%04X)\n", hello_utf16[0]);
  log_info("  UTF-32 string defined (world emoji: U+%08X)\n", hello_utf32[13]);
#endif

  /* Ring buffer demonstration */
  log_info("\n=== Ring Buffer Demo ===\n");
  ring_buffer_t *ring = arena_alloc(tls_data.local_arena, sizeof(ring_buffer_t),
                                    _Alignof(ring_buffer_t));
  if (ring) {
    ring->data.mask = 15; /* 16 slots */
    ring->data.buffer = arena_alloc(tls_data.local_arena, 16 * sizeof(void *),
                                    _Alignof(void *));
    atomic_init(&ring->producer.head, 0);
    atomic_init(&ring->consumer.tail, 0);

    /* Producer-consumer simulation */
    for (int i = 0; i < 10; i++) {
      uint64_t head = atomic_load(&ring->producer.head);
      ring->data.buffer[head & ring->data.mask] = (void *)(uintptr_t)i;
      atomic_store(&ring->producer.head, head + 1);
    }

    log_info("Ring buffer produced 10 items\n");

    for (int i = 0; i < 5; i++) {
      uint64_t tail = atomic_load(&ring->consumer.tail);
      uint64_t head = atomic_load(&ring->producer.head);
      if (tail < head) {
        void *item = ring->data.buffer[tail & ring->data.mask];
        atomic_store(&ring->consumer.tail, tail + 1);
        log_info("Consumed item: %d\n", (int)(uintptr_t)item);
      }
    }
  }

  /* Demonstrate weak symbols */
  extern void optional_feature(void) WEAK;
  if (optional_feature) {
    log_info("Optional feature is available\n");
    optional_feature();
  } else {
    log_info("Optional feature not linked\n");
  }

  /* Performance measurement */
  log_perf("\n=== Performance Metrics ===\n");
  uint64_t end_tsc = rdtsc();
  log_perf("TSC cycles: %llu\n", (unsigned long long)(end_tsc - start_tsc));

  TIMING_START()
  /* Final output using various methods */
  my_printf("\n=== Final Output ===\n");
  container->ops->print(container);

  char *upper = container->ops->to_upper(container);
  if (upper) {
    log_info("Uppercase: %s\n", upper);
    free(upper);
  }

  size_t len = container->ops->get_length(container);
  log_info("Length via vtable: %zu\n", len);
  TIMING_END("Final output generation");

  /* Reference counting demonstration */
  printf("\n");
  log_info("\nReference counting: current = %d\n",
           atomic_load(&container->refcount));
  atomic_fetch_add(&container->refcount, 1);
  log_info("After increment: %d\n", atomic_load(&container->refcount));
  atomic_fetch_sub(&container->refcount, 1);

  /* Computed goto demonstration */
  CORO_LABELS
  void *ip = labels[0]; // Start with first label
  goto *ip;             // Single dereference

coro_start:
  printf("Computed goto: ");
  ip = &&coro_yield1;
  goto *ip; // Single dereference

coro_yield1:
  printf("Hello ");
  ip = &&coro_yield2;
  goto *ip; // Single dereference

coro_yield2:
  printf("World!\n");
  ip = &&coro_end;
  goto *ip; // Single dereference

coro_end:
  /* Advanced cleanup demonstration */
  log_info("\n=== Cleanup Phase ===\n");

  /* Cleanup */
  CHECK_CANARY(protected);
  DEBUG_FREE(protected);

  container->ops->destroy(container);
  free(decrypted);

  if (dynamic_func && dynamic_func != simple_dynamic_hello) {
    /* Only unmap if we actually allocated memory */
    munmap((void *)dynamic_func, 4096);
  }
  arena_destroy(tls_data.local_arena);
  pool_destroy(tls_data.local_pool);

  /* Print memory statistics */
  print_memory_stats();
  /* Print arena statistics */
  log_info("Arena statistics:\n");
  log_info(
      "  Total allocated: %llu bytes\n",
      (unsigned long long)atomic_load(&tls_data.local_arena->total_allocated));
  log_info("  Block count: %u\n",
           atomic_load(&tls_data.local_arena->block_count));

  /* Print pool statistics */
  log_info("Object pool statistics:\n");
  log_info("  Allocations: %llu\n",
           (unsigned long long)atomic_load(&tls_data.local_pool->allocations));
  log_info("  Deallocations: %llu\n", (unsigned long long)atomic_load(
                                          &tls_data.local_pool->deallocations));

  /* Final memory verification */
  if (atomic_load(&total_bytes) == 0) {
    log_info("✅ All memory properly freed - no leaks detected!\n");
  } else {
    log_warning("⚠️  Final check: %llu bytes still allocated\n",
                (unsigned long long)atomic_load(&total_bytes));
  }
  /* Complex return value using bit manipulation */
  return 0x1 & ~(0x2 >> 1);
}

/*
 * VISUALS
 */
/* Visual Utility Functions */
static void print_header(const char *title, const char *color) {
  int title_len = strlen(title);
  int total_width = 80;
  int padding = (total_width - title_len - 4) / 2;

  printf("\n" BOLD "%s", color);

  /* Top border */
  printf(BOX_TL);
  for (int i = 0; i < total_width - 2; i++)
    printf(BOX_H);
  printf(BOX_TR "\n");

  /* Title line */
  printf(BOX_V);
  for (int i = 0; i < padding; i++)
    printf(" ");
  printf("  %s  ", title);
  for (int i = 0; i < total_width - title_len - 4 - padding; i++)
    printf(" ");
  printf(BOX_V "\n");

  /* Bottom border */
  printf(BOX_BL);
  for (int i = 0; i < total_width - 2; i++)
    printf(BOX_H);
  printf(BOX_BR RESET "\n");
}

static void print_progress_bar(const char *label, int progress, int total,
                               const char *color) {
  int bar_width = 40;
  int filled = (progress * bar_width) / total;

  printf("%s%-20s %s[", color, label, RESET);

  for (int i = 0; i < bar_width; i++) {
    if (i < filled) {
      printf("%s%s", color, PROGRESS_FULL);
    } else {
      printf("%s%s", DIM, PROGRESS_EMPTY);
    }
  }

  printf("%s] %s%3d%%%s (%d/%d)\n", RESET, BOLD, (progress * 100) / total,
         RESET, progress, total);
}

static void animated_counter(const char *label, uint64_t target,
                             const char *color, const char *unit) {
  printf("%s%s: %s", label, RESET, color);

  for (uint64_t i = 0; i <= target; i += (target / 20) + 1) {
    printf("\r%s%s: %s%llu %s%s", label, RESET, color, (unsigned long long)i,
           unit, RESET);
    fflush(stdout);
    usleep(50000); // 50ms delay
  }

  printf("\r%s%s: %s%llu %s%s\n", label, RESET, color,
         (unsigned long long)target, unit, RESET);
}

static void matrix_effect(int lines) {
  const char *chars = "01";
  printf(GREEN);

  for (int line = 0; line < lines; line++) {
    for (int col = 0; col < 80; col++) {
      printf("%c", chars[rand() % 2]);
      if (col % 8 == 7)
        printf(" ");
    }
    printf("\n");
    usleep(100000); // 100ms delay
  }
  printf(RESET);
}

static void typewriter_effect(const char *text, const char *color) {
  printf("%s", color);
  for (const char *p = text; *p; p++) {
    printf("%c", *p);
    fflush(stdout);
    usleep(50000 + (rand() % 50000)); // Variable typing speed
  }
  printf("%s", RESET);
}

static void pulse_text(const char *text, const char *color, int pulses) {
  for (int i = 0; i < pulses; i++) {
    printf("\r%s%s%s%s", BOLD, color, text, RESET);
    fflush(stdout);
    usleep(300000);
    printf("\r%s%s%s%s", DIM, color, text, RESET);
    fflush(stdout);
    usleep(300000);
  }
  printf("\r%s%s%s%s\n", BOLD, color, text, RESET);
}

static void rainbow_text(const char *text) {
  const char *colors[] = {RED, YELLOW, GREEN, CYAN, BLUE, MAGENTA};
  int color_count = sizeof(colors) / sizeof(colors[0]);

  for (const char *p = text; *p; p++) {
    int color_index = (p - text) % color_count;
    printf("%s%c", colors[color_index], *p);
  }
  printf("%s", RESET);
}

static void spinning_loader(const char *message, int duration_ms) {
  const char *spinner = "|/-\\";
  int spinner_len = 4;

  printf("%s", message);
  for (int i = 0; i < duration_ms / 100; i++) {
    printf("\r%s %c", message, spinner[i % spinner_len]);
    fflush(stdout);
    usleep(100000); // 100ms
  }
  printf("\r%s %s%s%s\n", message, GREEN, CHECKMARK, RESET);
}

/*
 * ADVANCED FEATURE IMPLEMENTATIONS
 */

/*
 * Generic bit manipulation functions for platforms without builtins
 */
static inline int generic_popcount(uint64_t x) {
  /* Brian Kernighan's algorithm */
  int count = 0;
  while (x) {
    x &= x - 1;
    count++;
  }
  return count;
}

static inline int generic_clz(uint64_t x) {
  if (x == 0)
    return 64;
  int n = 0;
  if (x <= 0x00000000FFFFFFFFULL) {
    n += 32;
    x <<= 32;
  }
  if (x <= 0x0000FFFFFFFFFFFFULL) {
    n += 16;
    x <<= 16;
  }
  if (x <= 0x00FFFFFFFFFFFFFFULL) {
    n += 8;
    x <<= 8;
  }
  if (x <= 0x0FFFFFFFFFFFFFFFULL) {
    n += 4;
    x <<= 4;
  }
  if (x <= 0x3FFFFFFFFFFFFFFFULL) {
    n += 2;
    x <<= 2;
  }
  if (x <= 0x7FFFFFFFFFFFFFFFULL) {
    n += 1;
  }
  return n;
}

static inline int generic_ctz(uint64_t x) {
  if (x == 0)
    return 64;
  return generic_popcount((x & -x) - 1);
}

/*
 * OBJECT POOL IMPLEMENTATION
 * Efficient object recycling to avoid malloc/free overhead
 */
static object_pool_t *pool_create(size_t obj_size, size_t alignment) {
  object_pool_t *pool = malloc(sizeof(object_pool_t));
  if (!pool)
    return NULL;

  pool->free_list = NULL;
  pool->object_size = obj_size;
  pool->alignment = alignment;
  atomic_init(&pool->allocations, 0);
  atomic_init(&pool->deallocations, 0);
  pool->backing_alloc = malloc;
  pool->backing_free = free;

  return pool;
}

static void pool_destroy(object_pool_t *pool) {
  if (!pool)
    return;

  /* Free all objects in free list */
  pool_node_t *node = pool->free_list;
  while (node) {
    pool_node_t *next = node->next;
    pool->backing_free(node);
    node = next;
  }

  free(pool);
}

static void *HOT_FUNC pool_alloc(object_pool_t *pool) {
  /* Try to get from free list first */
  pool_node_t *node = pool->free_list;
  if (node) {
    pool->free_list = node->next;
    atomic_fetch_add(&pool->allocations, 1);
    return node->data;
  }

  /* Allocate new object */
  size_t total_size = sizeof(pool_node_t) + pool->object_size;
  node = pool->backing_alloc(total_size);
  if (!node)
    return NULL;

  atomic_fetch_add(&pool->allocations, 1);
  return node->data;
}

static void HOT_FUNC pool_free(object_pool_t *pool, void *obj) {
  if (!obj)
    return;

  /* Get node from object pointer */
  pool_node_t *node =
      (pool_node_t *)((char *)obj - offsetof(pool_node_t, data));

  /* Add to free list */
  node->next = pool->free_list;
  pool->free_list = node;
  atomic_fetch_add(&pool->deallocations, 1);
}

/*
 * MEMORY DEBUGGING IMPLEMENTATION
 */
/* Add a simple mutex for debug tracking */
static pthread_mutex_t debug_mutex = PTHREAD_MUTEX_INITIALIZER;

static void *debug_malloc(size_t size, const char *file, int line) {
  void *ptr = malloc(size);
  if (!ptr)
    return NULL;

  alloc_info_t *info = malloc(sizeof(alloc_info_t));
  if (!info) {
    free(ptr);
    return NULL;
  }

  info->ptr = ptr;
  info->size = size;
  info->file = file;
  info->line = line;

  /* Thread-safe list insertion */
  pthread_mutex_lock(&debug_mutex);
  info->next = (alloc_info_t *)atomic_load(&alloc_list);
  atomic_store(&alloc_list, info);
  pthread_mutex_unlock(&debug_mutex);

  atomic_fetch_add(&total_allocations, 1);
  atomic_fetch_add(&total_bytes, size);

  return ptr;
}

static void debug_free(void *ptr, const char *file, int line) {
  if (!ptr)
    return;

  pthread_mutex_lock(&debug_mutex);

  /* Simple list traversal with mutex protection */
  alloc_info_t *prev = NULL;
  alloc_info_t *current = (alloc_info_t *)atomic_load(&alloc_list);

  while (current != NULL) {
    if (current->ptr == ptr) {
      /* Found it - remove from list */
      if (prev == NULL) {
        /* Removing head */
        atomic_store(&alloc_list, current->next);
      } else {
        /* Removing from middle/end */
        prev->next = current->next;
      }

      atomic_fetch_sub(&total_bytes, current->size);
      pthread_mutex_unlock(&debug_mutex);

      free(current);
      free(ptr);
      return;
    }
    prev = current;
    current = current->next;
  }

  pthread_mutex_unlock(&debug_mutex);

  log_warning("Freeing untracked pointer %p at %s:%d\n", ptr, file, line);
  free(ptr);
}

static void COLD_FUNC print_memory_stats(void) {
  print_header("MEMORY DIAGNOSTICS", BRIGHT_MAGENTA);

  pthread_mutex_lock(&debug_mutex);

  uint64_t total_allocs = atomic_load(&total_allocations);
  uint64_t total_mem = atomic_load(&total_bytes);

  animated_counter("Total Allocations", total_allocs, BRIGHT_GREEN, "objects");
  animated_counter("Total Memory", total_mem, BRIGHT_BLUE, "bytes");

  /* Visual memory map */
  alloc_info_t *node = (alloc_info_t *)atomic_load(&alloc_list);
  if (node) {
    printf("\n" BRIGHT_RED BOLD WARNING " MEMORY LEAKS DETECTED:" RESET "\n");
    printf(BOX_TL);
    for (int i = 0; i < 78; i++)
      printf(BOX_H);
    printf(BOX_TR "\n");

    while (node) {
      printf(BOX_V " " RED CROSSMARK " %8zu bytes at %p " YELLOW
                   "(%s:%d)" RESET,
             node->size, node->ptr, node->file, node->line);
      int padding = 78 - 25 - strlen(node->file) - 10;
      for (int i = 0; i < padding; i++)
        printf(" ");
      printf(BOX_V "\n");
      node = node->next;
    }

    printf(BOX_BL);
    for (int i = 0; i < 78; i++)
      printf(BOX_H);
    printf(BOX_BR "\n");
  } else {
    printf("\n" GREEN BOLD CHECKMARK
           " ALL MEMORY PROPERLY FREED - NO LEAKS!" RESET "\n");
    matrix_effect(3);
  }

  pthread_mutex_unlock(&debug_mutex);
}

/*
 * BACKTRACE IMPLEMENTATION
 * Print stack trace for debugging
 */
static void COLD_FUNC print_backtrace(void) {
#ifdef __GLIBC__
  void *buffer[100];
  int nptrs = backtrace(buffer, 100);
  char **strings = backtrace_symbols(buffer, nptrs);

  if (strings) {
    fprintf(stderr, "Backtrace:\n");
    for (int i = 0; i < nptrs; i++) {
      fprintf(stderr, "  %s\n", strings[i]);
    }
    free(strings);
  }
#else
  fprintf(stderr, "Backtrace not available on this platform\n");
#endif
}

/*
 * CACHE EFFECTS DEMONSTRATION
 * Shows the impact of cache-friendly vs cache-unfriendly access patterns
 */
static void demonstrate_cache_effects(void) {
  const size_t SIZE = 1024 * 1024;
  const size_t STRIDE = 64; /* Cache line size */

  uint8_t *data = malloc(SIZE);
  if (!data)
    return;

  /* Initialize with random data first */
  for (size_t i = 0; i < SIZE; i++) {
    data[i] = (uint8_t)(i & 0xFF);
  }

  // Declare variables at function scope
  uint64_t sum1 = 0;
  uint64_t sum2 = 0;
  uint64_t sum3 = 0;

  /* Cache-friendly sequential access */
  TIMING_START()
  for (size_t i = 0; i < SIZE; i++) {
    sum1 += data[i];
  }
  TIMING_END("Sequential access");

  /* Cache-unfriendly strided access */
  TIMING_START()
  for (size_t i = 0; i < SIZE; i += STRIDE) {
    for (size_t j = 0; j < STRIDE && i + j < SIZE; j++) {
      sum2 += data[i + j];
    }
  }
  TIMING_END("Strided access");

  /* Random access (worst case) */
  TIMING_START()
  for (size_t i = 0; i < SIZE / 4; i++) {
    size_t idx = (xorshift64star(&tls_data.rng_state) % SIZE);
    sum3 += data[idx];
  }
  TIMING_END("Random access");

  log_verbose("Sums: %llu, %llu, %llu (prevent optimization)\n",
              (unsigned long long)sum1, (unsigned long long)sum2,
              (unsigned long long)sum3);

  free(data);
}

/*
 * PREFETCHING DEMONSTRATION
 * Shows manual prefetching for performance
 */
static void demonstrate_prefetching(void) {
  const size_t SIZE = 1024 * 1024;
  const size_t PREFETCH_DISTANCE = 512;

  uint8_t *data = malloc(SIZE);
  if (!data)
    return;

  /* Initialize with random data */
  for (size_t i = 0; i < SIZE; i++) {
    data[i] = (uint8_t)xorshift64star(&tls_data.rng_state);
  }

  // Declare variables at function scope
  uint64_t sum1 = 0;
  uint64_t sum2 = 0;

  /* Without prefetching */
  TIMING_START()
  for (size_t i = 0; i < SIZE; i++) {
    sum1 += data[i] * data[i];
  }
  TIMING_END("Without prefetch");

  /* With prefetching */
  TIMING_START()
  for (size_t i = 0; i < SIZE; i++) {
    if (i + PREFETCH_DISTANCE < SIZE) {
      PREFETCH(&data[i + PREFETCH_DISTANCE]);
    }
    sum2 += data[i] * data[i];
  }
  TIMING_END("With prefetch");

  log_verbose("Results: %llu vs %llu\n", (unsigned long long)sum1,
              (unsigned long long)sum2);

  free(data);
}

/*
 * ARENA ALLOCATOR IMPLEMENTATION
 *
 * Arena allocation is a memory management strategy where you allocate
 * from large blocks and free everything at once. This is much faster
 * than malloc/free for temporary allocations.
 */
static void *arena_alloc(arena_t *arena, size_t size, size_t align) {
  if (!arena || !arena->current)
    return NULL;

  /*
   * Alignment calculation:
   * 1. Get current position in block
   * 2. Round up to next alignment boundary
   * 3. Calculate padding needed
   */
  uintptr_t current = (uintptr_t)(arena->current->data + arena->current->used);
  uintptr_t aligned = (current + align - 1) & ~(align - 1);
  size_t padding = aligned - current;

  /* Check if allocation fits in current block */
  if (arena->current->used + padding + size > arena->current->size) {
    /* Allocate new block */
    arena_block_t *new_block =
        malloc(sizeof(arena_block_t) + arena->block_size);
    if (!new_block)
      return NULL;

    new_block->next = NULL;
    new_block->size = arena->block_size;
    new_block->used = 0;
    arena->current->next = new_block;
    arena->current = new_block;
    atomic_fetch_add(&arena->block_count, 1);

    /* Recursively retry allocation in new block */
    return arena_alloc(arena, size, align);
  }

  arena->current->used += padding + size;
  atomic_fetch_add(&arena->total_allocated, size);

  /* Update peak usage */
  uint64_t current_total = atomic_load(&arena->total_allocated);
  uint64_t peak = atomic_load(&arena->peak_usage);
  while (current_total > peak) {
    if (atomic_compare_exchange_weak(&arena->peak_usage, &peak,
                                     current_total)) {
      break;
    }
  }

  return (void *)aligned;
}

static arena_t *arena_create(size_t block_size) {
  arena_t *arena = malloc(sizeof(arena_t));
  if (!arena)
    return NULL;

  arena->block_size = block_size;
  arena->first = malloc(sizeof(arena_block_t) + block_size);
  if (!arena->first) {
    free(arena);
    return NULL;
  }

  arena->first->next = NULL;
  arena->first->size = block_size;
  arena->first->used = 0;
  arena->current = arena->first;

  atomic_init(&arena->total_allocated, 0);
  atomic_init(&arena->total_freed, 0);
  atomic_init(&arena->peak_usage, 0);
  atomic_init(&arena->block_count, 1);

  return arena;
}

static void arena_destroy(arena_t *arena) {
  if (!arena)
    return;

  /* Calculate total freed */
  uint64_t total = 0;

  /* Free all blocks */
  arena_block_t *block = arena->first;
  while (block) {
    arena_block_t *next = block->next;
    total += block->used;
    free(block);
    block = next;
  }

  atomic_store(&arena->total_freed, total);
  free(arena);
}

/*
 * SIMD OPERATIONS DEMONSTRATION
 *
 * SIMD (Single Instruction, Multiple Data) allows processing multiple
 * data elements in parallel. AVX2 provides 256-bit registers that can
 * process 32 bytes at once.
 */
static void demonstrate_simd(void) {
  /* Create SIMD vector with Hello World pattern */
  __m256i hello1 =
      _mm256_set_epi8('!', 'd', 'l', 'r', 'o', 'W', ' ', 'o', 'l', 'l', 'e',
                      'H', '!', 'd', 'l', 'r', 'o', 'W', ' ', 'o', 'l', 'l',
                      'e', 'H', '!', 'd', 'l', 'r', 'o', 'W', ' ', 'o');

  /* Create vector filled with 'l' */
  __m256i hello2 = _mm256_set1_epi8('l');

  /* Compare vectors - result is 0xFF where equal, 0x00 where not */
  __m256i result = _mm256_cmpeq_epi8(hello1, hello2);

  /* Extract comparison results to integer mask */
  int mask = _mm256_movemask_epi8(result);
  printf("SIMD: Found 'l' at positions (mask): 0x%08X\n", mask);

  /* Count set bits using hardware instruction */
  int popcount = POPCOUNT(mask);
  printf("SIMD: Number of 'l' characters: %d\n", popcount);

  /* Demonstrate SIMD shuffle for string reversal */
  __m256i shuffle_mask = _mm256_set_epi8(
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
      21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);
  __m256i reversed = _mm256_shuffle_epi8(hello1, shuffle_mask);

  /* Extract and print reversed string */
  char reversed_str[33] = {0};
  _mm256_storeu_si256((__m256i *)reversed_str, reversed);
  printf("SIMD: Reversed first 32 bytes: %.32s\n", reversed_str);

  /* Demonstrate SIMD parallel addition */
  __m256i nums1 = _mm256_set_epi32(8, 7, 6, 5, 4, 3, 2, 1);
  __m256i nums2 = _mm256_set_epi32(1, 2, 3, 4, 5, 6, 7, 8);
  __m256i sum = _mm256_add_epi32(nums1, nums2);

  int32_t results[8];
  _mm256_storeu_si256((__m256i *)results, sum);
  printf("SIMD parallel add: ");
  for (int i = 0; i < 8; i++) {
    printf("%d ", results[i]);
  }
  printf("\n");

  /* Demonstrate horizontal operations */
  __m256i hadd_result = _mm256_hadd_epi32(nums1, nums2);
  _mm256_storeu_si256((__m256i *)results, hadd_result);
  printf("SIMD horizontal add: ");
  for (int i = 0; i < 8; i++) {
    printf("%d ", results[i]);
  }
  printf("\n");
}

/*
 * ATOMIC OPERATIONS AND MEMORY ORDERING
 *
 * C11 introduced fine-grained control over memory ordering in concurrent
 * programs. Different orderings provide different guarantees:
 *
 * - memory_order_seq_cst: Sequential consistency (strongest, default)
 * - memory_order_acquire/release: Synchronization pairs
 * - memory_order_relaxed: No ordering guarantees (fastest)
 */
static void demonstrate_atomics(void) {
  memory_order_test_t test = {0};

  /* Sequential consistency - all threads see same order */
  atomic_store(&test.seq_cst, 42);
  int val1 = atomic_load(&test.seq_cst);

  /* Acquire-Release - forms synchronization relationship */
  atomic_store_explicit(&test.acquire_release, 100, memory_order_release);
  int val2 = atomic_load_explicit(&test.acquire_release, memory_order_acquire);

  /* Relaxed - no ordering guarantees */
  atomic_store_explicit(&test.relaxed, 200, memory_order_relaxed);
  int val3 = atomic_load_explicit(&test.relaxed, memory_order_relaxed);

  printf("Atomics - SeqCst: %d, AcqRel: %d, Relaxed: %d\n", val1, val2, val3);

  /* Compare and swap (CAS) - foundation of lock-free algorithms */
  int expected = 200;
  int desired = 300;
  _Bool success = atomic_compare_exchange_strong_explicit(
      &test.relaxed, &expected, desired, memory_order_release,
      memory_order_relaxed);
  printf("CAS %s: expected=%d, actual=%d\n", success ? "succeeded" : "failed",
         200, expected);

  /* Demonstrate atomic RMW (Read-Modify-Write) operations */
  int old = atomic_fetch_add(&test.seq_cst, 10);
  printf("Atomic add: %d + 10 = %d\n", old, atomic_load(&test.seq_cst));

  old = atomic_fetch_and(&test.seq_cst, 0xFF);
  printf("Atomic AND: %d & 0xFF = %d\n", old, atomic_load(&test.seq_cst));

  old = atomic_fetch_or(&test.seq_cst, 0x100);
  printf("Atomic OR: %d | 0x100 = %d\n", old, atomic_load(&test.seq_cst));

  /* Memory fence - ensures ordering without atomic operation */
  atomic_thread_fence(memory_order_seq_cst);
  printf("Memory fence applied\n");

  /* Demonstrate atomic flag (lock-free boolean) */
  atomic_flag flag = ATOMIC_FLAG_INIT;
  if (!atomic_flag_test_and_set(&flag)) {
    printf("Acquired atomic flag\n");
    atomic_flag_clear(&flag);
    printf("Released atomic flag\n");
  }

  /* Hardware memory barriers */
  memory_barrier();
  printf("Hardware memory barrier executed\n");
}

/*
 * DYNAMIC CODE GENERATION
 *
 * This demonstrates generating machine code at runtime.
 * We create a simple function that calls printf.
 *
 * WARNING: This requires executable memory and may not work
 * on all systems due to security restrictions (DEP/NX bit).
 */
/* Simple fallback function for dynamic code demonstration */
static void *generate_code(const char *str) {
  /* Check if we can allocate executable memory */
  void *mem = mmap(NULL, 4096, PROT_READ | PROT_WRITE | PROT_EXEC,
                   MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (mem == MAP_FAILED) {
    log_warning("mmap failed: %s (trying alternative)\n", strerror(errno));
    return (void *)simple_dynamic_hello; /* Fallback */
  }

  /* Copy the string to the executable memory area first */
  char *str_location = (char *)mem + 256; /* Place string after code */
  strcpy(str_location, str);

  /*
   * Corrected x86-64 assembly for: void func(void) { printf(string); }
   */
  uint8_t code[] = {
      /* Function prologue - maintain 16-byte stack alignment */
      0x55,                   /* push rbp */
      0x48, 0x89, 0xe5,       /* mov rbp, rsp */
      0x48, 0x83, 0xe4, 0xf0, /* and rsp, -16 (align to 16 bytes) */
      0x48, 0x83, 0xec, 0x10, /* sub rsp, 16 */

      /* Load string address into RDI (first argument) */
      0x48, 0xbf, 0, 0, 0, 0, 0, 0, 0, 0, /* mov rdi, imm64 (string addr) */

      /* Clear AL (no vector registers used in printf call) */
      0x31, 0xc0, /* xor eax, eax */

      /* Call printf directly (assumes it's in PLT) */
      0x48, 0xb8, 0, 0, 0, 0, 0, 0, 0, 0, /* mov rax, imm64 (printf addr) */
      0xff, 0xd0,                         /* call rax */

      /* Restore stack and return */
      0x48, 0x89, 0xec, /* mov rsp, rbp */
      0x5d,             /* pop rbp */
      0xc3              /* ret */
  };

  /* Patch the addresses */
  uint64_t string_addr = (uint64_t)str_location;
  uint64_t printf_addr = (uint64_t)printf;

  memcpy(code + 12, &string_addr, 8); /* String address */
  memcpy(code + 24, &printf_addr, 8); /* Printf address */

  /* Copy code to executable memory */
  memcpy(mem, code, sizeof(code));

  /* Make sure the instruction cache is flushed */
  __builtin___clear_cache(mem, (char *)mem + sizeof(code));

  /* Verify the memory is executable */
  if (mprotect(mem, 4096, PROT_READ | PROT_EXEC) != 0) {
    log_warning("mprotect failed: %s\n", strerror(errno));
    munmap(mem, 4096);
    return (void *)simple_dynamic_hello;
  }

  log_debug("Dynamic code generated successfully at %p\n", mem);
  return mem;
}

static void debug_generated_code(void *mem, size_t size) {
  printf("Generated code bytes: ");
  uint8_t *bytes = (uint8_t *)mem;
  for (size_t i = 0; i < size; i++) {
    printf("%02x ", bytes[i]);
  }
  printf("\n");
}

/*
 * LOCK-FREE QUEUE OPERATIONS
 *
 * Lock-free data structures use atomic operations instead of locks.
 * This implementation uses Michael & Scott algorithm.
 */
static void enqueue_char(lock_free_queue_t *queue, char c) {
  struct lfq_node *node = pool_alloc(tls_data.local_pool);
  if (!node) {
    /* Fallback to arena */
    node = arena_alloc(tls_data.local_arena, sizeof(struct lfq_node),
                       _Alignof(struct lfq_node));
    if (!node)
      return;
  }

  node->data = c;
  atomic_store(&node->next, NULL);

  struct lfq_node *prev_tail = atomic_exchange(&queue->tail, node);
  if (prev_tail) {
    atomic_store(&prev_tail->next, node);
  } else {
    atomic_store(&queue->head, node);
  }

  atomic_fetch_add(&queue->size, 1);
}

static char dequeue_char(lock_free_queue_t *queue) {
  struct lfq_node *head;

  /* Retry loop for lock-free dequeue */
  while (1) {
    head = atomic_load(&queue->head);
    if (!head)
      return '\0';

    struct lfq_node *next = atomic_load(&head->next);

    /* Try to swing head to next */
    if (atomic_compare_exchange_weak(&queue->head, &head, next)) {
      if (!next) {
        /* Queue became empty */
        atomic_compare_exchange_strong(&queue->tail, &head, NULL);
      }

      char data = head->data;
      pool_free(tls_data.local_pool, head);
      atomic_fetch_sub(&queue->size, 1);
      return data;
    }

    /* CAS failed, retry with backoff */
    cpu_relax();
  }
}

static void lock_free_demo(void) {
  printf("Lock-free queue demonstration\n");

  /* Create queue in arena */
  lock_free_queue_t *queue =
      arena_alloc(tls_data.local_arena, sizeof(lock_free_queue_t),
                  _Alignof(lock_free_queue_t));
  if (!queue)
    return;

  atomic_init(&queue->head, NULL);
  atomic_init(&queue->tail, NULL);
  atomic_init(&queue->size, 0);

  /* Enqueue characters */
  const char *str = "Lock-free!";
  for (const char *p = str; *p; p++) {
    enqueue_char(queue, *p);
  }

  printf("Queue size: %llu\n", (unsigned long long)atomic_load(&queue->size));

  /* Dequeue and print */
  printf("Dequeued: ");
  char c;
  while ((c = dequeue_char(queue)) != '\0') {
    printf("%c", c);
  }
  printf("\n");

  /* Demonstrate atomic flag (spinlock primitive) */
  atomic_flag lock = ATOMIC_FLAG_INIT;

  /* Try to acquire lock with exponential backoff */
  int backoff = 1;
  while (atomic_flag_test_and_set(&lock)) {
    for (int i = 0; i < backoff; i++) {
      cpu_relax();
    }
    backoff = min_with_hint(backoff * 2, 1000);
  }

  printf("Acquired spinlock after backoff\n");
  atomic_flag_clear(&lock);
  printf("Released spinlock\n");

  /* Demonstrate ABA problem prevention */
  tagged_ptr_t tagged = {0};
  atomic_init(&tagged.ptr, NULL);
  atomic_init(&tagged.counter, 0);

  void *old_ptr = NULL;
  uint64_t old_counter = 0;
  void *new_ptr = queue;

  /* Update with counter to prevent ABA */
  while (1) {
    old_ptr = atomic_load(&tagged.ptr);
    old_counter = atomic_load(&tagged.counter);

    if (atomic_compare_exchange_weak(&tagged.ptr, &old_ptr, new_ptr)) {
      atomic_store(&tagged.counter, old_counter + 1);
      break;
    }
  }

  printf("Tagged pointer updated with counter %llu\n",
         (unsigned long long)(old_counter + 1));
}

/*
 * COROUTINE IMPLEMENTATION
 *
 * Coroutines allow functions to yield and resume.
 * This simple implementation prints one character at a time.
 */
static void run_coroutine(coroutine_t *coro) {
  static const char *hello = "Hello World!";
  if (coro->state < 12) {
    printf("%c", hello[coro->state]);
    fflush(stdout);
    coro->state++;

    /* Simulate some work with pause instruction */
    for (int i = 0; i < 100; i++) {
      cpu_relax();
    }
  }
}

/*
 * PARALLEL HELLO WORLD
 *
 * Each thread prints a portion of "Hello World!"
 * Demonstrates thread creation and synchronization.
 */
static int parallel_hello(void *arg) {
  int id = *(int *)arg;
  const char *part;

  /* Set thread ID in TLS */
  tls_data.thread_id = id;

  /* Assign work based on thread ID */
  switch (id) {
  case 0:
    part = "Hel";
    break;
  case 1:
    part = "lo ";
    break;
  case 2:
    part = "Wor";
    break;
  case 3:
    part = "ld!";
    break;
  default:
    return 0;
  }

  /* Simulate variable work with thread-local RNG */
  uint64_t delay = xorshift64star(&tls_data.rng_state) % 1000000;
  for (uint64_t i = 0; i < delay; i++) {
    cpu_relax(); /* Yield to other threads */
  }

  /* Use atomic operations for thread-safe printing */
  static atomic_int print_order = 0;
  int my_order = atomic_fetch_add(&print_order, 1);

  /* Measure thread performance */
  uint64_t start = rdtsc();
  printf("[Thread %d, order %d]: %s\n", id, my_order, part);
  uint64_t end = rdtsc();

  tls_data.perf_counter = end - start;

  return 0;
}

/*
 * XORSHIFT64* PRNG
 *
 * A fast, high-quality pseudorandom number generator.
 * Good for non-cryptographic uses.
 */
static uint64_t HOT_FUNC xorshift64star(uint64_t *state) {
  uint64_t x = *state;
  x ^= x >> 12;
  x ^= x << 25;
  x ^= x >> 27;
  *state = x;
  return x * 0x2545F4914F6CDD1DULL;
}

/* Original functions continue below... */

static char *process_with_vla(const char *input, size_t len) {
  recursion_depth++;
  log_debug("Entering VLA processing (recursion depth: %d)\n", recursion_depth);

  /* Guard against stack overflow */
  if (recursion_depth > 100) {
    log_error("Recursion limit reached\n");
    longjmp(jump_buffer, 1);
  }

  /* Create 1D VLA */
  char temp[len + 1];
  strcpy(temp, input);

  /* Create 2D VLA matrix */
  int matrix[len][len];

  /* Fill matrix with pattern */
  for (size_t i = 0; i < len; i++) {
    for (size_t j = 0; j < len; j++) {
      matrix[i][j] = (i + j) % 256;
    }
  }

  /* Create 3D VLA for demonstration */
  char cube[2][len / 2][len / 2];
  memset(cube, 0, sizeof(cube));

  /* Allocate result */
  char *result = malloc(len + 1);
  if (!result) {
    recursion_depth--;
    return NULL;
  }
  strcpy(result, temp);

  log_debug("Exiting VLA processing (matrix sum: %d)\n", matrix[0][0]);
  recursion_depth--;
  return result;
}

static void demonstrate_goto(int *result) {
  int n = 5;
  int factorial = 1;
  int i = 1;

  log_debug("Computing 5! using goto\n");

loop_start:
  if (i > n)
    goto loop_end;
  factorial *= i;
  i++;
  goto loop_start;

loop_end:
  *result = factorial;
  log_debug("5! = %d\n", factorial);

  /* Error handling pattern with goto */
  char *buffer1 = NULL;
  char *buffer2 = NULL;
  FILE *file = NULL;

  buffer1 = malloc(100);
  if (!buffer1)
    goto cleanup;

  buffer2 = malloc(100);
  if (!buffer2)
    goto cleanup;

  file = fopen("/dev/null", "w");
  if (!file)
    goto cleanup;

  /* Do work */
  strcpy(buffer1, "goto can be useful");
  strcpy(buffer2, "for cleanup patterns");
  fprintf(file, "%s %s\n", buffer1, buffer2);

cleanup:
  /* Cleanup in reverse order */
  if (file)
    fclose(file);
  if (buffer2)
    free(buffer2);
  if (buffer1)
    free(buffer1);

  if (!file || !buffer2 || !buffer1) {
    log_warning("Cleanup after error in goto demonstration\n");
  }
}

static double complex CONST_FUNC hello_complex(void) {
  /* Create complex numbers from ASCII values */
  double complex h = 72.0 + 0.0 * I;  /* 'H' */
  double complex e = 101.0 + 0.0 * I; /* 'e' */
  double complex l = 108.0 + 0.0 * I; /* 'l' */
  double complex o = 111.0 + 0.0 * I; /* 'o' */

  /* Complex arithmetic */
  double complex sum = h + e + l + l + o;
  double complex avg = sum / 5.0;

  /* Add imaginary component using Euler's formula */
  double complex phase = cexp(I * M_PI / 4); /* e^(i*π/4) */

  return avg * phase;
}

static void print_container(const void *container) {
  const string_container_t *cont = (const string_container_t *)container;
  printf("[Container] %s (len=%zu, checksum=%016llx, version=%u, refs=%d)\n",
         cont->data, cont->length, (unsigned long long)cont->checksum,
         cont->metadata.version, atomic_load(&cont->refcount));
}

static char *to_upper_container(const void *container) {
  const string_container_t *cont = (const string_container_t *)container;
  char *upper = malloc(cont->length + 1);
  if (!upper)
    return NULL;

  /* Vectorized uppercase conversion for demonstration */
  size_t i;
  for (i = 0; i + 16 <= cont->length; i += 16) {
    __m128i chars = _mm_loadu_si128((const __m128i *)&cont->data[i]);
    __m128i mask = _mm_and_si128(_mm_cmpgt_epi8(chars, _mm_set1_epi8('a' - 1)),
                                 _mm_cmplt_epi8(chars, _mm_set1_epi8('z' + 1)));
    __m128i upper_chars =
        _mm_sub_epi8(chars, _mm_and_si128(mask, _mm_set1_epi8(32)));
    _mm_storeu_si128((__m128i *)&upper[i], upper_chars);
  }

  /* Handle remaining characters */
  for (; i < cont->length; i++) {
    char c = cont->data[i];
    upper[i] = (c >= 'a' && c <= 'z') ? c - 32 : c;
  }
  upper[cont->length] = '\0';
  return upper;
}

static size_t PURE_FUNC get_length_container(const void *container) {
  const string_container_t *cont = (const string_container_t *)container;
  return cont->length;
}

static void destroy_container(void *container) {
  string_container_t *cont = (string_container_t *)container;
  if (atomic_fetch_sub(&cont->refcount, 1) == 1) {
    /* Last reference, actually destroy */
    release_string_container(cont);
  }
}

static flex_buffer_t *create_flex_buffer(size_t capacity) {
  flex_buffer_t *buf = malloc(sizeof(flex_buffer_t) + capacity);
  if (buf) {
    buf->capacity = capacity;
    buf->used = 0;
  }
  return buf;
}

static void *secure_alloc(size_t size) {
  size_t total_size = size + sizeof(size_t) + 16; /* Size + canary space */
  void *original_ptr = malloc(total_size);
  if (!original_ptr)
    return NULL;

  /* Add size header */
  *((size_t *)original_ptr) = size;

  /* Add canaries */
  uint64_t *front_canary = (uint64_t *)((char *)original_ptr + sizeof(size_t));
  uint64_t *back_canary =
      (uint64_t *)((char *)original_ptr + sizeof(size_t) + 8 + size);
  *front_canary = STACK_CANARY;
  *back_canary = STACK_CANARY;

  void *user_ptr = (char *)original_ptr + sizeof(size_t) + 8;

  /* Secure initialization */
  memset(user_ptr, 0, size);

  return user_ptr;
}

static void secure_free(void *ptr) {
  if (!ptr)
    return;

  void *original_ptr = (char *)ptr - sizeof(size_t) - 8;
  size_t size = *((size_t *)original_ptr);

  /* Check canaries */
  uint64_t *front_canary = (uint64_t *)((char *)ptr - 8);
  uint64_t *back_canary = (uint64_t *)((char *)ptr + size);

  if (*front_canary != STACK_CANARY || *back_canary != STACK_CANARY) {
    log_error("Buffer overflow detected in secure_free!\n");
    abort();
  }

  /* Secure wipe using volatile to prevent optimization */
  volatile unsigned char *p =
      (volatile unsigned char *)ptr; // Changed to unsigned char
  for (size_t i = 0; i < size; i++) {
    p[i] = 0;
  }

  /* Additional passes for paranoid security */
  for (size_t i = 0; i < size; i++) {
    p[i] = 0xFF; // Now safe
  }
  for (size_t i = 0; i < size; i++) {
    p[i] = 0xAA; // Now safe
  }
  for (size_t i = 0; i < size; i++) {
    p[i] = 0;
  }

  free(original_ptr);
}

static char *decrypt_string(const char *encrypted, size_t length) {
  char *decrypted = malloc(length + 1);
  if (!decrypted) {
    log_error("Failed to allocate memory for decryption\n");
    return NULL;
  }

  /* Vectorized XOR decryption */
  __m128i key = _mm_set1_epi8(ENCRYPTION_KEY);
  size_t i;

  for (i = 0; i + 16 <= length; i += 16) {
    __m128i enc = _mm_loadu_si128((const __m128i *)&encrypted[i]);
    __m128i dec = _mm_xor_si128(enc, key);
    _mm_storeu_si128((__m128i *)&decrypted[i], dec);
  }

  /* Handle remaining bytes */
  for (; i < length; i++) {
    decrypted[i] = OBFUSCATE_CHAR(encrypted[i], ENCRYPTION_KEY);
  }

  decrypted[length] = '\0';
  log_debug("Decryption complete: %zu bytes processed\n", length);
  return decrypted;
}

static uint64_t PURE_FUNC compute_checksum(const char *data, size_t length) {
  /* FNV-1a hash - 64-bit */
  uint64_t hash = 14695981039346656037ULL;
  const uint64_t prime = 1099511628211ULL;

  /* Process 8 bytes at a time for performance */
  size_t i;
  for (i = 0; i + 8 <= length; i += 8) {
    uint64_t chunk;
    memcpy(&chunk, &data[i], 8);
    hash ^= chunk;
    hash *= prime;
  }

  /* Handle remaining bytes */
  for (; i < length; i++) {
    hash ^= (uint64_t)(unsigned char)data[i];
    hash *= prime;
  }

  return hash;
}

static string_container_t *preprocess_string(const char *input) {
  string_container_t *container = secure_alloc(sizeof(string_container_t));
  if (!container) {
    log_error("Failed to allocate string container\n");
    return NULL;
  }

  size_t len = strlen(input);
  container->data = malloc(len + 1);
  if (!container->data) {
    log_error("Failed to allocate string data\n");
    secure_free(container);
    return NULL;
  }

  strcpy(container->data, input);
  container->length = len;
  container->checksum = compute_checksum(input, len);
  container->free_func = free;

  /* Update thread-local stats */
  tls_data.stats.cache_hits++;

  /* Simulate random error for demonstration */
  if (UNLIKELY(rand() % 10000 == 0)) {
    log_warning("Simulating random error with longjmp\n");
    longjmp(jump_buffer, 1);
  }

  log_debug("Container created: %zu bytes, checksum %016llx\n", len,
            (unsigned long long)container->checksum);

  return container;
}

static void release_string_container(string_container_t *container) {
  if (!container)
    return;

  if (container->data && container->free_func) {
    container->free_func(container->data);
  }

  secure_free(container);
  log_debug("Container released\n");
}

static void signal_handler(int signum) {
  signal_received = signum;

  /* Re-raise signal for proper termination */
  if (signum == SIGINT || signum == SIGTERM) {
    signal(signum, SIG_DFL);
    raise(signum);
  }
}

/* Weak symbol definition (can be overridden) */
void WEAK optional_feature(void) {
  printf("Default optional feature implementation\n");
}

static void DESTRUCTOR cleanup_handler(void) {
  print_header("SYSTEM SHUTDOWN", BRIGHT_RED);

  if (signal_received) {
    printf(WARNING " Program interrupted by signal %d\n", signal_received);
  }

  printf("\n" BRIGHT_CYAN "Thread Statistics:" RESET "\n");
  printf("  " STAR " Cache hits: " GREEN "%llu" RESET "\n",
         (unsigned long long)tls_data.stats.cache_hits);
  printf("  " STAR " Cache misses: " RED "%llu" RESET "\n",
         (unsigned long long)tls_data.stats.cache_misses);
  printf("  " STAR " Performance cycles: " BLUE "%llu" RESET "\n",
         (unsigned long long)tls_data.perf_counter);

  typewriter_effect(
      "\nThank you for exploring the ultimate in C programming!\n",
      BRIGHT_MAGENTA);

  printf(SHOW_CURSOR RESET);
}

/*
 * End of the Ultimate Hello World Program
 *
 * This program has demonstrated virtually every feature of the C language,
 * from basic concepts to cutting-edge C23 features, including:
 *
 * - Advanced preprocessor metaprogramming
 * - Lock-free data structures and atomics
 * - SIMD vectorization
 * - Dynamic code generation
 * - Custom memory allocators
 * - Coroutines and computed goto
 * - Type introspection and _Generic
 * - Thread-local storage
 * - Weak symbols and aliases
 * - Complex numbers
 * - Unicode support
 * - And much, much more!
 *
 * Every line has been crafted to educate and inspire,
 * showing that even the simplest task - printing "Hello World!" -
 * can be an opportunity to explore the full depth and beauty of C.
 */