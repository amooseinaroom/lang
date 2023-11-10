
#pragma once

#include <stdio.h>
#include <stdarg.h>

typedef signed __int8  s8;
typedef signed __int16 s16;
typedef signed __int32 s32;
typedef signed __int64 s64;

typedef unsigned __int8  u8;
typedef unsigned __int16 u16;
typedef unsigned __int32 u32;
typedef unsigned __int64 u64;

// assuming x64
typedef s64 ssize;
typedef u64 usize;

typedef float  f32;
typedef double f64;

#define null 0

#define flag(index) ( 1 << (index) )

typedef char * cstring;

// C static array count
#define carray_count(static_array) ( sizeof(static_array) / sizeof((static_array)[0]) )

const f32 pi32 = 3.14159265358979323846;

#define array_type(name, type) \
struct name \
{ \
    usize count; \
    type  *base; \
};

#define buffer_type(buffer_name, array_name, type) \
array_type(array_name, type); \
union buffer_name \
{ \
    array_name array; \
    \
    struct \
    { \
        usize count; \
        type  *base; \
        usize capacity; \
    }; \
};

buffer_type(base_buffer, base_array, u8);

buffer_type(u8_buffer, u8_array, u8);
buffer_type(u32_buffer, u32_array, u32);
buffer_type(s32_buffer, s32_array, s32);
buffer_type(f32_buffer, f32_array, f32);

typedef u8_array string;

buffer_type(string_buffer, string_array, string);

struct base_single_list_entry
{
    base_single_list_entry *next;
};

#define single_list_type(name, type) \
struct name \
{ \
    type *first; \
    type **tail_next; \
};

typedef base_single_list_entry **base_list_tail_next;

single_list_type(base_single_list, base_single_list_entry);

// without 0 terminal character
#define s(cstring_literal) string { carray_count(cstring_literal) - 1, (u8 *) cstring_literal }

// printf("%.*s", fs(my_string));
#define fs(string) ((int) (string).count), ((char *) (string).base)

static s32 clamp(s32 min, s32 value, s32 max)
{
    if (value < min)
        return min;
    else if (value > max)
        return max;
    else
        return value;
}

static s32 minimum(s32 a, s32 b)
{
    if (a < b)
        return a;
    else
        return b;
}

static s32 maximum(s32 a, s32 b)
{
    if (a >= b)
        return a;
    else
        return b;
}

static s32 absolute(s32 a)
{
    if (a < 0.0f)
        return -a;
    else
        return a;
}

static s32 sign(s32 a)
{
    if (a < 0.0f)
        return -1;
    else if (a > 0.0f)
        return 1;
    else
        return 0;
}

static u32 clamp(u32 min, u32 value, u32 max)
{
    if (value < min)
        return min;
    else if (value > max)
        return max;
    else
        return value;
}

static u32 minimum(u32 a, u32 b)
{
    if (a < b)
        return a;
    else
        return b;
}

static u32 maximum(u32 a, u32 b)
{
    if (a >= b)
        return a;
    else
        return b;
}

static usize minimum(usize a, usize b)
{
    if (a < b)
        return a;
    else
        return b;
}

static usize maximum(usize a, usize b)
{
    if (a >= b)
        return a;
    else
        return b;
}

static f32 clamp(f32 min, f32 value, f32 max)
{
    if (value < min)
        return min;
    else if (value > max)
        return max;
    else
        return value;
}

static f32 minimum(f32 a, f32 b)
{
    if (a < b)
        return a;
    else
        return b;
}

static f32 maximum(f32 a, f32 b)
{
    if (a >= b)
        return a;
    else
        return b;
}

static f32 absolute(f32 a)
{
    if (a < 0.0f)
        return -a;
    else
        return a;
}

static f32 sign(f32 a)
{
    if (a < 0.0f)
        return -1;
    else if (a > 0.0f)
        return 1;
    else
        return 0;
}

static f32 lerp(f32 a, f32 b, f32 factor)
{
    f32 result = a * (1.0f - factor) + b * factor;
    return result;
}

struct code_location
{
    cstring file;
    cstring function;
    u32 line;
};

union byte_count_info
{
    usize value;
    
    struct
    {
        usize byte : 10;
        usize kilo : 10;
        usize mega : 10;
        usize giga : 34;
    };
};

#define _get_call_location() code_location { __FILE__, __FUNCTION__, __LINE__ }
#define get_call_location() _get_call_location()
#define call_location_argument code_location call_location
    
#define platform_fatal_error_location_va_declaration \
    static bool platform_fatal_error_location_va(code_location location, cstring label, cstring format, va_list va_arguments)

#define platform_fatal_error_location_declaration \
    static bool platform_fatal_error_location(code_location location, cstring label, cstring format, ...)

platform_fatal_error_location_va_declaration;
platform_fatal_error_location_declaration;

#define platform_conditional_fatal_error_location(condition, location, label, format, ...)  \
    if (!(condition)) \
        if (platform_fatal_error_location(location, label, format,  __VA_ARGS__)) \
            __debugbreak();

#if defined _DEBUG

    #define debug_get_call_location()    , get_call_location()
    #define debug_call_location_argument , code_location debug_location
    #define debug_call_location          , debug_location
    
    #define assert_location(condition, location, ...) \
        platform_conditional_fatal_error_location(condition, location, "Assertion Failure", "Assertion:\n    " # condition "\nfailed.\n\n" __VA_ARGS__)

    #define assert(condition, ...) assert_location(condition, get_call_location(), __VA_ARGS__)
    
#else

    #define debug_get_call_location()
    #define debug_call_location_argument
    #define debug_call_location
    
    #define assert_location(...)
    #define assert(...)

#endif

#define require_location(condition, location, ...) \
        platform_conditional_fatal_error_location(condition, location, "Error", "Requirement:\n    " # condition "\nfailed.\n\n" __VA_ARGS__)

#define require(condition, ...) require_location(condition, get_call_location(), __VA_ARGS__)

#define unreachable_codepath  assert(false, "unreachable codepath")

#define cases_complete_message(format, ...) default: { assert(false, "unhandled case: " format, __VA_ARGS__); } break;
#define cases_complete                      default: { assert(false, "unhandled case"); } break;

#define require_result(expression, result, format) { \
    auto value = (expression); \
    require(value == (result), "unexpected value " format "\n", value); \
}

#define platform_require(condition, ...) platform_require_location(condition, get_call_location(), __VA_ARGS__)

template <typename F>
struct Deferer {
    F f;
    
    Deferer(F f) : f(f) {}
    ~Deferer() { f(); }
};

template <typename F>
Deferer<F> operator++(F f) { return Deferer<F>(f); }

// macro chain
#define _mchain(a, b) a ## b
#define mchain(a, b) _mchain(a, b)

#define defer \
auto mchain(_defer_, __LINE__) = ++[&]()

#define mswap(a, b) { auto temp = a; a = b; b = temp; }

#define mlist_enum(entry, prefix) \
    prefix ## entry,

#define mlist_name(entry, ...) \
    s(# entry),
    
#define mlist_byte_count(entry, prefix) \
    sizeof(prefix ## entry),

#define using(struct, field)      auto field = &(struct)->field
#define local_copy(struct, field) auto field = (struct).field

#define field_to_struct_pointer(type, field, pointer) ( (type *) ((u8 *) (pointer) - ((usize) &((type *) null)->field)) )

#define scope_save(var) \
    auto mchain(_scope_backup_, __LINE__) = var; \
    defer { var = mchain(_scope_backup_, __LINE__); };
    
#define scope_push(var, value) \
    scope_save(var); \
    var = value;

#define value_to_u8_array(value) u8_array{ sizeof(value), (u8 *) &value }

#define values_are_equal(a_value, b_value) bytes_are_equal(sizeof(a_value), (u8 *) &(a_value), (u8 *) &(b_value))

static bool bytes_are_equal(usize byte_count, u8 *a, u8 *b)
{
    for (usize i = 0; i < byte_count; i++)
    {
        if (a[i] != b[i])
            return false;
    }
    
    return true;
}

bool operator==(string a, string b)
{
    if (a.count != b.count)
        return false;
    
    return bytes_are_equal(a.count, a.base, b.base);
}

bool operator!=(string a, string b)
{
    return !(a == b);
}


#include <intrin.h>

// returns 0 on 0
u32 get_highest_bit_index(u64 value)
{
    unsigned long index; // because unsigned long is soooo different form unsigned int. It's not!
    bool is_none_zero = _BitScanReverse64(&index, value);
    if (!is_none_zero)
        index = 0;
        
    return (u32) index + 1;
}

void advance(u8_array *array, usize count = 1)
{
    assert(array->count >= count);
    array->base  += count;
    array->count -= count;
}

string skip(string *iterator, usize count)
{
    string result = { count, iterator->base };
    advance(iterator, count);
    
    return result;
}

platform_fatal_error_location_va_declaration;

platform_fatal_error_location_declaration
{
    va_list va_arguments;
    va_start(va_arguments, format);
    
    bool do_break = platform_fatal_error_location_va(location, label, format, va_arguments);
    
    va_end(va_arguments);
    
    return do_break;
}

#if defined _DEBUG

const int debug_platform_allocation_table_count = 1 << 12;

struct debug_platform_allocation_table
{
    u8            *bases[debug_platform_allocation_table_count];
    usize         byte_counts[debug_platform_allocation_table_count];
    code_location locations[debug_platform_allocation_table_count];
    usize count;
    
    usize byte_count;
};

debug_platform_allocation_table global_debug_platform_allocation_table;

#endif

#define make_tail_next(pointer_to_first)   new_base_list((base_single_list_entry **) (pointer_to_first))
#define append_tail_next(tail_next, entry) append_base_list(tail_next, (base_single_list_entry *) (entry))

#define begin_list(list)         begin_base_list((base_single_list *) (list))
#define append_list(list, entry) append_base_list(&((base_single_list *) (list))->tail_next, (base_single_list_entry *) (entry))

base_list_tail_next new_base_list(base_single_list_entry **first)
{
    assert(first && !*first);
    return (base_list_tail_next) first;
}

void begin_base_list(base_single_list *list)
{
    list->first = null;
    list->tail_next = &list->first;
}

void append_base_list(base_single_list_entry ***tail_next, base_single_list_entry *entry)
{
    assert(!entry->next);
    **tail_next = entry;
    *tail_next = &entry->next;
}

union vec2s
{
    struct
    {
        s32 x, y;
    };
    
    s32 values[2];
};

union box2s
{
    struct
    {
        vec2s min, max;
    };
    
    vec2s extends[2];
};

box2s box2_size(s32 x, s32 y, s32 width, s32 height)
{
    return { x, y, x + width, y + height };
}