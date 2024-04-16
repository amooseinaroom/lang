
module lang;

// if you want to override assert, you need the lang module to be able to see other functions
// so we import platform
import platform;

// these can be overridden as needed
def lang_debug                     = false;
def lang_enable_array_bound_checks = lang_debug; // note that array bounds checking is quite expensive

// can be overriden by platform module, to actually do something
// require will always be evaluated, while assert should only evaluate if lang_debug is true
func assert assert_type { }
func require assert_type { }

type usize u64;
type ssize s64;

type b8 u8;
type b32 u32;

type string u8[];

type cstring u8 ref;

def null  = 0 cast(u8 ref);
def false = 0 cast(b8);
def true  = 1 cast(b8);

// all dynamic arrays share this layout, like u8[]
struct lang_base_array
{
    count usize;
    base  u8 ref;
}

struct lang_code_location
{
    module   string;
    file     string;
    function string;
    file_index u32;
    line       u32;
    column     u32;
}

// same order as ast_type_list in lang.h
enum lang_type_info_type u32
{
    empty; // unused
    number;
    enumeration;
    function;
    compound;
    union;
    array;
}

struct lang_type_info
{
    alias             string;

    expand actual_type union
    {
        reference        u8 ref;
        number_type      lang_type_info_number ref;
        enumeration_type lang_type_info_enumeration ref;
        array_type       lang_type_info_array ref;
        compound_type    lang_type_info_compound ref;
        union_type       lang_type_info_union ref;
        function_type    lang_type_info_function ref;
    };

    type_type         lang_type_info_type;
    byte_count        usize;
    indirection_count u32;
    byte_alignment    u32;
}

enum lang_type_info_number_type u32
{
    u8;
    u16;
    u32;
    u64;

    s8;
    s16;
    s32;
    s64;

    f32;
    f64;
}

struct lang_type_info_number
{
    number_type              lang_type_info_number_type;
    byte_count_and_alignment u32;
    is_float                 b8;
    is_signed                b8;
}

struct lang_type_info_compound
{
    fields         lang_type_info_compound_field[];
    byte_count     usize;
    byte_alignment u32;
}

struct lang_type_info_compound_field
{
    type        lang_type_info;
    name        string;
    byte_offset usize;
}

struct lang_type_info_union
{
    fields         lang_type_info_union_field[];
    byte_count     usize;
    byte_alignment u32;
}

struct lang_type_info_union_field
{
    type lang_type_info;
    name string;
}

struct lang_type_info_function
{
    input  lang_type_info_compound ref;
    output lang_type_info_compound ref;
}

struct lang_type_info_array
{
    item_type  lang_type_info;

    // 0 means is not fixed size
    item_count usize;
    byte_count usize;
}

struct lang_type_info_enumeration
{
    item_type  lang_type_info;
    items      lang_type_info_enumeration_item[];
}

struct lang_type_info_enumeration_item
{
    name  string;
    value u64;
}

struct lang_typed_value
{
    type lang_type_info;

    expand value union
    {
        // for union, compound, functions and reference values
        base       u8 ref;

        base_array lang_base_array ref;

    // requires union literal field support in C++ backend (or switch to C backend, bot that's just a hack)
    multiline_comment
    {
        // for numbers and enum values
        u8_number  u8;
        u16_number u16;
        u32_number u32;
        u64_number u64; // accessing this is always fine for any unsinged interger and enum values

        s8_number  s8;
        s16_number s16;
        s32_number s32;
        s64_number s64; // accessing this is always fine for any singed interger

        // you have to know access the proper type for floating point numbers
        f32_number f32;
        f64_number f64;
    }

    };
}

// placeholders, actual array size will be updated when compiled
struct lang_type_info_table
{
    number_types           lang_type_info_number[1];

    enumeration_types      lang_type_info_enumeration[1];
    enumeration_item_types lang_type_info_enumeration_item[1];

    array_types            lang_type_info_array[1];

    compound_types         lang_type_info_compound[1];
    compound_field_types   lang_type_info_compound_field[1];

    union_types            lang_type_info_union[1];
    union_field_types      lang_type_info_union_field[1];

    function_types         lang_type_info_function[1];
}

def lang_type_table = {} lang_type_info_table;

struct lang_variable_info
{
    type lang_type_info;
    name string;
    base u8 ref;
}

// placeholders, actual array size will be updated when compiled
def lang_global_variables = {} lang_variable_info[1];

func assert_type(condition_text = get_call_argument_text(condition), condition b8, location = get_call_location(), format = "", expand arguments = {} lang_typed_value[]);

func lang_assert_array_bounds(index usize, count usize) (result usize)
{
    if lang_enable_array_bound_checks
        assert(index < count, "array index is out of bounds, index % >= count %", index, count);

    return index;
}