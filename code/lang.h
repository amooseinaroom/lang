#pragma once

#if defined LANG_BREAK_ON_ERROR

#define lang_maybe_break_on_error() \
    { \
        printf("\n%.*s\n", fs(parser->error_messages.memory.array)); \
        platform_conditional_fatal_error_location(false, get_call_location(), "Internal Debug Breakpoint", "Hit 'Continue' to see error messages"); \
    }

#else

#define lang_maybe_break_on_error()

#endif

#include "platform.h"
#include "utf8_string.h"
#include "crc32.h"
//#include "hash_string.h"
//#include "hash_table.h"

#define ast_node_list(macro, ...) \
    macro(base_node, __VA_ARGS__) \
    macro(module, __VA_ARGS__) \
    macro(module_reference, __VA_ARGS__) \
    macro(file, __VA_ARGS__) \
    macro(file_reference, __VA_ARGS__) \
    macro(array_index, __VA_ARGS__) \
    macro(variable, __VA_ARGS__) \
    macro(enumeration_item, __VA_ARGS__) \
    macro(external_binding, __VA_ARGS__) \
    macro(intrinsic, __VA_ARGS__) \
    macro(function, __VA_ARGS__) \
    macro(function_reference, __VA_ARGS__) \
    macro(function_overloads, __VA_ARGS__) \
    macro(function_call, __VA_ARGS__) \
    macro(argument, __VA_ARGS__) \
    macro(compound_literal, __VA_ARGS__) \
    macro(array_literal, __VA_ARGS__) \
    macro(constant, __VA_ARGS__) \
    macro(assignment, __VA_ARGS__) \
    macro(number, __VA_ARGS__) \
    macro(string_literal, __VA_ARGS__) \
    macro(name_reference, __VA_ARGS__) \
    macro(scope, __VA_ARGS__) \
    macro(branch, __VA_ARGS__) \
    macro(loop, __VA_ARGS__) \
    macro(loop_with_counter, __VA_ARGS__) \
    macro(branch_switch, __VA_ARGS__) \
    macro(branch_switch_case, __VA_ARGS__) \
    macro(function_return, __VA_ARGS__) \
    macro(scope_control, __VA_ARGS__) \
    macro(dereference, __VA_ARGS__) \
    macro(field_dereference, __VA_ARGS__) \
    macro(get_type_info, __VA_ARGS__) \
    macro(type_byte_count, __VA_ARGS__) \
    macro(get_function_reference, __VA_ARGS__) \
    macro(get_call_location, __VA_ARGS__) \
    macro(get_call_argument_text, __VA_ARGS__) \
    macro(unary_operator, __VA_ARGS__) \
    macro(binary_operator, __VA_ARGS__) \

#define ast_unary_operator_list(macro, ...) \
    macro(not, __VA_ARGS__) \
    macro(bit_not, __VA_ARGS__) \
    macro(negate, __VA_ARGS__) \
    macro(take_reference, __VA_ARGS__) \
    macro(cast, __VA_ARGS__) \

#define ast_binary_operator_list(macro, ...) \
    macro(or, __VA_ARGS__) \
    macro(and, __VA_ARGS__) \
    macro(xor, __VA_ARGS__) \
    \
    macro(is, __VA_ARGS__) \
    macro(is_not, __VA_ARGS__) \
    macro(is_less, __VA_ARGS__) \
    macro(is_less_equal, __VA_ARGS__) \
    macro(is_greater, __VA_ARGS__) \
    macro(is_greater_equal, __VA_ARGS__) \
    \
    macro(bit_or, __VA_ARGS__) \
    macro(bit_and, __VA_ARGS__) \
    macro(bit_xor, __VA_ARGS__) \
    macro(bit_shift_left, __VA_ARGS__) \
    macro(bit_shift_right, __VA_ARGS__) \
    \
    macro(add, __VA_ARGS__) \
    macro(subtract, __VA_ARGS__) \
    macro(multiply, __VA_ARGS__) \
    macro(divide, __VA_ARGS__) \
    macro(modulo, __VA_ARGS__) \

#define ast_type_list(macro, ...) \
    macro(empty_type, __VA_ARGS__) \
    macro(number_type, __VA_ARGS__) \
    macro(enumeration_type, __VA_ARGS__) \
    macro(function_type, __VA_ARGS__) \
    macro(compound_type, __VA_ARGS__) \
    macro(union_type, __VA_ARGS__) \
    macro(array_type, __VA_ARGS__) \
    \
    macro(expression_reference_type, __VA_ARGS__) \
    macro(alias_type, __VA_ARGS__) \

#define menum(entry, prefix) \
    prefix ## entry,

#define menum_name(entry, ...) \
    s(# entry),

#define menum_field(entry, ...) \
    ast_ ## entry entry;

enum ast_node_type
{
    ast_type_list(menum, ast_node_type_)
    ast_node_list(menum, ast_node_type_)

    ast_node_type_count,
};

enum ast_unary_operator_type
{
    ast_unary_operator_list(menum, ast_unary_operator_type_)

    ast_unary_operator_type_count,
};

enum ast_binary_operator_type
{
    ast_binary_operator_list(menum, ast_binary_operator_type_)

    ast_binary_operator_type_count,
};

string ast_unary_operator_names[] =
{
    ast_unary_operator_list(menum_name)
};

string ast_binary_operator_names[] =
{
    ast_binary_operator_list(menum_name)
};

u32 ast_binary_operator_precedence[] =
{
    1, // or
    2, // and
    3, // xor
    //
    4, // is
    4, // is_not
    4, // is_less
    4, // is_less_equal
    4, // is_greater
    4, // is_greater_equal
    //
    5, // bit_or
    6, // bit_and
    7, // bit_xor
    8, // bit_shift_left
    8, // bit_shift_right
    //
    9, // add
    9, // subtract
    10, // multiply
    10, // divide
    10, // modulo
};

string ast_scope_control_names[] =
{
    s("break"),
    s("continue")
};

string lang_keywords[] =
{
    s("if"),
    s("else"),
    s("while"),
    s("loop"),
    s("return"),
    s("continue"),
    s("break"),
    s("switch"),
    s("case"),
    ast_unary_operator_list(menum_name)
    ast_binary_operator_list(menum_name)
};

string ast_node_type_names[] =
{
    ast_type_list(menum_name)
    ast_node_list(menum_name)
};

#define lang_base_number_type_list(macro, ...) \
    macro(u8, __VA_ARGS__) \
    macro(u16, __VA_ARGS__) \
    macro(u32, __VA_ARGS__) \
    macro(u64, __VA_ARGS__) \
    macro(s8, __VA_ARGS__) \
    macro(s16, __VA_ARGS__) \
    macro(s32, __VA_ARGS__) \
    macro(s64, __VA_ARGS__) \
    macro(f32, __VA_ARGS__) \
    macro(f64, __VA_ARGS__) \

#define lang_base_alias_type_list(macro, ...) \
    macro(b8, __VA_ARGS__) \
    macro(b32, __VA_ARGS__) \
    macro(usize, __VA_ARGS__) \
    macro(ssize, __VA_ARGS__) \
    macro(string, __VA_ARGS__) \
    macro(lang_code_location, __VA_ARGS__) \
    macro(cstring, __VA_ARGS__) \
    macro(lang_type_info_type, __VA_ARGS__) \
    macro(lang_type_info, __VA_ARGS__) \
    macro(lang_type_info_number_type, __VA_ARGS__) \
    macro(lang_type_info_number, __VA_ARGS__) \
    macro(lang_type_info_compound_field, __VA_ARGS__) \
    macro(lang_type_info_compound, __VA_ARGS__) \
    macro(lang_type_info_union_field, __VA_ARGS__) \
    macro(lang_type_info_union, __VA_ARGS__) \
    macro(lang_type_info_array, __VA_ARGS__) \
    macro(lang_type_info_enumeration, __VA_ARGS__) \
    macro(lang_type_info_enumeration_item, __VA_ARGS__) \
    macro(lang_typed_value, __VA_ARGS__) \
    macro(lang_type_info_table, __VA_ARGS__) \

#define lang_base_constant_list(macro, ...) \
    macro(null, __VA_ARGS__) \
    macro(false, __VA_ARGS__) \
    macro(true, __VA_ARGS__) \
    macro(build_debug, __VA_ARGS__) \
    macro(lang_type_table, __VA_ARGS__) \
    macro(lang_global_variables, __VA_ARGS__) \

#define lang_base_function_list(macro, ...) \
    macro(lang_assert_array_bounds, __VA_ARGS__) \

enum lang_base_number_type
{
    lang_base_number_type_list(menum, lang_base_number_type_)

    lang_base_number_type_count,
};

enum lang_base_alias_type
{
    lang_base_alias_type_list(menum, lang_base_alias_type_)

    lang_base_alias_type_count,
};

enum lang_base_type
{
    lang_base_number_type_list(menum, lang_base_type_)
    lang_base_alias_type_list(menum, lang_base_type_)

    lang_base_type_count,
};

enum lang_base_constant
{
    lang_base_constant_list(menum, lang_base_constant_)

    lang_base_constant_count,
};

enum lang_base_function
{
    lang_base_function_list(menum, lang_base_function_)

    lang_base_function_count,
};

string lang_base_type_names[] =
{
    lang_base_number_type_list(menum_name)
    lang_base_alias_type_list(menum_name)
};

string lang_base_constant_names[] =
{
    lang_base_constant_list(menum_name)
};

string lang_base_function_names[] =
{
    lang_base_function_list(menum_name)
};

#define fnode_type_name(node) fs(ast_node_type_names[(node)->node_type])
#define fnode_name(node)      fs(get_name(node))

union ast_node;

struct ast_base_node
{
    ast_node      *next; // needs to be first, to properly work with base lists
    ast_node      *parent;
    u32           index;
    ast_node_type node_type;
    u32           type_index;
};

buffer_type(ast_node_buffer, ast_node_array, ast_node *);

struct simple_type_info
{
    ast_node *node;
    u32      indirection_count;
};

struct lang_complete_type
{
    simple_type_info base_type;
    simple_type_info name_type;
    string           name;
};

enum type_compatibility
{
    type_compatibility_false,
    type_compatibility_requires_cast,
    type_compatibility_number_sign_expand,
    type_compatibility_number_size_expand,
    type_compatibility_equal,
};

struct ast_module;

struct ast_module_reference
{
    ast_base_node node;
    ast_module *module;
};

struct ast_file
{
    ast_base_node node;
    ast_module *module;
    ast_node   *first_statement;
    ast_module_reference *first_module_dependency;
    string path;
    string text;
    u32 index;
};

struct ast_file_reference
{
    ast_base_node node;
    ast_file *file;
};

struct ast_module
{
    ast_base_node node;
    ast_file_reference   *first_file;
    ast_module_reference *first_module_dependency;
    ast_file             *internal_override_file;
    string name;
};

struct ast_scope
{
    ast_base_node node;
    string        label;
    ast_node      *first_statement;

    // this actually for c backend
    bool requires_begin_label;
    bool requires_end_label;
};

struct ast_scope_control
{
    ast_base_node node;
    ast_scope     *scope;
    string        label;
    bool          is_continue; // otherwise is break
};

struct ast_declaration
{
    ast_base_node   node;
    ast_declaration *next_declaration;
};

struct ast_variable
{
    union
    {
        ast_base_node   node;
        ast_declaration declaration;
    };

    lang_complete_type type;
    ast_node *default_expression;
    string name;
    bool is_global, can_expand;
    u32 field_byte_offset;
};

struct ast_enumeration_type;

struct parsed_number
{
    bool is_signed;
    bool is_float;
    bool is_hex;
    bool is_character;
    bool type_is_fixed;

    u8 bit_count_power_of_two;

    union
    {
        u64 u64_value;
        s64 s64_value;
        f64 f64_value;
    };
};

struct ast_enumeration_item
{
    ast_base_node node;
    ast_node *expression;
    string name;

    union
    {
        u64 u64_value;
        s64 s64_value;
    };
};

struct ast_number
{
    ast_base_node node;
    parsed_number value;
};

struct ast_array_type
{
    ast_base_node      node;
    lang_complete_type item_type;
    ast_node           *item_count_expression;  // is constant array
    usize              item_count; // only if count_expression != null
};

struct ast_enumeration_type
{
    ast_base_node node;
    lang_complete_type   item_type;
    u32                  item_count;
    ast_enumeration_item *first_item;
};

struct ast_external_binding
{
    ast_base_node node;
    string library_name;
    bool is_dll;
};

struct ast_intrinsic
{
    ast_base_node node;
    string header;
};

struct ast_constant
{
    union
    {
        ast_base_node   node;
        ast_declaration declaration;
    };

    string   name;
    ast_node *expression;
    bool is_override;
};

struct ast_alias_type
{
    ast_base_node node;
    string name;
    lang_complete_type type;
};

struct ast_expression_reference_type
{
    ast_base_node      node;
    ast_node           *expression;
    lang_complete_type type;
};

typedef ast_base_node ast_empty_type;

struct ast_number_type
{
    ast_base_node node;
    string name;

    bool is_signed, is_float;
    u8 bit_count_power_of_two;
};

struct ast_function_type
{
    ast_base_node node;

    lang_complete_type input;
    lang_complete_type output;

    string calling_convention;
};

struct ast_function
{
    ast_base_node node;
    lang_complete_type type;
    string        name;
    ast_node      *first_statement;
    bool          do_export;
    bool          is_override;
};

struct ast_function_reference
{
    ast_base_node node;
    ast_function *function;
};

struct ast_function_overloads
{
    ast_base_node           node;
    string                  name;
    ast_function_reference *first_function_reference;
};

struct ast_compound_or_union_type
{
    ast_base_node node;
    ast_variable  *first_field;
    u32           field_count;
    u32           byte_count;
    u32           byte_alignment;
};

typedef ast_compound_or_union_type ast_compound_type;
typedef ast_compound_or_union_type ast_union_type;

struct ast_argument
{
    ast_base_node node;
    string   name; // can be empty
    ast_node *expression;
};

struct ast_compound_literal
{
    ast_base_node       node;
    lang_complete_type  type;
    ast_argument        *first_argument;
};

struct ast_array_literal
{
    ast_base_node      node;

    // this could be a union or an array_type
    lang_complete_type type;
    ast_array_type     *array_type;

    // argument, so we can unify compound literals and function calls
    ast_argument       *first_argument;
    usize              item_count;
};

struct ast_name_reference
{
    ast_base_node node;
    string   name;
    ast_node *reference;
};

struct ast_dereference
{
    ast_base_node      node;
    ast_node           *expression;
    lang_complete_type type;
};

struct ast_field_dereference
{
    ast_base_node      node;
    string             name;
    ast_node           *expression;
    ast_node           *reference;
    lang_complete_type type;
};

// pseudo functions

struct ast_get_type_info
{
    ast_base_node      node;
    lang_complete_type type;
};

struct ast_type_byte_count
{
    ast_base_node      node;
    lang_complete_type type;
    parsed_number      byte_count;
};

struct ast_get_function_reference
{
    ast_base_node      node;
    string             name;
    lang_complete_type type;
    ast_function       *function;
};

typedef ast_base_node ast_get_call_location;

struct ast_get_call_argument_text
{
    ast_base_node node;
    ast_name_reference *argument;
};

struct ast_array_index
{
    ast_base_node node;
    ast_node *array_expression;
    ast_node *index_expression;

    struct
    {
        u64 value;
        bool is_constant, was_evaluated;
    } index;
};

struct ast_assignment
{
    ast_base_node node;
    ast_node *left;
    ast_node *right;
};

struct ast_string_literal
{
    ast_base_node node;
    string text;
    bool is_raw; // does not contain escape sequences
};

union ast_branch
{
    ast_base_node node;

    struct
    {
        ast_scope scope;
        ast_node  *condition;

        // so we can have declarations in true and false scope with the same names
        ast_scope *false_scope;
    };
};

union ast_loop
{
    ast_base_node node;

    struct
    {
        ast_scope scope;
        ast_node *condition;
    };
};

union ast_loop_with_counter
{
    ast_base_node node;

    struct
    {
        ast_scope scope;
        ast_node *counter_statement;
        ast_node *end_condition;
    };
};

union ast_branch_switch_case
{
    ast_base_node node;

    struct
    {
        ast_scope scope;
        ast_node *first_expression;
    };
};

union ast_branch_switch
{
    ast_scope scope;

    struct
    {
        // copied from scope
        ast_base_node node;
        string        label;
        ast_branch_switch_case *first_case; // instead of first statement
        bool is_referenced_by_break_or_continue;

        ast_node  *condition;
        ast_scope *default_case_scope;
    };
};

struct ast_function_return
{
    ast_base_node node;
    ast_node *first_expression;
};

struct ast_function_call
{
    ast_base_node node;
    ast_node     *expression;
    ast_argument *first_argument;
};

struct ast_unary_operator
{
    ast_base_node node;
    ast_unary_operator_type operator_type;
    lang_complete_type type;
    ast_function *function; // if its an overload
    ast_node *expression;
};

struct ast_binary_operator
{
    ast_base_node node;
    ast_binary_operator_type operator_type;
    lang_complete_type type;
    ast_function *function; // if its an overload
    ast_node *left;
    //ast_node *right == left->next, less book keeping
};

union ast_node
{
    ast_base_node base;

    // copy from ast_base_node
    struct
    {
        ast_node      *next; // needs to be first, to properly work with base lists
        ast_node      *parent;
        u32           index;
        ast_node_type node_type;
        u32           type_index;
    };

    ast_type_list(menum_field)
    ast_node_list(menum_field)
};

#define menum_ast_type_byte_count(entry, ...) \
    sizeof(ast_ ## entry),

u32 ast_node_type_byte_counts[] = {
    ast_type_list(menum_ast_type_byte_count)
    ast_node_list(menum_ast_type_byte_count)
};

struct source_location
{
    string text;
    u32 file_index;
    u32 line;
    u32 line_count;
    u32 start_column, end_column;
};

buffer_type(source_location_buffer, source_location_array, source_location);

single_list_type(ast_file_list,   ast_file);
single_list_type(ast_module_list, ast_module);

#define bucket_type(name, type, capacity) \
struct name \
{ \
    name  *next; \
    usize count; \
    type  base[capacity]; \
};

#define bucket_array_type(name, type, capacity) \
bucket_type(name, type, capacity); \
struct name ## _array \
{ \
    name  *first; \
    name  **tail_next; \
    usize item_count; \
};

bucket_array_type(base_bucket_type, u8, 1);

#define for_bucket_item(bucket, index, bucket_array) \
for (auto bucket = (bucket_array).first; bucket; bucket = bucket->next) \
    for (u32 index = 0; index < bucket->count; index++)

const u32 ast_bucket_item_count = 1024;

#define menum_bucket_type(entry, ...) \
    bucket_array_type(ast_ ## entry ## _bucket, ast_ ## entry, ast_bucket_item_count);

#define menum_bucket_array_field(entry, ...) \
    ast_ ## entry ## _bucket_array entry ## _buckets;

#define menum_bucket_type_byte_count(entry, ...) \
    sizeof(ast_ ## entry ## _bucket),

ast_node_list(menum_bucket_type);
ast_type_list(menum_bucket_type);

u32 ast_node_bucket_byte_counts[] = {
    ast_type_list(menum_bucket_type_byte_count)
    ast_node_list(menum_bucket_type_byte_count)
};

#define TEMPLATE_HASH_TABLE_NAME     lang_required_node_set
#define TEMPLATE_HASH_TABLE_KEY      ast_node *
#define TEMPLATE_HASH_TABLE_KEY_ZERO null
#include "template_hash_table.h"

u64 hash_of(lang_required_node_set *table, ast_node *key)
{
    return key->index + 1;
}

struct lang_resolve_table_key
{
    string   name;
    ast_node *scope;
};

struct lang_resolve_table_value
{
    ast_node *node;
    bool in_initialization_scope; // in function signature or in loop counter scope
};

bool operator==(lang_resolve_table_key a, lang_resolve_table_key b)
{
    return (a.name == b.name) && (a.scope == b.scope);
}

bool operator!=(lang_resolve_table_key a, lang_resolve_table_key b)
{
    return !(a == b);
}

#define TEMPLATE_HASH_TABLE_NAME  lang_resolve_table
#define TEMPLATE_HASH_TABLE_KEY   lang_resolve_table_key
#define TEMPLATE_HASH_TABLE_VALUE lang_resolve_table_value
#include "template_hash_table.h"

u64 hash_of(lang_resolve_table *table, lang_resolve_table_key key)
{
    u32 value = crc32_begin();
    value = crc32_advance(value, key.name);
    value = crc32_advance(value, { sizeof(key.scope->index), (u8 *) &key.scope->index }); // pointer bytes
    value = crc32_end(value);

    return value;
}

#define TEMPLATE_HASH_TABLE_NAME     lang_unique_type_table
#define TEMPLATE_HASH_TABLE_KEY      ast_node *
#define TEMPLATE_HASH_TABLE_KEY_ZERO null
#define TEMPLATE_HASH_TABLE_VALUE    lang_complete_type
#include "template_hash_table.h"

u64 hash_of(lang_unique_type_table *table, ast_node *key)
{
    return key->index + 1;
}

struct lang_unique_types
{
    ast_array_type_bucket_array    unique_array_type_buckets;
    ast_compound_type_bucket_array unique_compound_type_buckets;
    ast_union_type_bucket_array    unique_union_type_buckets;
    ast_function_type_bucket_array unique_function_type_buckets;

    lang_unique_type_table         table;
};

#define TEMPLATE_HASH_TABLE_NAME     ast_node_to_node_table
#define TEMPLATE_HASH_TABLE_KEY      ast_node *
#define TEMPLATE_HASH_TABLE_KEY_ZERO null
#define TEMPLATE_HASH_TABLE_VALUE    ast_node *
#include "template_hash_table.h"

u64 hash_of(ast_node_to_node_table *table, ast_node *key)
{
    return key->index + 1;
}

struct ast_queue_entry
{
    ast_node *scope;
    ast_node **node_field; // pointer to where the node is stored, so we can also replace it in the parent
};

buffer_type(ast_queue, ast_queue_array, ast_queue_entry);

#define local_buffer(name, type) type name = {}; defer { free_buffer(&name); };

struct lang_parser
{
    // memory

    union
    {
        struct
        {
            ast_type_list(menum_bucket_array_field);
            ast_node_list(menum_bucket_array_field);
        };

        ast_base_node_bucket_array bucket_arrays[ast_node_type_count];
    };

    // one source location per node
    string_buffer          node_comments;
    source_location_buffer node_locations;

    string_builder error_messages;
    string_builder temp_builder;

    lang_resolve_table     resolve_table;   // name x scope -> node
    lang_unique_types      unique_types;    // complete type -> unique complete type
    lang_required_node_set required_nodes;  // node

    // cache table and queue so we can avoid reallocation when calling clone
    ast_node_to_node_table clone_table; // node -> node
    ast_queue              clone_queue;

    // can be reset

    bool debug_unique_types_are_finalized;

    string source_name;
    string source;

    string iterator;
    struct
    {
        string pending_comment;
        string last_location_token;
        u8 *node_location_base;
        ast_node *current_parent;
        string tested_patterns[32];
        u32 tested_pattern_count;
    } parse_state;

    bool error;

    union
    {
        struct
        {
            ast_number_type *base_number_types[lang_base_number_type_count];
            ast_alias_type  *base_alias_types[lang_base_alias_type_count];
        };

        ast_node *base_types[lang_base_type_count];
    };

    ast_constant *base_constants[lang_base_constant_count];
    ast_function *base_functions[lang_base_function_count];

    u32 next_node_index;

    ast_module_list module_list;
    ast_file_list   file_list;
    u32 file_count;

    ast_empty_type     *empty_type_node;
    lang_complete_type empty_type;

    string     lang_internal_source;
    ast_module *lang_module;
    ast_file   *lang_file;
    ast_module *unnamed_module;

    ast_file   *current_file;
};

#define begin_new_node(node_type, ...) \
( (ast_ ## node_type *) begin_node(parser, (ast_node *) new_base_bucket_item((base_bucket_type_array *) &parser->node_type ## _buckets, sizeof(ast_ ## node_type ## _bucket), ast_bucket_item_count, sizeof(ast_ ## node_type)), ast_node_type_ ## node_type, __VA_ARGS__) )

#define new_leaf_node(node_type, first_token) ( (ast_ ## node_type *) end_node(parser, (ast_node *) begin_new_node(node_type, first_token)) )

#define begin_new_local_node(node_type)              ast_ ## node_type *node_type = begin_new_node(node_type)
#define new_local_leaf_node(node_type, first_token)  ast_ ## node_type *node_type = new_leaf_node(node_type, first_token)

// in same scope, declare parents before children
// e.g:
//   new_local_node(a);
//   new_local_node(b);
//   new_local_node(c);
// -> a is parent of b is parent of c
//
//   new_local_node(a);
//   new_local_lead_node(b);
//   new_local_node(c);
// -> a is parent of b, a is parent of c

#define new_local_named_node(name, node_type, ...) ast_ ## node_type *name = begin_new_node(node_type, __VA_ARGS__); defer { end_node(parser, get_base_node(name)); }

#define new_local_node(node_type, ...) new_local_named_node(node_type, node_type, __VA_ARGS__)

#define new_bucket_item(bucket_array) ( (decltype(&(bucket_array)->first->base[0])) new_base_bucket_item((base_bucket_type_array *) bucket_array, sizeof(*(bucket_array)->first), carray_count((bucket_array)->first->base), sizeof((bucket_array)->first->base[0])) )

u8 * new_base_bucket_item(base_bucket_type_array *bucket_array, usize bucket_byte_count, usize item_capacity, usize item_byte_count)
{
    auto bucket_tail_next = bucket_array->tail_next;
    for (; *bucket_tail_next; bucket_tail_next = &(*bucket_tail_next)->next)
    {
        auto bucket = *bucket_tail_next;
        if (bucket->count < item_capacity)
            break;
    }

    if (!*bucket_tail_next)
    {
        auto bucket = (base_bucket_type *) platform_allocate_bytes(bucket_byte_count).base;
        memset(bucket, 0, bucket_byte_count);

        *bucket_tail_next = bucket;
    }

    auto bucket = *bucket_tail_next;
    auto item = (bucket->base + bucket->count * item_byte_count);
    bucket->count++;
    bucket_array->item_count++;
    // no need to clear, since the whole bucket will be cleared on creation

    return item;
}

string advance_node_location(lang_parser *parser, u8 *base)
{
    string text = { (usize) (parser->iterator.base - base), base };

    // remove trailing white space
    while (text.count)
    {
        u8 tail = text.base[text.count - 1];
        if (!contains(s(" \t\n\r"), tail))
            break;

        --text.count;
    }

    parser->parse_state.node_location_base = parser->iterator.base;
    parser->parse_state.tested_pattern_count = 0;

    return text;
}

void advance_node_location(lang_parser *parser)
{
    parser->parse_state.last_location_token = advance_node_location(parser, parser->parse_state.node_location_base);
}

ast_node * begin_node(lang_parser *parser, ast_node *node, ast_node_type node_type, string location_text = {}, bool update_location_on_end = false)
{
    assert(parser->node_locations.count == parser->next_node_index);
    resize_buffer(&parser->node_locations, parser->node_locations.count + 1);

    assert(parser->node_comments.count == parser->next_node_index);
    resize_buffer(&parser->node_comments, parser->node_comments.count + 1);
    auto comment = &parser->node_comments.base[parser->node_comments.count - 1];
    *comment = parser->parse_state.pending_comment;
    parser->parse_state.pending_comment = {};

    node->index  = parser->next_node_index++;
    node->node_type  = node_type;
    node->type_index = parser->bucket_arrays[node_type].item_count - 1;

    node->parent = parser->parse_state.current_parent;
    parser->parse_state.current_parent = node;
    parser->parse_state.tested_pattern_count = 0;

    auto location = &parser->node_locations.base[node->index];
    *location = {};

    if (location_text.base)
    {
        //assert(node_location_index < parser->node_locations.count);
        location->text = location_text;

        if (update_location_on_end)
            location->text.count = 0;
    }
    else
    {
        location->text.base = parser->parse_state.last_location_token.base;
    }

    return node;
}

ast_node * end_node(lang_parser *parser, ast_node *node)
{
    assert(parser->error || node == parser->parse_state.current_parent, "call end_node on parent");

    parser->parse_state.current_parent = parser->parse_state.current_parent->parent;

    auto location = &parser->node_locations.base[node->index];
    if (!location->text.count)
    {
        //assert(location->text.base);
        location->text = advance_node_location(parser, location->text.base);
    }

    return node;
}

string get_node_location(lang_parser *parser, ast_node *node)
{
    assert(node->index < parser->node_locations.count);
    return parser->node_locations.base[node->index].text;
}

#define get_node_type(type, node)   (ast_ ## type *) (node); assert((node)->node_type == ast_node_type_ ## type)
#define local_node_type(type, node) ast_ ## type *type = get_node_type(type, node)

#define is_node_type(node, type) ((node)->node_type == ast_node_type_ ## type)

#define get_base_node(super_node) ((ast_node *) (super_node))

#define consume_white_or_comment_declaration void consume_white_or_comment(lang_parser *parser)
consume_white_or_comment_declaration;

#define types_are_compatible_declaration type_compatibility types_are_compatible(lang_parser *parser, lang_complete_type to, lang_complete_type from)
types_are_compatible_declaration;

#define maybe_add_cast_declaration bool maybe_add_cast(lang_parser *parser, ast_node **expression_pointer, type_compatibility compatibility, lang_complete_type type)
maybe_add_cast_declaration;

string try_consume_name(lang_parser *parser)
{
    string name = skip_name(&parser->iterator);

    if (name.count)
    {
        consume_white_or_comment(parser);
        advance_node_location(parser);
    }
    else
    {
        assert(parser->parse_state.tested_pattern_count < carray_count(parser->parse_state.tested_patterns));
        parser->parse_state.tested_patterns[parser->parse_state.tested_pattern_count++] = s("name");
    }

    return name;
}

bool try_consume(lang_parser *parser, string pattern)
{
    if (try_skip(&parser->iterator, pattern))
    {
        consume_white_or_comment(parser);
        advance_node_location(parser);

        return true;
    }
    else
    {
        assert(parser->parse_state.tested_pattern_count < carray_count(parser->parse_state.tested_patterns));
        parser->parse_state.tested_patterns[parser->parse_state.tested_pattern_count++] = pattern;

        return false;
    }
}

bool try_consume_keyword(lang_parser *parser, string keyword)
{
    auto backup = parser->iterator;

    if (try_skip(&parser->iterator, keyword))
    {
        if (!parser->iterator.count || (!is_letter(parser->iterator.base[0]) && !is_digit(parser->iterator.base[0])))
        {
            consume_white_or_comment(parser);
            advance_node_location(parser);

            return true;
        }
    }

    assert(parser->parse_state.tested_pattern_count < carray_count(parser->parse_state.tested_patterns));
    parser->parse_state.tested_patterns[parser->parse_state.tested_pattern_count++] = keyword;

    parser->iterator = backup;
    return false;
}

struct location_line
{
    ast_file *file;
    string path;
    string text;
    u32    line;
    u32    column;
};

location_line get_location_line(lang_parser *parser, string token)
{
    ast_file *file = null;
    for (auto it = parser->file_list.first; it; it = (ast_file *) it->node.next)
    {
        if ((it->text.base <= token.base) && (token.base + token.count <= it->text.base + it->text.count))
        {
            file = it;
            break;
        }
    }

    string path;
    string left;
    if (file)
    {
        left = file->text;
        path = file->path;
    }
    else
    {
        left = parser->source;
        path = parser->source_name;
        assert((left.base <= token.base) && (token.base + token.count <= left.base + left.count));
    }

    string line = left;

    u32 line_count = 0;
    u32 column_count = 0;

    while (left.base < token.base)
    {
        u8 head = left.base[0];
        advance(&left);

        if (head == '\n')
        {
            line_count++;
            column_count = 0;
            line = left;
        }
        else
        {
            column_count++;
        }
    }

    while (left.count)
    {
        u8 head = left.base[0];
        if ((head == '\n') || (head == '\r'))
            break;

        advance(&left);
    }

    line.count = left.base - line.base;

    return { file, path, line, line_count, column_count };
}

void print_location_prefix(string_builder *builder, location_line location)
{
    print(builder, "%.*s(%i,%i):  ", fs(location.path), location.line + 1, location.column + 1);
}

void print_location_source(string_builder *builder, location_line location)
{
    print_location_prefix(builder, location);
    print_line(builder, "%.*s", fs(location.text));

    print_location_prefix(builder, location);
    print_line(builder, "%*c", location.column + 1, '^');
}

void print_token_source(lang_parser *parser, string_builder *builder, string token)
{
    auto location = get_location_line(parser, token);
    print_location_source(builder, location);
}

void parser_message_va(lang_parser *parser, string token, cstring format, va_list va_arguments)
{
    auto error_messages = &parser->error_messages;

    auto location = get_location_line(parser, token);

    print_newline(error_messages);
    print_location_prefix(error_messages, location);
    print_va(error_messages, format, va_arguments);
    print_newline(error_messages);

    print_location_source(error_messages, location);
}

void parser_message(lang_parser *parser, string token, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);

    parser_message_va(parser, token, format, va_arguments);

    va_end(va_arguments);
}

void parser_error_location_source(lang_parser *parser, location_line location)
{
    print_newline(&parser->error_messages);
    print_location_source(&parser->error_messages, location);
}

void parser_error_location_source(lang_parser *parser, string token)
{
    auto location = get_location_line(parser, token);
    parser_error_location_source(parser, location);
}

string_builder * parser_error_begin(lang_parser *parser, string token, cstring format = null, ...)
{
    parser->error = true;

    auto location = get_location_line(parser, token);

    print_newline(&parser->error_messages);
    print_location_prefix(&parser->error_messages, location);
    print(&parser->error_messages, "ERROR: ");

    if (format)
    {
        va_list va_arguments;
        va_start(va_arguments, format);

        print_va(&parser->error_messages, format, va_arguments);

        va_end(va_arguments);

        parser_error_location_source(parser, location);
    }

    return &parser->error_messages;
}

void parser_error_print(lang_parser *parser, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);

    print_va(&parser->error_messages, format, va_arguments);

    va_end(va_arguments);
}

void parser_error_end(lang_parser *parser)
{
    lang_maybe_break_on_error();
}

#define parser_error_return_value(return_value, parser, token, format, ...) \
do \
{ \
    parser_error_begin(parser, token, format, __VA_ARGS__); \
    parser_error_end(parser); \
    return return_value; \
} \
while (0)

#define parser_error_return(parser, token, format, ...) parser_error_return_value(, parser, token, format, __VA_ARGS__)

// assumes lang_parser *parser in local scope
#define lang_require_return_value(condition, return_value, token, message, ...) \
    if (!(condition)) \
        parser_error_return_value(return_value, parser, token, message, __VA_ARGS__);


void consume_white_or_comment(lang_parser *parser)
{
    u8 *start = null;

    while (true)
    {
        if (try_skip(&parser->iterator, s("//")))
        {
            auto comment = skip_until_or_all(&parser->iterator, s("\n"), true);

            if (!start)
                start = comment.base;

            skip_white(&parser->iterator);
            continue;
        }

        if (skip_white(&parser->iterator))
            continue;

        break;
    }

    if (start)
    {
        if (!parser->parse_state.pending_comment.count)
            parser->parse_state.pending_comment.base = start;

        parser->parse_state.pending_comment.count = parser->iterator.base - parser->parse_state.pending_comment.base;
    }
}

#define lang_require(condition, token, message, ...) lang_require_return_value(condition, null, token, message, __VA_ARGS__)

#define lang_abort_return_value(...) if (parser->error) return __VA_ARGS__
#define lang_abort() lang_abort_return_value(null);

#define lang_require_call_return_value(call, return_value) call; lang_abort_return_value(return_value)
#define lang_require_call(call)                            lang_require_call_return_value(call, null)

#define lang_require_consume_return_value(pattern, return_value, message, ...) lang_require_return_value(try_consume(parser, s(pattern)), return_value, parser->iterator, "expected '" pattern "' " message, __VA_ARGS__)

#define lang_require_consume(pattern, message, ...) lang_require_consume_return_value(pattern, null, message, __VA_ARGS__)

#define parse_expression_declaration ast_node * parse_expression(lang_parser *parser, bool is_inside_constant)
parse_expression_declaration;

#define parse_expression_new_declaration ast_node * parse_expression_new(lang_parser *parser, bool is_inside_constant, u32 min_precedence)
parse_expression_new_declaration;

#define lang_require_expression_return_value(destination, return_value, parser) \
    destination = lang_require_call_return_value(parse_expression(parser, false), return_value); \
    lang_require_return_value(destination, return_value, parser->iterator, "expected expression after '%.*s' in %.*s", fs(parser->parse_state.last_location_token), fnode_type_name(parser->parse_state.current_parent));

#define lang_require_expression(destination, parser) lang_require_expression_return_value(destination, null, parser)

u32 get_bit_count_power_of_two(u64 value)
{
    u32 bit_count = get_highest_bit_index(value);

    if (bit_count)
        bit_count = (bit_count + 7) & ~0x07;
    else
        bit_count = 8;

    return get_highest_bit_index(bit_count) - 1;
}

void skip_multiline_comments(lang_parser *parser)
{
    auto node_location_base = parser->parse_state.node_location_base;
    while (try_consume_keyword(parser, s("multiline_comment")))
    {
        lang_require_consume_return_value("{", , "after multiline_comment");
        auto comment = parser->iterator;

        u32 depth = 1;

        while (parser->iterator.count)
        {
            auto head = parser->iterator.base[0];
            advance(&parser->iterator);

            if (head == '{')
                depth++;
            else if (head == '}')
            {
                depth--;

                if (!depth)
                {
                    comment.count = parser->iterator.base - comment.base - 1;
                    break;
                }
            }
        }

        lang_require_return_value(!depth, , comment, "expected matching closing '}' in multiline comment");

        if (!parser->parse_state.pending_comment.count)
            parser->parse_state.pending_comment = comment;

        parser->parse_state.pending_comment.count = comment.base + comment.count - parser->parse_state.pending_comment.base;

        parser->parse_state.node_location_base = node_location_base;

        consume_white_or_comment(parser);
    }
}

ast_number * new_number_u64(lang_parser *parser, string location_text, u64 value, ast_node *parent = null)
{
    scope_save(parser->parse_state.current_parent);

    new_local_node(number, location_text);
    if (parent)
        number->node.parent = parent;

    number->value.u64_value              = value;
    number->value.bit_count_power_of_two = get_bit_count_power_of_two(value);

    return number;
}

ast_node * new_number_u64_node(lang_parser *parser, string location_text, u64 value, ast_node *parent = null)
{
    return get_base_node(new_number_u64(parser, location_text, value, parent));
}

bool parse_number(parsed_number *result, lang_parser *parser, bool parsed_minus)
{
    bool is_signed = parsed_minus || try_skip(&parser->iterator, s("-"));
    if (!is_signed)
        try_skip(&parser->iterator, s("+")); // ignore + sign

    bool is_hex = try_skip(&parser->iterator, s("0x"));

    u64 base = 10;

    if (is_hex)
        base = 16;

    usize count = 0;
    u64 value = 0;
    while (count < parser->iterator.count)
    {
        u8 head = parser->iterator.base[count];
        u8 digit = head - '0';

        if (digit > 9)
        {
            if (!is_hex)
                break;

            digit = head - 'a';
            if (digit >= 6)
                digit = head - 'A';

            if (digit >= 6)
                break;

            digit += 10;
        }

        auto previous = value;
        value *= base;
        value += digit;
        lang_require(previous <= value, parser->iterator, "number to big for 64bit representation");

        count++;
    }

    bool is_float = false;
    f64 f64_value;
    if (parser->iterator.base[count] == '.')
    {
        count++;
        is_float = true;

        f64 fraction = 0;
        f64 factor = base;

        while (count < parser->iterator.count)
        {
            u8 head = parser->iterator.base[count];
            u8 digit = head - '0';

            if (digit > 9)
            {
                if (!is_hex)
                    break;

                u8 digit = head - 'a';
                if (digit >= 6)
                    digit = head - 'A';

                if (digit >= 6)
                    break;

                digit += 10;
            }

            fraction += (f64) digit / factor;
            factor *= base;
            count++;
        }

        f64_value = (f64) value + fraction;

        if (is_signed)
            f64_value = -f64_value;
    }

    parsed_number parsed_value = {};

    if (count)
    {
        string token = skip(&parser->iterator, count);
        advance_node_location(parser);

        parsed_value.is_float  = is_float;
        parsed_value.is_signed = is_signed | is_float;

        u32 bit_count;

        if (is_float)
        {
            parsed_value.f64_value = f64_value;

            // TODO: make clear when we use f64

            //f32 f32_value = (f32) f64_value;
            //if ((f64) f32_value == f64_value)
            bit_count = 32;
            //else
                //bit_count = 64;
        }
        else if (is_signed)
        {
            parsed_value.s64_value = -(s64) value;
            bit_count = get_highest_bit_index(value);
        }
        else
        {
            parsed_value.u64_value = value;
            bit_count = get_highest_bit_index(value);
        }

        if (bit_count)
            bit_count = (bit_count + 7) & ~0x07;
        else
            bit_count = 8;

        assert(!is_hex || !is_float);
        parsed_value.is_hex = is_hex;
        parsed_value.bit_count_power_of_two = get_highest_bit_index(bit_count) - 1;

        *result = parsed_value;
        return true;
    }
    else
    {
        lang_require(!is_hex, parser->iterator, "expected hexadecimal value after '0x'");
        return false;
    }
}

ast_number * parse_number(lang_parser *parser, bool parsed_minus)
{
    parsed_number value;
    auto ok = lang_require_call(parse_number(&value, parser, parsed_minus));
    if (ok)
    {
        new_local_node(number);
        number->value = value;
        return number;
    }

    return null;
}

bool parse_quoted_string(string *out_text, lang_parser *parser)
{
    if (!parser->iterator.count || (parser->iterator.base[0] != '"'))
        return false;

    string text;
    text.base = parser->iterator.base + 1;

    usize count = 1;
    bool ok = false;
    while (count < parser->iterator.count)
    {
        u8 head = parser->iterator.base[count];

        // skip next character
        if (head == '\\')
        {
            lang_require(count + 1 < parser->iterator.count, parser->iterator, "unexpected end of source after '\\' in string literal");
            count++;
        }
        else if (head == '"')
        {
            ok = true;
            break;
        }

        count++;
    }

    lang_require_return_value(ok, false, parser->iterator, "expected '\"' after string literal");

    text.count = count - 1;
    advance(&parser->iterator, count + 1);
    consume_white_or_comment(parser);
    advance_node_location(parser);

    *out_text = text;

    return true;
}

ast_node * parse_string_or_character_literal(lang_parser *parser)
{
    string text;
    bool ok = lang_require_call(parse_quoted_string(&text, parser));

    if (ok)
    {
        if (try_consume(parser, s("[")))
        {
            parsed_number value;
            bool ok = lang_require_call(parse_number(&value, parser, false));
            lang_require(ok && !value.is_signed, parser->iterator, "expected unsigned integer after '[' in character literal");

            u32 index = 0;
            u32 character = -1;
            for (u32 i = 0; i < text.count; i++)
            {
                character = text.base[i];
                if (character == '\\')
                {
                    i++;
                    switch (text.base[i])
                    {
                        default:
                        {
                            lang_require(false, parser->iterator, "unrecognized character excape sequence");
                        } break;

                        case '0':
                        {
                            character = '\0';
                        } break;

                        case '\\':
                        {
                            character = '\\';
                        } break;

                        case 'n':
                        {
                            character = '\n';
                        } break;

                        case 'r':
                        {
                            character = '\r';
                        } break;

                        case 't':
                        {
                            character = '\t';
                        } break;
                    }
                }

                if (index == value.u64_value)
                    break;

                index++;
            }

            lang_require(index == value.u64_value, parser->iterator, "index %llu in character literal is out of rage, should be at most %i", value.u64_value, index);

            new_local_node(number);
            number->value.u64_value = character;
            number->value.bit_count_power_of_two = get_bit_count_power_of_two(number->value.u64_value);
            number->value.is_character = true;
            number->value.type_is_fixed = true;

            lang_require_consume("]", "in character literal");

            return get_base_node(number);
        }
        else
        {
            new_local_node(string_literal);
            string_literal->text = text;

            return get_base_node(string_literal);
        }
    }
    else
    {
        return null;
    }
}

#define get_expression_type_declaration lang_complete_type get_expression_type(lang_parser *parser, ast_node *node)
get_expression_type_declaration;

bool type_is_not_empty(lang_complete_type type)
{
    return !type.base_type.node || !is_node_type(type.base_type.node, empty_type);

    //assert(type.base_type.node);
    //return !is_node_type(type.base_type.node, empty_type);
}

lang_complete_type get_function_return_type(ast_function_type *function_type)
{
    if (type_is_not_empty(function_type->output))
    {
        local_node_type(compound_type, function_type->output.base_type.node);
        if (!compound_type->first_field->node.next)
            return compound_type->first_field->type;
    }

    return function_type->output;
}

void resolve_complete_type(lang_parser *parser, lang_complete_type *type)
{
    if (type->base_type.node || !type->name_type.node)
        return;

    auto name_type = type->name_type.node;
    switch (name_type->node_type)
    {
        cases_complete_message("%.*s", fs(ast_node_type_names[name_type->node_type]));

        case ast_node_type_empty_type:
        case ast_node_type_function_type:
        case ast_node_type_compound_type:
        case ast_node_type_union_type:
        case ast_node_type_enumeration_type:
        case ast_node_type_number_type:
        case ast_node_type_array_type:
        {
            type->base_type = type->name_type;
        } break;

        case ast_node_type_expression_reference_type:
        {
            local_node_type(expression_reference_type, name_type);

            if (!expression_reference_type->type.base_type.node)
            {
                auto type = get_expression_type(parser, expression_reference_type->expression);
                resolve_complete_type(parser, &type);

                expression_reference_type->type = type;
            }

            type->base_type = expression_reference_type->type.base_type;
            type->base_type.indirection_count += type->name_type.indirection_count;
        } break;

        case ast_node_type_alias_type:
        {
            local_node_type(alias_type, name_type);

            resolve_complete_type(parser, &alias_type->type);
            if (!alias_type->type.base_type.node)
                break;

            assert(alias_type->type.base_type.node->node_type != ast_node_type_alias_type);

            type->base_type = alias_type->type.base_type;
            type->base_type.indirection_count += type->name_type.indirection_count;
            type->name = alias_type->name;
        } break;
    }
}

// assumes start pattern was allready parsed
#define parse_arguments_declaration ast_compound_type * parse_arguments(lang_parser *parser, string argument_delimiter, string end_pattern, bool is_union)
parse_arguments_declaration;

lang_complete_type parse_type(lang_parser *parser, bool is_required)
{
    auto name = try_consume_name(parser);

    if (!name.count)
        return {};

    lang_complete_type result = {};

    if (name == s("type_of"))
    {
        new_local_node(expression_reference_type);

        lang_require_consume_return_value("(", {}, "after 'type_of'");

        lang_require_expression_return_value(expression_reference_type->expression, {}, parser);

        lang_require_consume_return_value(")", {}, "after type_of expression");

        result.name_type.node = get_base_node(expression_reference_type);
    }
    else if (name == s("struct"))
    {
        lang_require_consume_return_value("{", {}, "after 'struct'");
        auto compound_type = lang_require_call_return_value(parse_arguments(parser, s(";"), s("}"), false), {});

        result.base_type.node = get_base_node(compound_type);
        result.name_type = result.base_type;
    }
    else if (name == s("union"))
    {
        lang_require_consume_return_value("{", {}, "after 'union'");
        auto union_type = lang_require_call_return_value(parse_arguments(parser, s(";"), s("}"), true), {});

        result.base_type.node = get_base_node(union_type);
        result.name_type = result.base_type;
    }
    else
    {
        result.name = name;

        for (u32 i = 0; i < lang_base_type_count; i++)
        {
            if (name == lang_base_type_names[i])
            {
                result.name_type.node = parser->base_types[i];
                resolve_complete_type(parser, &result);
                break;
            }
        }
    }

    while (true)
    {
        if (try_consume_keyword(parser, s("ref")))
        {
            result.name_type.indirection_count++;

            if (result.base_type.node)
                result.base_type.indirection_count++;
        }
        else if (try_consume(parser, s("[")))
        {
            new_local_node(array_type);

            auto expression = lang_require_call_return_value(parse_expression(parser, true), {});
            lang_require_return_value(try_consume(parser, s("]")), {}, parser->iterator, "expected ']' after array count expression");

            resolve_complete_type(parser, &result);

            array_type->item_count_expression = expression;
            array_type->item_type = result;

            result = {};
            result.name_type.node = get_base_node(array_type);
            result.base_type      = result.name_type;
        }
        else
        {
            break;
        }
    }

    resolve_complete_type(parser, &result);

    lang_require_return_value(!is_required || result.name_type.node || result.name.count, {}, parser->iterator, "expected type");

    return result;
}

ast_compound_literal * parse_compound_literal(lang_parser *parser)
{
    if (!try_consume(parser, s("{")))
        return null;

    new_local_node(compound_literal);

    auto tail_next = make_tail_next(&compound_literal->first_argument);

    bool is_first = true;
    bool consumed_delimiter = false;
    while (!try_consume(parser, s("}")))
    {
        if (!is_first)
        {
            lang_require(consumed_delimiter, parser->iterator, " expects ';' before every new field of compound literal");
        }
        is_first = false;

        new_local_node(argument);

        auto backup = parser->iterator;
        auto name = try_consume_name(parser);

        if (name.count && !try_consume(parser, s("=")))
        {
            name = {};
            parser->iterator = backup;
        }
        else if (name.count)
        {
            lang_require(false, parser->iterator, " named compound literal expressions are currently not supported");
        }

        argument->name = name;
        lang_require_expression(argument->expression, parser);
        consumed_delimiter = try_consume(parser, s(","));

        append_tail_next(&tail_next, &argument->node);
    }

    auto type = lang_require_call(parse_type(parser, true));

    lang_require((type.base_type.node || type.name.count) && !type.name_type.indirection_count, parser->iterator, " expected type for compound literal");

    compound_literal->type = type;

    return compound_literal;
}

// add count_expression to type
ast_array_literal * parse_array_literal(lang_parser *parser)
{
    if (!try_consume(parser, s("[")))
        return null;

    new_local_node(array_literal);

    auto tail_next = make_tail_next(&array_literal->first_argument);

    bool is_first = true;
    bool consumed_delimiter = false;
    while (!try_consume(parser, s("]")))
    {
        if (!is_first)
        {
            lang_require(consumed_delimiter, parser->iterator, " before every new field of array literal");
        }

        is_first = false;

        new_local_node(argument);

        lang_require_expression(argument->expression, parser);

        array_literal->item_count++;

        append_tail_next(&tail_next, argument);

        consumed_delimiter = try_consume(parser, s(","));
    }

    auto type = lang_require_call(parse_type(parser, true));

    lang_require(type.base_type.node || type.name.count, parser->iterator, " expected type for array literal");

    if (type.name_type.node && is_node_type(type.name_type.node, array_type))
    {
        local_node_type(array_type, type.name_type.node);
        if (!array_type->item_count_expression)
        {
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, type.name_type.node), array_literal->item_count, type.name_type.node));
        }
    }

    array_literal->type = type;

    return array_literal;
}

lang_complete_type parse_function_type(lang_parser *parser)
{
    lang_complete_type type = {};

    if (try_consume(parser, s("(")))
    {
        new_local_node(function_type);

        function_type->input.name_type.node = (ast_node *) lang_require_call_return_value(parse_arguments(parser, s(","), s(")"), false), {});
        function_type->input.base_type = function_type->input.name_type;

        if (!function_type->input.name_type.node)
            function_type->input = parser->empty_type;

        if (try_consume(parser, s("(")))
        {
            function_type->output.name_type.node = (ast_node *) lang_require_call_return_value(parse_arguments(parser, s(","), s(")"), false), {});
            function_type->output.base_type = function_type->output.name_type;
        }

        if (!function_type->output.name_type.node)
            function_type->output = parser->empty_type;

        if (try_consume_keyword(parser, s("calling_convention")))
        {
            bool ok = lang_require_call_return_value(parse_quoted_string(&function_type->calling_convention, parser), {});
            lang_require_return_value(ok && function_type->calling_convention.count, {}, parser->iterator, "expected calling convention in quoates (\"...\") after 'calling_convention'");
        }

        type.name_type.node = get_base_node(function_type);
        type.base_type      = type.name_type;
    }
    else
    {
        auto function_type_name = try_consume_name(parser);
        lang_require_return_value(function_type_name.count, {}, parser->iterator, "expected explicit function type starting with '(' or function type name after function name");

        type.name = function_type_name;
    }

    return type;
}

ast_node * parse_base_expression(lang_parser *parser, bool is_inside_constant)
{
    ast_node *root = null;
    ast_node *parent = parser->parse_state.current_parent;
    ast_node **parent_expression = &root;

    ast_node *expression = null;

    bool pending_minus = false;

    while (true)
    {
        {
            auto backup = *parser;
            auto keyword = try_consume_name(parser);

            u32 type = -1;
            if (keyword.count)
            {
                for (u32 i = 0; i <= ast_unary_operator_type_bit_not; i++)
                {
                    if (keyword == ast_unary_operator_names[i])
                    {
                        type = i;
                        break;
                    }
                }
            }

            if (type != -1)
            {
                if (pending_minus)
                {
                    new_local_node(unary_operator);
                    unary_operator->operator_type = ast_unary_operator_type_negate;

                    parent = get_base_node(unary_operator);
                    *parent_expression = parent;
                    parent_expression = &unary_operator->expression;
                    pending_minus = false;
                }

                new_local_node(unary_operator);
                unary_operator->operator_type = (ast_unary_operator_type) type;

                parent = get_base_node(unary_operator);
                *parent_expression = parent;
                parent_expression = &unary_operator->expression;
            }
            else
            {
                *parser = backup;
            }
        }

        if (try_consume(parser, s("-")))
        {
            pending_minus = !pending_minus;
            continue;
        }

        break;
    }

    if (try_consume(parser, s("(")))
    {
        if (pending_minus)
        {
            new_local_node(unary_operator);
            unary_operator->operator_type = ast_unary_operator_type_negate;

            parent = get_base_node(unary_operator);
            *parent_expression = parent;
            parent_expression = &unary_operator->expression;
            pending_minus = false;
        }

        lang_require_expression(expression, parser);
        lang_require_consume(")", "after sub expression starting with '('");
    }

    if (!expression)
    {
        expression = lang_require_call(get_base_node(parse_number(parser, pending_minus)));
        if (expression)
            pending_minus = false;
    }

    if (pending_minus)
    {
        new_local_node(unary_operator);
        unary_operator->operator_type = ast_unary_operator_type_negate;

        parent = get_base_node(unary_operator);
        *parent_expression = parent;
        parent_expression = &unary_operator->expression;
        pending_minus = false;
    }

    if (!expression)
        expression = lang_require_call(parse_string_or_character_literal(parser));

    if (!expression)
        expression = lang_require_call(get_base_node(parse_array_literal(parser)));

    if (!expression)
        expression = lang_require_call(get_base_node(parse_compound_literal(parser)));

    if (!expression)
    {
        auto backup = *parser;
        auto keyword = try_consume_name(parser);
        if (keyword.count)
        {
            for (u32 i = 0; i < lang_base_constant_count; i++)
            {
                if (lang_base_constant_names[i] == keyword)
                {
                    new_local_node(name_reference);
                    name_reference->name = keyword;
                    name_reference->reference = get_base_node(parser->base_constants[i]);
                    expression = get_base_node(name_reference);
                    break;
                }
            }
        }

        if (!expression)
            *parser = backup;
    }

    if (!expression)
    {
        auto name = try_consume_name(parser);
        if (name.count)
        {
            // check some pseudo function calls
            if (name == s("get_call_location"))
            {
                new_local_leaf_node(get_call_location, name);

                lang_require_consume("(", "after 'get_call_location'");
                lang_require_consume(")", "after 'get_call_location('");

                 expression = get_base_node(get_call_location);
            }
            else if (name == s("get_call_argument_text"))
            {
                new_local_node(get_call_argument_text);

                lang_require_consume("(", "after 'get_call_argument_text'");

                auto argument_name = try_consume_name(parser);
                lang_require(argument_name.count, parser->iterator, "expected function argument name as single argument to get_call_argument_text");

                lang_require_consume(")", "after 'get_call_argument_text('");

                new_local_leaf_node(name_reference, argument_name);
                name_reference->name = argument_name;
                get_call_argument_text->argument = name_reference;

                expression = get_base_node(get_call_argument_text);
            }
            else if (name == s("get_type_info"))
            {
                new_local_node(get_type_info);

                lang_require_consume_return_value("(", {}, "after 'get_type_info'");

                get_type_info->type = lang_require_call(parse_type(parser, true));

                lang_require_consume_return_value(")", {}, "after get_type_info type");
                expression = get_base_node(get_type_info);
            }
            else if (name == s("type_byte_count"))
            {
                new_local_node(type_byte_count);

                lang_require_consume_return_value("(", {}, "after 'type_byte_count'");

                type_byte_count->type = lang_require_call(parse_type(parser, true));

                lang_require_consume_return_value(")", {}, "after type_byte_count type");
                expression = get_base_node(type_byte_count);
            }
            else if (name == s("get_function_reference"))
            {
                new_local_node(get_function_reference);

                lang_require_consume_return_value("(", {}, "after 'get_function_reference'");

                get_function_reference->name = try_consume_name(parser);
                lang_require_return_value(get_function_reference->name.count, {}, parser->iterator, "exected function name after 'get_function_reference'");

                get_function_reference->type = parse_function_type(parser);

                lang_require_consume_return_value(")", {}, "after get_function_reference expression");

                expression = get_base_node(get_function_reference);
            }
            else if (name == s("import_text_file"))
            {
                lang_require_consume_return_value("(", {}, "after 'import_text_file'");

                new_local_node(string_literal);
                string_literal->is_raw = true;

                string file_path;
                lang_require_return_value(parse_quoted_string(&file_path, parser), {}, parser->iterator, "expected file path string as only argument of import_text_file");

                auto backup = parser->temp_builder.memory.count;
                auto working_directory = parser->current_file->path;

                {
                    u32 count = 0;
                    for (u32 i = 0; i < working_directory.count; i++)
                    {
                        assert(working_directory.base[i] != '\\');

                        if (working_directory.base[i] == '/')
                            count = i;
                    }
                    working_directory.count = count;
                }

                auto complete_path = get_absolute_path(&parser->temp_builder, working_directory, file_path);
                print(&parser->error_messages, "\0");

                lang_require_return_value(platform_allocate_and_read_entire_file(&string_literal->text, (cstring) complete_path.base), {}, file_path, "couldn't load file '%.*s'", fs(complete_path));

                parser->temp_builder.memory.count = backup;

                lang_require_consume_return_value(")", {}, "after import_text_file file name");

                expression = get_base_node(string_literal);
            }
            else
            {
                new_local_leaf_node(name_reference, name);
                name_reference->name = name;
                expression = get_base_node(name_reference);

                // TODO: unify with compound literals
                // function call
                if (try_consume(parser, s("(")))
                {
                    lang_require_return_value(!is_inside_constant, null, parser->iterator, "function calls are not allowed inside compile time constants");

                    new_local_node(function_call, parser->node_locations.base[expression->index].text);

                    auto argument_tail_next = make_tail_next(&function_call->first_argument);

                    bool is_first = true;
                    while (!try_consume(parser, s(")")))
                    {
                        lang_require(is_first || try_consume(parser, s(",")), parser->iterator, "expected expression after ','");

                        new_local_node(argument);

                        // TODO: parse name = befor expression?

                        lang_require_expression(argument->expression, parser);

                        append_tail_next(&argument_tail_next, argument);

                        is_first = false;
                    }

                    function_call->expression = expression;

                    function_call->node.parent = expression->parent;
                    expression->parent = get_base_node(function_call);

                    expression = get_base_node(function_call);
                }
            }
        }
    }

    while (expression)
    {
        consume_white_or_comment(parser);

        if (try_consume(parser, s(".")))
        {
            auto field_name = try_consume_name(parser);
            lang_require(field_name.count, parser->iterator, "expected field name after '.'");
            new_local_node(field_dereference, parser->node_locations.base[expression->index].text, false);
            field_dereference->expression = expression;
            field_dereference->name = field_name;

            field_dereference->node.parent = expression->parent;
            expression->parent = get_base_node(field_dereference);
            expression = get_base_node(field_dereference);
            continue;
        }
        else if (try_consume(parser, s("[")))
        {
            new_local_node(array_index, parser->node_locations.base[expression->index].text, true);
            array_index->array_expression = expression;

            lang_require_expression(array_index->index_expression, parser);

            lang_require(try_consume(parser, s("]")), parser->iterator, "expected ']' after array index expression");

            array_index->node.parent = expression->parent;
            expression->parent = get_base_node(array_index);
            expression = get_base_node(array_index);

            continue;
        }
        else
        {
            auto backup = *parser;

            auto keyword = try_consume_name(parser);
            if (keyword == s("cast"))
            {
                lang_require(try_consume(parser, s("(")), parser->iterator, "expected '(' after 'cast'");
                auto type = lang_require_call(parse_type(parser, true));
                lang_require(try_consume(parser, s(")")), parser->iterator, "expected ')' at the end of cast");

                // TODO: move this to resolve, so can always remove casts to number types
                if (is_node_type(expression, number) && type.base_type.node && !type.base_type.indirection_count && is_node_type(type.base_type.node, number_type))
                {
                    auto compatibility = types_are_compatible(parser, type, get_expression_type(parser, expression));
                    if (compatibility != type_compatibility_false)
                    {
                        // force convertion to number_type
                        maybe_add_cast(parser, &expression, type_compatibility_requires_cast, type);
                        continue;
                    }
                }

                new_local_node(unary_operator, parser->node_locations.base[expression->index].text, true);
                unary_operator->operator_type = ast_unary_operator_type_cast;
                unary_operator->type = type;
                unary_operator->expression = expression;

                unary_operator->node.parent = expression->parent;
                expression->parent = get_base_node(unary_operator);

                expression = get_base_node(unary_operator);
                continue;
            }
            else if (keyword == s("ref"))
            {
                new_local_node(unary_operator, parser->node_locations.base[expression->index].text, true);
                unary_operator->operator_type = ast_unary_operator_type_take_reference;
                unary_operator->expression = expression;

                unary_operator->node.parent = expression->parent;
                expression->parent = get_base_node(unary_operator);

                expression = get_base_node(unary_operator);
                continue;
            }
            else if (keyword == s("deref"))
            {
                new_local_node(dereference, parser->node_locations.base[expression->index].text, true);
                dereference->expression = expression;

                dereference->node.parent = expression->parent;
                expression->parent = get_base_node(dereference);
                expression = get_base_node(dereference);
                continue;
            }
            else
            {
                *parser = backup;
            }
        }

        break;
    }

    if (expression)
    {
        expression->parent = parent;
        *parent_expression = expression;
        parser->parse_state.current_parent = root->parent;
    }
    else
    {
        lang_require(!root, parser->iterator, "incomplete expression. expected operand after %.*s", fnode_type_name(root));
    }

    return root;
}

bool parse_binary_operator(ast_binary_operator_type *out_operator_type, lang_parser *parser)
{
    ast_binary_operator_type operator_type = ast_binary_operator_type_count;
    string operator_token = {};

    auto backup = parser->iterator;

    auto keyword = try_consume_name(parser);
    if (keyword.count)
    {
        // same order as ast_binary_operator_list
        string short_names[] = {
            s("or"),
            s("and"),
            s("xor"),

            s("is"),
            s("is_not"),
            s("is_less"),
            s("is_less_equal"),
            s("is_greater"),
            s("is_greater_equal"),

            s("bit_or"),
            s("bit_and"),
            s("bit_xor"),
            s("bit_shift_left"),
            s("bit_shift_right"),

            s("add"),
            s("sub"),
            s("mul"),
            s("div"),
            s("mod"),
        };

        for (u32 i = 0; i < ast_binary_operator_type_count; i++)
        {
            if ((keyword == short_names[i]) || (keyword == ast_binary_operator_names[i]))
            {
                operator_type  = (ast_binary_operator_type) i;
                operator_token = ast_binary_operator_names[i];
                break;
            }
        }

        if (operator_type == ast_binary_operator_type_count)
            parser->iterator = backup;
    }
    else
    {
        struct
        {
            string token;
            ast_binary_operator_type operator_type;
        }
        symbol_operators[] =
        {
            // first match wins, so order is important
            { s("<="), ast_binary_operator_type_is_less_equal },
            { s("<"), ast_binary_operator_type_is_less },
            { s(">="), ast_binary_operator_type_is_greater_equal },
            { s(">"), ast_binary_operator_type_is_greater },

            { s("+"), ast_binary_operator_type_add },
            { s("-"), ast_binary_operator_type_subtract },
            { s("*"), ast_binary_operator_type_multiply },
            { s("/"), ast_binary_operator_type_divide },
        };

        for (u32 i = 0; i < carray_count(symbol_operators); i++)
        {
            if (try_consume(parser, symbol_operators[i].token))
            {
                operator_type  = symbol_operators[i].operator_type;
                operator_token = symbol_operators[i].token;
                break;
            }
        }
    }

    *out_operator_type = operator_type;
    return (operator_type != ast_binary_operator_type_count);
}

ast_node * parse_expression_increasing_precedence(lang_parser *parser, bool is_inside_constant, ast_node *left, u32 min_precedence)
{
    auto backup = parser->iterator;
    ast_binary_operator_type binary_operator_type;

    if (!parse_binary_operator(&binary_operator_type, parser) || (ast_binary_operator_precedence[binary_operator_type] <= min_precedence) || try_consume(parser, s("=")))
    {
        parser->iterator = backup;
        return left;
    }

    new_local_node(binary_operator, parser->node_locations.base[left->index].text, true);
    binary_operator->operator_type = binary_operator_type;
    binary_operator->left = left;
    assert(!left->next);

    auto right = lang_require_call(parse_expression_new(parser, is_inside_constant, ast_binary_operator_precedence[binary_operator_type]));
    lang_require(right, parser->iterator, "expected espression after binary operator '%.*s'", fs(ast_binary_operator_names[binary_operator->operator_type]));
    assert(!right->next)
    binary_operator->left->next = right;
    left->parent  = get_base_node(binary_operator);
    right->parent = get_base_node(binary_operator);

    return get_base_node(binary_operator);
}

parse_expression_new_declaration
{
    auto left = lang_require_call(parse_base_expression(parser, is_inside_constant));

    if (!left)
        return null;

    while (true)
    {
        auto root = parse_expression_increasing_precedence(parser, is_inside_constant, left, min_precedence);
        if (root == left)
            return left;

        left = root;
    }

    unreachable_codepath;
    return null;
}

ast_node * parse_expression_old(lang_parser *parser, bool is_inside_constant)
{
    auto left = lang_require_call(parse_base_expression(parser, is_inside_constant));

    if (!left)
        return null;

    while (true)
    {
        ast_binary_operator_type operator_type;
        auto backup = parser->iterator;
        if (parse_binary_operator(&operator_type, parser))
        {
            if (try_consume(parser, s("=")))
            {
                parser->iterator = backup;
                return left;
            }

            new_local_node(binary_operator, parser->node_locations.base[left->index].text, true);
            binary_operator->operator_type = operator_type;
            binary_operator->left = left;
            assert(!left->next);

            // we don't have precendence now, we just build from left to right
            // a + b + c => (a + b) + c
            auto right = lang_require_call(parse_base_expression(parser, is_inside_constant));
            lang_require(right, parser->iterator, "expected espression after binary operator '%.*s'", fs(ast_binary_operator_names[binary_operator->operator_type]));

            assert(!right->next)
            binary_operator->left->next = right;

            left->parent = get_base_node(binary_operator);

            left = get_base_node(binary_operator);
            continue;
        }

        // nothing matched
        break;
    }

    return left;
}

bool expressions_are_equal(lang_parser *parser, ast_node *left, ast_node *right)
{
    if (!left || !right)
        return !left == !right;

    if (left->node_type != right->node_type)
        return false;

    switch (left->node_type)
    {
        cases_complete("%.*s", fs(ast_node_type_names[left->node_type]));

        case ast_node_type_name_reference:
            return left->name_reference.name == right->name_reference.name;

        case ast_node_type_number:
        {
            return values_are_equal(left->number.value, right->number.value);
        } break;

        case ast_node_type_string_literal:
            return left->string_literal.text == right->string_literal.text;

        case ast_node_type_compound_literal:
        {
            auto left_item  = left->compound_literal.first_argument;
            auto right_item = right->compound_literal.first_argument;
            for (; right_item && left_item; left_item = (ast_argument *) left_item->node.next)
            {
                if (!expressions_are_equal(parser, left_item->expression, right_item->expression))
                    return false;

                right_item = (ast_argument *) right_item->node.next;
            }

            if (!right_item != !left_item)
                return false;

            return true;
        } break;

        case ast_node_type_array_literal:
        {
            auto left_item  = left->array_literal.first_argument;
            auto right_item = right->array_literal.first_argument;
            for (; right_item && left_item; left_item = (ast_argument *) left_item->node.next)
            {
                if (!expressions_are_equal(parser, left_item->expression, right_item->expression))
                    return false;

                right_item = (ast_argument *) right_item->node.next;
            }

            if (!right_item != !left_item)
                return false;

            return true;
        } break;

        case ast_node_type_function_call:
        {
            if (!expressions_are_equal(parser, left->function_call.expression, right->function_call.expression))
                return false;

            auto left_item  = left->function_call.first_argument;
            auto right_item = right->function_call.first_argument;
            for (; right_item && left_item; left_item = (ast_argument *) left_item->node.next)
            {
                if (!expressions_are_equal(parser, left_item->expression, right_item->expression))
                    return false;

                right_item = (ast_argument *) right_item->node.next;
            }

            if (!right_item != !left_item)
                return false;

            return true;
        } break;

        case ast_node_type_array_index:
        {
            return expressions_are_equal(parser, left->array_index.array_expression, right->array_index.array_expression) && expressions_are_equal(parser, left->array_index.index_expression, right->array_index.index_expression);
        } break;

        case ast_node_type_dereference:
        {
            return expressions_are_equal(parser, left->dereference.expression, right->dereference.expression);
        } break;

        case ast_node_type_field_dereference:
        {
            return (left->field_dereference.name == right->field_dereference.name) && expressions_are_equal(parser, left->field_dereference.expression, right->field_dereference.expression);
        } break;

        case ast_node_type_type_byte_count:
        case ast_node_type_get_type_info:
        case ast_node_type_get_function_reference:
        case ast_node_type_get_call_location:
        case ast_node_type_get_call_argument_text:
        {
            return parser->node_locations.base[left->index].text == parser->node_locations.base[right->index].text;
        } break;

        case ast_node_type_unary_operator:
        {
            return (left->unary_operator.operator_type == right->unary_operator.operator_type) && expressions_are_equal(parser, left->unary_operator.expression, right->unary_operator.expression);
        } break;

        case ast_node_type_binary_operator        :
        {
            if (left->binary_operator.operator_type != right->binary_operator.operator_type)
                return false;

            return (expressions_are_equal(parser, left->binary_operator.left, right->binary_operator.left) && expressions_are_equal(parser, left->binary_operator.left->next, right->binary_operator.left->next)) || (expressions_are_equal(parser, left->binary_operator.left->next, right->binary_operator.left) && expressions_are_equal(parser, left->binary_operator.left, right->binary_operator.left->next));
        } break;
    }

    unreachable_codepath;
    return false;
}

// #define LANG_CHECK_PRECEDENCE_PARSING

parse_expression_declaration
{
#ifdef LANG_CHECK_PRECEDENCE_PARSING

    // HACK: to mark code that is resolved
    auto tested_pattern_count = parser->parse_state.tested_pattern_count;
    auto was_fixed = try_consume(parser, s("$fixed"));
    if (!was_fixed)
        parser->parse_state.tested_pattern_count = tested_pattern_count;

    auto backup = parser->iterator;
    auto parse_state = parser->parse_state;
    auto debug_next_node_index = parser->next_node_index;
    ast_node *old_expression = parse_expression_old(parser, is_inside_constant);
    auto old_itertor = parser->iterator;

    parser->iterator = backup;
    parser->parse_state = parse_state;

    ast_node *new_expression = parse_expression_new(parser, is_inside_constant, 0);

    assert(old_itertor.base == parser->iterator.base);

    if (!was_fixed && !expressions_are_equal(parser, old_expression, new_expression))
    //if (!expressions_are_equal(parser, old_expression, new_expression))
    {
        parser_error_return_value(null, parser, backup, "expression precedence changed with new expression parser");
    }

#else

    ast_node *new_expression = parse_expression_new(parser, is_inside_constant, 0);

#endif

    return new_expression;
}

// parses '=' right
ast_assignment * parse_assignment_begin(lang_parser *parser)
{
    if (!try_consume(parser, s("=")))
        return null;

    begin_new_local_node(assignment);
    lang_require_expression(assignment->right, parser);

    return assignment;
}

void parse_assignment_end(lang_parser *parser, ast_assignment *assignment, ast_node *left)
{
    assignment->left = left;
    left->parent     = get_base_node(assignment);

    end_node(parser, get_base_node(assignment));

    auto assignment_text = &parser->node_locations.base[assignment->node.index].text;
    auto left_text       = parser->node_locations.base[left->index].text;

    assignment_text->count += (assignment_text->base - left_text.base);
    assignment_text->base  = left_text.base;
}

lang_complete_type get_type(lang_parser *parser, lang_base_type type)
{
    lang_complete_type result = {};

    result.name_type.node = parser->base_types[type];

    switch (result.name_type.node->node_type)
    {
        cases_complete;

        case ast_node_type_number_type:
        {
            local_node_type(number_type, result.name_type.node);
            result.base_type = result.name_type;
            result.name = number_type->name;
        } break;

        case ast_node_type_alias_type:
        {
            local_node_type(alias_type, result.name_type.node);
            result.base_type                    = alias_type->type.base_type;
            result.base_type.indirection_count += alias_type->type.name_type.indirection_count;
            result.name = alias_type->name;
        } break;
    }

    return result;
}

lang_complete_type get_default_type(lang_parser *parser)
{
    return get_type(parser, lang_base_type_s32);
}

ast_variable * parse_declaration(lang_parser *parser)
{
    new_local_node(variable);

    bool can_expand = try_consume_keyword(parser, s("expand"));

    auto name = try_consume_name(parser);
    lang_require(name.count, parser->iterator, "expected declaration name");

    ast_node *expression = null;

    variable->name = name;

    variable->can_expand = can_expand;

    variable->type = lang_require_call_return_value(parse_type(parser, false), {});
    auto type_is_declared = variable->type.name.count || variable->type.name_type.node;

    if (try_consume(parser, s("=")))
    {
        lang_require_expression(variable->default_expression, parser);
    }

    if (!type_is_declared && !variable->default_expression)
        variable->type = get_default_type(parser);

    return variable;
}

parse_arguments_declaration
{
    base_list_tail_next tail_next = null;
    ast_compound_type *compound_or_union_type = null;

    u32 field_count = 0;
    bool consumed_delimiter = true;
    while (consumed_delimiter)
    {
        lang_require_call(skip_multiline_comments(parser));

        if (try_consume(parser, end_pattern))
        {
            consumed_delimiter = true;
            break;
        }

        if (!compound_or_union_type)
        {
            if (is_union)
            {
                compound_or_union_type = begin_new_node(union_type);
            }
            else
            {
                compound_or_union_type = begin_new_node(compound_type);
            }

            tail_next = make_tail_next(&compound_or_union_type->first_field);
        }

        auto variable = lang_require_call(parse_declaration(parser));
        append_tail_next(&tail_next, &variable->node);
        field_count++;
        consumed_delimiter = try_consume(parser, argument_delimiter);
    }

    lang_require(consumed_delimiter || try_consume(parser, end_pattern), parser->iterator, "expected '%.*s' or '%.*s'", fs(argument_delimiter), fs(end_pattern));

    if (compound_or_union_type)
    {
        compound_or_union_type->field_count = field_count;
        end_node(parser, get_base_node(compound_or_union_type));
    }

    return compound_or_union_type;
}

#define parse_single_statement_declaration ast_node * parse_single_statement(bool *ok, lang_parser *parser, bool is_file_scope)
parse_single_statement_declaration;

#define parse_statements_declaration ast_node * parse_statements(lang_parser *parser, bool is_file_scope)
parse_statements_declaration;

#define clone_declaration ast_node * clone(lang_parser *parser, ast_node *root, ast_node *clone_parent)
clone_declaration;

bool parse_scoped_statements_begin(ast_node **first_statement, lang_parser *parser)
{
    auto open_brace = parser->iterator;

    if (!try_consume(parser, s("{")))
        return false;

    *first_statement = lang_require_call(parse_statements(parser, false));

    if (!try_consume(parser, s("}")))
    {
        auto builder = parser_error_begin(parser, parser->iterator, "expected closing '}' in scope");
        auto open_location = get_location_line(parser, open_brace);
        print_line(builder, "scope was opened here:");
        print_location_source(builder, open_location);
        parser_error_end(parser);
        return false;
    }

    return true;
}

void parse_scoped_statements_end(ast_node *first_statement, ast_node *parent)
{
    // link children to parent, since we create parent later
    for (auto it = first_statement; it; it = it->next)
        it->parent = parent;
}

ast_node * parse_single_or_scoped_statements(lang_parser *parser)
{
    ast_node *first_statement;
    auto ok = lang_require_call(parse_scoped_statements_begin(&first_statement, parser));
    if (!ok)
    {
        first_statement = lang_require_call(parse_single_statement(&ok, parser, false));
    }

    // no need to call parse_scoped_statements_end, since this assumes a parent

    return first_statement;
}

ast_module * get_or_create_module(lang_parser *parser, string name)
{
    scope_save(parser->parse_state.current_parent);

    if (!name.count)
    {
        if (!parser->unnamed_module)
        {
            new_local_node(module);
            module->node.parent = null; // modules have no parent

            append_list(&parser->module_list, module);

            parser->unnamed_module = module;
        }

        return parser->unnamed_module;
    }

    for (auto it = parser->module_list.first; it; it = (ast_module *) it->node.next)
    {
        if (it->name == name)
            return it;
    }

    new_local_leaf_node(module, name);
    module->node.parent = null; // modules have no parent
    module->name = name;

    append_list(&parser->module_list, module);

    return module;
}

ast_file * get_or_create_internal_override_file(lang_parser *parser, ast_module *module)
{
    scope_save(parser->parse_state.current_parent);

    if (!module->internal_override_file)
    {
        new_local_node(file);
        file->module = module;
        file->index = parser->file_count;
        parser->file_count++;

        new_local_node(file_reference);
        file_reference->file = file;

        file_reference->node.next = get_base_node(module->first_file);
        module->first_file = file_reference;

        module->internal_override_file = file;
    }

    return module->internal_override_file;
}

#if 0
ast_file * try_parse_override(lang_parser *parser)
{
    ast_file *override_module_internal_file = null;
    if (try_consume_keyword(parser, s("override")))
    {
        auto name = try_consume_name(parser);
        lang_require(name.count, parser->iterator, "expected module name after 'override'");
        auto module = get_or_create_module(parser, name);
        override_module_internal_file = get_or_create_internal_override_file(parser, module);
    }

    return override_module_internal_file;
}
#endif

parse_single_statement_declaration
{
    lang_require_call(skip_multiline_comments(parser));

    if (starts_with(parser->iterator, s("}")))
    {
        *ok = false;
        return null;
    }

    string label = {};
    if (try_consume_keyword(parser, s("label")))
    {
        label = try_consume_name(parser);
        lang_require(label.count, parser->iterator, "expected name after 'label'");
    }
    // label should be set to {}, when it's consumed
    // NOTE: we can't return from inside a defer, since its a lambda
    defer { lang_require_return_value(!label.count, , label, "'label' not allowed for this statement"); };

    {
        auto scope_start = parser->iterator;
        ast_node *scoped_statements;
        *ok = lang_require_call(parse_scoped_statements_begin(&scoped_statements, parser));
        if (*ok)
        {
            new_local_node(scope, scope_start);
            scope->label = label;
            scope->first_statement = scoped_statements;
            parse_scoped_statements_end(scoped_statements, get_base_node(scope));
            label = {}; // consume label

            return get_base_node(scope);
        }
    }

    ast_file *override_module_internal_file = null;
    string override_token;
    if (try_consume_keyword(parser, s("override")))
    {
        string name = {};
        if (try_consume(parser, s("(")))
        {
            name = try_consume_name(parser);
            lang_require(name.count, parser->iterator, "expected module name after '('");
            lang_require_consume(")", "expected ')' after module name in override");
        }

        auto module = get_or_create_module(parser, name);
        override_module_internal_file = get_or_create_internal_override_file(parser, module);

        override_token = parser->iterator;
    }
    // override_module_internal_file should be set to null, when it's consumed
    // NOTE: we can't return from inside a defer, since its a lambda
    defer {
        if (override_module_internal_file && !override_module_internal_file->module->name.count)
        {
            lang_require_return_value(!override_module_internal_file, , override_token, "'override' for unnamed module not allowed for this statement. you can specify a module name with 'override(name).'");
        }
        else
        {
            lang_require_return_value(!override_module_internal_file, , override_token, "'override' for module '%.*s' not allowed for this statement", fs(override_module_internal_file->module->name));
        }
    };

    *ok = true;
    auto backup = parser->iterator;
    if (try_consume_keyword(parser, s("var")))
    {
        bool is_global = try_consume_keyword(parser, s("global"));

        auto variable = lang_require_call(parse_declaration(parser));
        variable->is_global = is_global;

        lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' at the end of the statement");
        return get_base_node(variable);
    }
    else if (try_consume_keyword(parser, s("if")))
    {
        new_local_node(branch);
        branch->scope.label = label;
        branch->condition = lang_require_call(parse_expression(parser, false));
        lang_require(branch->condition, parser->iterator, "expected condition expression after 'if'");
        label = {}; // consume label

        branch->scope.first_statement = lang_require_call(parse_single_or_scoped_statements(parser));

        if (try_consume(parser, s("else")))
        {
            new_local_node(scope);
            scope->first_statement = lang_require_call(parse_single_or_scoped_statements(parser));
            branch->false_scope = scope;
        }

        return get_base_node(branch);
    }
    else if (try_consume_keyword(parser, s("while")))
    {
        new_local_node(loop);
        loop->scope.label = label;
        loop->condition = lang_require_call(parse_expression(parser, false));
        lang_require(loop->condition, parser->iterator, "expected condition expression after 'while'");
        label = {}; // consume label

        loop->scope.first_statement = lang_require_call(parse_single_or_scoped_statements(parser));

        return get_base_node(loop);
    }
    else if (try_consume_keyword(parser, s("loop")))
    {
        new_local_node(loop_with_counter);
        loop_with_counter->scope.label = label;
        label = {}; // consume label

        if (try_consume_keyword(parser, s("var")))
        {
            auto variable = lang_require_call(parse_declaration(parser));
            loop_with_counter->counter_statement = get_base_node(variable);
        }
        else
        {
            loop_with_counter->counter_statement = lang_require_call(parse_expression(parser, false));
        }
        lang_require(loop_with_counter->counter_statement, parser->iterator, "expected counter statement afer 'loop'");

        lang_require_consume(";", " after loop counter");

        loop_with_counter->end_condition = lang_require_call(parse_expression(parser, false));
        lang_require(loop_with_counter->end_condition, parser->iterator, "expected end condition expression after ';' in loop");

        loop_with_counter->scope.first_statement = lang_require_call(parse_single_or_scoped_statements(parser));

        return get_base_node(loop_with_counter);
    }
    else if (try_consume_keyword(parser, s("switch")))
    {
        new_local_node(branch_switch);
        branch_switch->scope.label = label;
        label = {}; // consume label

        lang_require_expression(branch_switch->condition, parser);

        auto case_tail_next = make_tail_next(&branch_switch->first_case);

        while (try_consume_keyword(parser, s("case")))
        {
            new_local_node(branch_switch_case);

            branch_switch_case->first_expression = lang_require_call(parse_expression(parser, true));
            lang_require(branch_switch_case->first_expression, parser->iterator, "expected expression after 'case'");

            auto expression_tail = &branch_switch_case->first_expression->next;

            while (try_consume(parser, s(",")))
            {
                auto expression = lang_require_call(parse_expression(parser, true));
                lang_require(expression, parser->iterator, "expected expression after ',' in switch case");
                *expression_tail = expression;
                expression_tail = &expression->next;
            }

            append_tail_next(&case_tail_next, &branch_switch_case->node);

            branch_switch_case->scope.first_statement = lang_require_call(parse_single_or_scoped_statements(parser));
        }

        if (try_consume_keyword(parser, s("else")))
        {
            new_local_node(scope);
            branch_switch->default_case_scope = scope;
            scope->first_statement = lang_require_call(parse_single_or_scoped_statements(parser));
        }

        lang_require(branch_switch->first_case || branch_switch->default_case_scope, parser->iterator, "expected 'case' or 'else' after switch expression");

        return get_base_node(branch_switch);
    }
    else if (try_consume_keyword(parser, s("return")))
    {
        new_local_node(function_return);

        auto expression_tail_next = make_tail_next(&function_return->first_expression);

        bool is_first = true;
        while (!try_consume(parser, s(";")))
        {
            lang_require(is_first || try_consume(parser, s(",")), parser->iterator, "expected ',' or ';' after return expression");
            is_first = false;

            // set return value to function output type
            auto expression = lang_require_call(parse_expression(parser, false));
            lang_require(expression, parser->iterator, "expected expression or ';' after return");

            append_tail_next(&expression_tail_next, expression);
        }

        return get_base_node(function_return);
    }
    else if (try_consume_keyword(parser, s("break")))
    {
        new_local_node(scope_control);
        scope_control->label = try_consume_name(parser);
        lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' after break");

        return get_base_node(scope_control);
    }
    else if (try_consume_keyword(parser, s("continue")))
    {
        new_local_node(scope_control);
        scope_control->is_continue = true;
        scope_control->label = try_consume_name(parser);
        lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' after continue");

        return get_base_node(scope_control);
    }
    else if (try_consume_keyword(parser, s("def")))
    {
        auto name = try_consume_name(parser);
        lang_require(name.count, parser->iterator, "expected name after 'def'");

        scope_save(parser->parse_state.current_parent);
        if (try_consume(parser, s("=")))
        {
            new_local_node(constant);

            bool is_global = is_file_scope;
            constant->name = name;
            constant->expression = lang_require_call(parse_expression(parser, is_global));
            lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' after constant definition");

            if (override_module_internal_file)
            {
                constant->node.parent = get_base_node(override_module_internal_file);
                constant->is_override = true;

                // append to statements in internal file
                constant->node.next = override_module_internal_file->first_statement;
                override_module_internal_file->first_statement = get_base_node(constant);
                override_module_internal_file = null; // consume override

                // this is not part of the statements in this file
                return null;
            }

            return get_base_node(constant);
        }
    }
    else if (try_consume_keyword(parser, s("func")))
    {
        ast_node *statement = null;

        auto name = try_consume_name(parser);
        lang_require(name.count, parser->iterator, "expected name after 'func'");

        auto type = lang_require_call(parse_function_type(parser));

        if (try_consume_keyword(parser, s("extern_binding")))
        {
            new_local_node(function);
            function->name = name;
            function->type = type;
            statement = get_base_node(function);

            lang_require(try_consume(parser, s("(")), parser->iterator, "expected '(' after 'extern_binding_lib'");
            new_local_node(external_binding);

            bool ok = lang_require_call(parse_quoted_string(&external_binding->library_name, parser));
            lang_require(ok && external_binding->library_name.count, parser->iterator, "expected library name after 'extern_binding_lib'");

            if (try_consume(parser, s(",")))
            {
                if (try_consume_keyword(parser, s("true")))
                    external_binding->is_dll = true;
                else
                {
                    lang_require(try_consume_keyword(parser, s("false")), parser->iterator, "expected external binding is dynamic arguemnt after ',' ('true' or 'false')");
                }
            }

            lang_require(try_consume(parser, s(")")), parser->iterator, "expected ')' after 'extern_binding' arguments");
            lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' after 'extern_binding' statement");

            function->first_statement = get_base_node(external_binding);
        }
        else if (try_consume_keyword(parser, s("intrinsic")))
        {
            new_local_node(function);
            function->name = name;
            function->type = type;
            statement = get_base_node(function);

            new_local_node(intrinsic);

            if (try_consume(parser, s("(")))
            {
                bool ok = lang_require_call(parse_quoted_string(&intrinsic->header, parser));
                lang_require(ok && intrinsic->header.count, parser->iterator, "expected header name after 'intrinsic'");
                lang_require(try_consume(parser, s(")")), parser->iterator, "expected ')' after 'intrinsic' arguments");
            }

            lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' after 'extern_binding' statement");

            function->first_statement = get_base_node(intrinsic);
        }
        else
        {
            bool do_export = try_consume_keyword(parser, s("export"));

            ast_node *first_statement;
            auto ok = lang_require_call(parse_scoped_statements_begin(&first_statement, parser));
            if (ok)
            {
                new_local_node(function);
                function->name = name;
                function->type = type;
                function->do_export = do_export;
                function->first_statement = first_statement;
                parse_scoped_statements_end(first_statement, get_base_node(function));

                statement = get_base_node(function);
            }
            else
            {
                lang_require(!do_export, parser->iterator, "export is only allowed on functions, not on function types");
                lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' after function type");

                // type alias def x func ...;
                new_local_node(alias_type);
                alias_type->type = type;
                alias_type->name = name;
                statement = get_base_node(alias_type);
            }
        }

        if (type.name_type.node)
            type.name_type.node->parent = statement;

        // check if function overrides another
        if (is_node_type(statement, function) && override_module_internal_file)
        {
            local_node_type(function, statement);
            function->node.parent = get_base_node(override_module_internal_file);
            function->is_override = true;

            // append to statements in internal file
            function->node.next = override_module_internal_file->first_statement;
            override_module_internal_file->first_statement = get_base_node(function);
            override_module_internal_file = null; // consume override

            // this is not part of the statements in this file
            return null;
        }

        return statement;
    }
    else if (try_consume_keyword(parser, s("struct")))
    {
        new_local_node(alias_type);

        auto name = try_consume_name(parser);
        lang_require(name.count, parser->iterator, "expected name after 'struct'");

        lang_require(try_consume(parser, s("{")), parser->iterator, "expected '{' after structure declaration");

        auto compound_type = lang_require_call(parse_arguments(parser, s(";"), s("}"), false));

        alias_type->type.base_type.node = get_base_node(compound_type);
        alias_type->type.name_type      = alias_type->type.base_type;
        alias_type->name = name;

        return get_base_node(alias_type);
    }
    else if (try_consume_keyword(parser, s("enum")))
    {
        new_local_node(alias_type);

        auto name = try_consume_name(parser);
        lang_require(name.count, parser->iterator, "expected name after 'enum'");

        new_local_node(enumeration_type);

        enumeration_type->item_type = lang_require_call_return_value(parse_type(parser, false), {});

        auto item_tail_next = make_tail_next(&enumeration_type->first_item);

        lang_require(try_consume(parser, s("{")), parser->iterator, "expected '{' after enumeration declaration");

        ast_node *previous_expression = null;
        u32 expression_value = 0;

        u32 item_count = 0;
        while (!try_consume(parser, s("}")))
        {
            new_local_node(enumeration_item);
            enumeration_item->name = try_consume_name(parser);
            lang_require(enumeration_item->name.count, parser->iterator, "expected name for enumeration item");
            lang_require(enumeration_item->name != s("count"), enumeration_item->name, "name 'count' is reserved fot the number of declared enumeration items");

            if (try_consume(parser, s("=")))
            {
                enumeration_item->expression = lang_require_call(parse_expression(parser, true));
                assert(enumeration_item->expression);

                previous_expression = enumeration_item->expression;
                expression_value = 1;
            }
            else
            {
                if (previous_expression)
                {
                    new_local_node(binary_operator);
                    binary_operator->operator_type = ast_binary_operator_type_add;

                    new_local_node(number);
                    number->value.u64_value = expression_value;
                    number->value.bit_count_power_of_two = get_bit_count_power_of_two(number->value.u64_value);

                    binary_operator->left       = clone(parser, previous_expression, get_base_node(binary_operator));
                    binary_operator->left->next = get_base_node(number);

                    enumeration_item->expression = get_base_node(binary_operator);
                }
                else
                {
                    new_local_node(number);
                    number->value.u64_value = expression_value;
                    number->value.bit_count_power_of_two = get_bit_count_power_of_two(number->value.u64_value);
                    enumeration_item->expression = get_base_node(number);
                }

                expression_value++;
            }

            lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' at the end of enumeration item");

            item_count++;
            append_tail_next(&item_tail_next, &enumeration_item->node);
        }

        enumeration_type->item_count = item_count;

        alias_type->type.base_type.node = get_base_node(enumeration_type);
        alias_type->type.name_type      = alias_type->type.base_type;
        alias_type->name = name;
        return get_base_node(alias_type);
    }
    else if (try_consume_keyword(parser, s("type")))
    {
        auto name = try_consume_name(parser);
        lang_require(name.count, parser->iterator, "expected name after 'type'");

        new_local_node(alias_type);
        alias_type->name = name;
        alias_type->type = lang_require_call(parse_type(parser, true));
        lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' at the end of type alias definition");

        return get_base_node(alias_type);
    }
    else if (try_consume_keyword(parser, s("module")))
    {
        lang_require(!parser->current_file->module, parser->iterator, "file allready assigned to a module");
        auto name = try_consume_name(parser);
        lang_require(name.count, parser->iterator, "expected module name after 'module'");

        auto module = get_or_create_module(parser, name);
        parser->current_file->module = module;

        auto file_tail_next = (ast_node **) &module->first_file;
        bool found = false;
        for (auto it = module->first_file; it; it = (ast_file_reference *) it->node.next)
        {
            if (it->file == parser->current_file)
            {
                found = true;
                break;
            }

            file_tail_next = &it->node.next;
        }

        if (!found)
        {
            new_local_node(file_reference);
            file_reference->file = parser->current_file;
            *file_tail_next = get_base_node(file_reference);
        }

        lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' at the end of the statement");

        // ok, but not real statement
        return null;
    }
    else if (try_consume_keyword(parser, s("import")))
    {
        auto name = try_consume_name(parser);
        lang_require(name.count, parser->iterator, "expected module name after 'import'");
        lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' at the end of the statement");

        auto file = parser->current_file;
        auto dependency_tail_next = &file->first_module_dependency;

        {
            ast_module_reference *module_reference = null;

            for (auto it = file->first_module_dependency; it; it = (ast_module_reference *) it->node.next)
            {
                if (it->module->name == name)
                {
                    module_reference = it;
                    break;
                }

                dependency_tail_next = &(ast_module_reference *) it->node.next;
            }

            lang_require(!module_reference, parser->iterator, "module '%.*s' was allready inmported in this file", fs(name));
        }

        new_local_leaf_node(module_reference, name);
        module_reference->module = get_or_create_module(parser, name);
        *dependency_tail_next = module_reference;

        // ok, but not real statement
        return null;
    }
    else
    {
        // revert parse
        parser->iterator = backup;

        auto expression = lang_require_call(parse_expression(parser, false));
        if (expression)
        {
            ast_binary_operator_type operator_type;
            bool has_binary_operator = parse_binary_operator(&operator_type, parser);

            // set type to type of left
            auto assignment = lang_require_call(parse_assignment_begin(parser));
            if (assignment)
            {
                if (has_binary_operator)
                {
                     new_local_node(binary_operator, parser->node_locations.base[expression->index].text, true);
                    binary_operator->operator_type = operator_type;
                    binary_operator->left = clone(parser, expression, get_base_node(binary_operator));
                    binary_operator->left->next = assignment->right;
                    binary_operator->left->next->parent = get_base_node(binary_operator);

                    assignment->right = get_base_node(binary_operator);
                }

                parse_assignment_end(parser, assignment, expression);
                expression = get_base_node(assignment);
            }

            lang_require(try_consume(parser, s(";")), parser->iterator, "expected ';' at the end of the statement");

            return expression;
        }
    }

    auto builder = parser_error_begin(parser, parser->iterator, "expected statement.");
    print_line(builder, "starting with any of the following:");

    for (u32 i = 0; i < parser->parse_state.tested_pattern_count; i++)
    {
        print_line(builder, "'%.*s'", fs(parser->parse_state.tested_patterns[i]));
    }

    print_line(builder, "or an expression");
    parser_error_end(parser);
    return null;
}

parse_statements_declaration
{
    ast_node *first_statement = null;
    auto tail_next = make_tail_next(&first_statement);

    while (parser->iterator.count)
    {
        // skip empty statements
        while (try_consume(parser, s(";")))
        {
            if (parser->parse_state.pending_comment.count)
            {
                new_local_node(base_node);
                append_tail_next(&tail_next, base_node);
            }
        }

        // some statements are not added here, they might be global or a module or import
        bool ok;
        auto statement = lang_require_call(parse_single_statement(&ok, parser, is_file_scope));
        if (statement)
            append_tail_next(&tail_next, statement);

        if (!ok)
            break;
    }

    // give trailing comments a home // and always add one node at least
    if (parser->parse_state.pending_comment.count)
    {
        new_local_node(base_node);
        append_tail_next(&tail_next, base_node);
    }

    return first_statement;
}

string get_name(ast_node *node)
{
    string name = s("");
    switch (node->node_type)
    {
        case ast_node_type_file:
        {
            local_node_type(file, node);
            name = file->path;
        } break;

        case ast_node_type_module:
        {
            local_node_type(module, node);
            name = module->name;
        } break;

        case ast_node_type_scope:
        {
            local_node_type(scope, node);
            name = scope->label;
        } break;

        case ast_node_type_variable:
        {
            local_node_type(variable, node);
            name = variable->name;
        } break;

        case ast_node_type_enumeration_item:
        {
            local_node_type(enumeration_item, node);
            name = enumeration_item->name;
        } break;

        case ast_node_type_constant:
        {
            local_node_type(constant, node);
            name = constant->name;
        } break;

        case ast_node_type_number_type:
        {
            local_node_type(number_type, node);
            name = number_type->name;
        } break;

        case ast_node_type_name_reference:
        {
            local_node_type(name_reference, node);
            name = name_reference->name;
        } break;

        case ast_node_type_field_dereference:
        {
            local_node_type(field_dereference, node);
            name = field_dereference->name;
        } break;

        case ast_node_type_alias_type:
        {
            local_node_type(alias_type, node);
            name = alias_type->name;
        } break;

        case ast_node_type_function:
        {
            local_node_type(function, node);
            name = function->name;
        } break;
    }

    return name;
}

void enqueue(ast_queue *queue, ast_node *scope, ast_node **first)
{
    assert(first && *first);

    // insert in reverse order, since we allways consume from back

    u32 count = 0;
    for (auto it = first; *it; it = &(*it)->next)
    {
        count++;

        auto node = *it;
        assert(node->parent == scope, "node not properly build [%i] %.*s '%.s'", node->index, fnode_type_name(node), fnode_name(node));
    }

    resize_buffer(queue, queue->count + count);

    count = 0;
    for (auto it = first; *it; it = &(*it)->next)
    {
        queue->base[queue->count - count - 1].scope       = scope;
        queue->base[queue->count - count - 1].node_field  = it;
        count++;
    }
}

void enqueue(ast_queue *queue, ast_node **node)
{
    enqueue(queue, (*node)->parent, node);
}

void enqueue_one(ast_queue *queue, ast_node **node)
{
    resize_buffer(queue, queue->count + 1);
    queue->base[queue->count - 1].scope       = (*node)->parent;
    queue->base[queue->count - 1].node_field  = node;
}

void skip_children(ast_queue *queue, ast_node *node)
{
    while (queue->count && queue->base[queue->count - 1].scope == node)
        resize_buffer(queue, queue->count - 1);
}

bool next(ast_queue_entry *out_entry, ast_queue *queue)
{
    if (!queue->count)
        return false;

    auto entry = queue->base[--queue->count];
    auto scope = entry.scope;
    auto node  = *entry.node_field;

    assert(node->parent == scope, "node not properly build [%i] %.*s '%.s'", node->index, fnode_type_name(node), fnode_name(node));

    switch (node->node_type)
    {
        cases_complete_message("unhandled node type '%.*s' %.*s", fnode_name(node), fnode_type_name(node));

        case ast_node_type_base_node:
        case ast_node_type_number_type:
        case ast_node_type_number:
        case ast_node_type_string_literal:
        case ast_node_type_name_reference:
        case ast_node_type_external_binding:
        case ast_node_type_intrinsic:
        case ast_node_type_get_call_location:
        case ast_node_type_scope_control:
        {
        } break;

        case ast_node_type_get_function_reference:
        {
            local_node_type(get_function_reference, node);

            if (get_function_reference->type.base_type.node && (get_function_reference->type.base_type.node->parent == node))
                enqueue(queue, node, &get_function_reference->type.base_type.node);
        } break;

        case ast_node_type_get_call_argument_text:
        {
            local_node_type(get_call_argument_text, node);

            enqueue(queue, node, &get_base_node(get_call_argument_text->argument));
        } break;

        case ast_node_type_variable:
        {
            local_node_type(variable, node);

            if (variable->default_expression)
                enqueue(queue, node, &variable->default_expression);

            // type belongs to variable
            if (variable->type.name_type.node && variable->type.name_type.node->parent == node)
                enqueue(queue, node, &variable->type.name_type.node);
        } break;

        case ast_node_type_get_type_info:
        {
            local_node_type(get_type_info, node);

            if (get_type_info->type.name_type.node && get_type_info->type.name_type.node->parent == node)
                enqueue(queue, node, &get_type_info->type.name_type.node);
        } break;

        case ast_node_type_type_byte_count:
        {
            local_node_type(type_byte_count, node);

            if (type_byte_count->type.name_type.node && type_byte_count->type.name_type.node->parent == node)
                enqueue(queue, node, &type_byte_count->type.name_type.node);
        } break;

        case ast_node_type_expression_reference_type:
        {
            local_node_type(expression_reference_type, node);

            enqueue(queue, node, &expression_reference_type->expression);
        } break;

        case ast_node_type_alias_type:
        {
            local_node_type(alias_type, node);

            auto name_node = alias_type->type.name_type.node;
            if (name_node)
            {
                switch (name_node->node_type)
                {
                    cases_complete;

                    case ast_node_type_alias_type:
                    case ast_node_type_number_type:
                    break;

                    case ast_node_type_compound_type:
                    case ast_node_type_union_type:
                    case ast_node_type_function_type:
                    case ast_node_type_enumeration_type:
                    case ast_node_type_array_type:
                    {
                        enqueue(queue, node, &alias_type->type.name_type.node);
                    } break;
                }
            }
        } break;

        case ast_node_type_constant:
        {
            local_node_type(constant, node);

            enqueue(queue, node, &constant->expression);
        } break;

        case ast_node_type_file:
        {
            local_node_type(file, node);

            if (file->first_statement)
                enqueue(queue, node, &file->first_statement);
        } break;

        case ast_node_type_unary_operator:
        {
            local_node_type(unary_operator, node);

            enqueue(queue, node, &unary_operator->expression);
        } break;

        case ast_node_type_binary_operator:
        {
            local_node_type(binary_operator, node);

            assert(binary_operator->left->next && !binary_operator->left->next->next);
            enqueue(queue, node, &binary_operator->left);
        } break;

        case ast_node_type_assignment:
        {
            local_node_type(assignment, node);

            enqueue(queue, node, &assignment->right);
            enqueue(queue, node, &assignment->left);
        } break;

        case ast_node_type_enumeration_type:
        {
            local_node_type(enumeration_type, node);

            if (enumeration_type->first_item)
                enqueue(queue, node, &(ast_node *) enumeration_type->first_item);
        } break;

        case ast_node_type_enumeration_item:
        {
            local_node_type(enumeration_item, node);

            if (enumeration_item->expression)
                enqueue(queue, node, &enumeration_item->expression);
        } break;

        case ast_node_type_compound_literal:
        {
            local_node_type(compound_literal, node);

            if (compound_literal->first_argument)
                enqueue(queue, node, &(ast_node *) compound_literal->first_argument);

            // compound type could be declared on assignment, and would belong to def or var declaration
            if (compound_literal->type.name_type.node && (compound_literal->type.name_type.node->parent == node))
                enqueue(queue, node, &compound_literal->type.name_type.node);
        } break;

        case ast_node_type_argument:
        {
            local_node_type(argument, node);

            if (argument->expression)
                enqueue(queue, node, &(ast_node *) argument->expression);
        } break;

        case ast_node_type_array_literal:
        {
            local_node_type(array_literal, node);

            if (array_literal->first_argument)
                enqueue(queue, node, &(ast_node *) array_literal->first_argument);

            // array type could be declared on assignment, and would belong to def or var declaration
            if (array_literal->type.name_type.node && (array_literal->type.name_type.node->parent == node))
                enqueue(queue, node, &array_literal->type.name_type.node);
        } break;

        case ast_node_type_function_type:
        {
            local_node_type(function_type, node);

            if (!function_type->output.name.count && function_type->output.name_type.node && type_is_not_empty(function_type->output))
                enqueue(queue, node, &function_type->output.name_type.node);

            if (!function_type->input.name.count && function_type->input.name_type.node && type_is_not_empty(function_type->input))
                enqueue(queue, node, &function_type->input.name_type.node);
        } break;

        case ast_node_type_scope:
        {
            local_node_type(scope, node);

            if (scope->first_statement)
                enqueue(queue, node, &scope->first_statement);
        } break;

        case ast_node_type_function:
        {
            local_node_type(function, node);

            if (function->first_statement)
                enqueue(queue, node, &function->first_statement);

            if (!function->type.name.count)
                enqueue(queue, node, &function->type.base_type.node);
        } break;

        case ast_node_type_compound_type:
        case ast_node_type_union_type:
        {
            auto compound_or_union_type = (ast_compound_or_union_type *) node;

            if (compound_or_union_type->first_field)
                enqueue(queue, node, &(ast_node *) compound_or_union_type->first_field);
        } break;

        case ast_node_type_array_type:
        {
            local_node_type(array_type, node);

            if (array_type->item_count_expression)
                enqueue(queue, node, &array_type->item_count_expression);

            if (array_type->item_type.name_type.node && (array_type->item_type.name_type.node->parent == node))
                enqueue(queue, node, &array_type->item_type.name_type.node);
        } break;

        case ast_node_type_branch:
        {
            local_node_type(branch, node);

            if (branch->false_scope)
                enqueue(queue, node, &get_base_node(branch->false_scope));

            if (branch->scope.first_statement)
                enqueue(queue, node, &branch->scope.first_statement);

            enqueue(queue, node, &branch->condition);
        } break;

        case ast_node_type_loop:
        {
            local_node_type(loop, node);

            if (loop->scope.first_statement)
                enqueue(queue, node, &loop->scope.first_statement);

            enqueue(queue, node, &loop->condition);
        } break;

        case ast_node_type_loop_with_counter:
        {
            local_node_type(loop_with_counter, node);

            if (loop_with_counter->scope.first_statement)
                enqueue(queue, node, &loop_with_counter->scope.first_statement);

            enqueue(queue, node, &loop_with_counter->end_condition);
            enqueue(queue, node, &loop_with_counter->counter_statement);
        } break;

        case ast_node_type_branch_switch:
        {
            local_node_type(branch_switch, node);

            if (branch_switch->first_case)
                enqueue(queue, node, &(ast_node *) branch_switch->first_case);

            if (branch_switch->default_case_scope)
                enqueue(queue, node, &get_base_node(branch_switch->default_case_scope));

            enqueue(queue, node, &branch_switch->condition);
        } break;

        case ast_node_type_branch_switch_case:
        {
            local_node_type(branch_switch_case, node);

            if (branch_switch_case->scope.first_statement)
                enqueue(queue, node, &branch_switch_case->scope.first_statement);

            enqueue(queue, node, &branch_switch_case->first_expression);
        } break;

        case ast_node_type_function_return:
        {
            local_node_type(function_return, node);

            if (function_return->first_expression)
                enqueue(queue, node, &function_return->first_expression);
        } break;

        case ast_node_type_function_call:
        {
            local_node_type(function_call, node);

            if (function_call->first_argument)
                enqueue(queue, node, &(ast_node *) function_call->first_argument);

            enqueue(queue, node, &function_call->expression);
        } break;

        case ast_node_type_dereference:
        {
            local_node_type(dereference, node);

            enqueue(queue, node, &dereference->expression);
        } break;

        case ast_node_type_field_dereference:
        {
            local_node_type(field_dereference, node);

            enqueue(queue, node, &field_dereference->expression);
        } break;

        case ast_node_type_array_index:
        {
            local_node_type(array_index, node);

            enqueue(queue, node, &array_index->index_expression);
            enqueue(queue, node, &array_index->array_expression);
        } break;
    }

    *out_entry = entry;

    return true;
}

bool next(ast_node **out_node, ast_queue *queue)
{
    ast_queue_entry out_entry = {};
    bool ok = next(&out_entry, queue);

    if (ok)
        *out_node = *out_entry.node_field;

    return ok;
}

clone_declaration
{
    auto table = &parser->clone_table;
    assert(table->count);
    clear(table);

    auto queue = &parser->clone_queue;

    // clone all nodes and hash node to clone
    {
        resize_buffer(queue, 0);
        enqueue_one(queue, &root);

        ast_node *node;
        while (next(&node, queue))
        {
            u32 byte_count = ast_node_type_byte_counts[node->node_type];

            auto new_node = (ast_node *) new_base_bucket_item((base_bucket_type_array *) &parser->bucket_arrays[node->node_type], ast_node_bucket_byte_counts[node->node_type], ast_bucket_item_count, byte_count);

            begin_node(parser, new_node, node->node_type);
            end_node(parser, new_node);

            auto index = new_node->index;
            memcpy(new_node, node, byte_count);
            new_node->index = index;

            ast_node **insert_node;
            bool ok = insert(&insert_node, table, node);
            assert(ok);
            *insert_node = new_node;
        }
    }

    {
        resize_buffer(queue, 0);
        enqueue_one(queue, &root);

        ast_queue_entry entry;
        while (next(&entry, queue))
        {
            auto parent = entry.scope;

            ast_node **cloned_parent = get_value(table, parent);
            if (cloned_parent)
            {
                auto node = *entry.node_field;

                ast_node **cloned_node = get_value(table, node);
                if (cloned_node)
                {
                    usize field_offset = (u8 *) entry.node_field - (u8 *) parent;
                    if (field_offset < ast_node_type_byte_counts[parent->node_type])
                    {
                        auto clone_field = (ast_node **) ((u8 *) *cloned_parent + field_offset);
                        *clone_field = *cloned_node;
                    }

                    (*cloned_node)->parent = *cloned_parent;

                    if (node->next)
                    {
                        ast_node **cloned_next = get_value(table, node->next);
                        if (cloned_next)
                            (*cloned_node)->next = *cloned_next;
                    }
                }
            }
        }
    }

    ast_node **cloned_root = get_value(table, root);
    assert(cloned_root);
    (*cloned_root)->parent = clone_parent;

    return *cloned_root;
}

u64 get_array_item_count(ast_array_type *array_type, bool is_required = true);

#define get_enumeration_item_value_declaration u64 get_enumeration_item_value(ast_enumeration_item *enumeration_item)
get_enumeration_item_value_declaration;

parsed_number cast_number(parsed_number value, ast_number_type *number_type)
{
    if (!value.is_float && number_type->is_float)
    {
        if (value.is_signed)
            value.f64_value = value.s64_value;
        else
            value.f64_value = value.u64_value;

        value.is_float = true;
        value.is_signed = true;
    }
    else if (!value.is_signed && number_type->is_signed)
    {
        assert(value.is_float == number_type->is_float);

        value.s64_value = value.u64_value;
        value.is_signed = true;
    }
    else if (value.is_float && !number_type->is_float)
    {
        if (number_type->is_signed)
            value.s64_value = value.f64_value;
        else
            value.s64_value = value.f64_value;

        value.is_float  = false;
        value.is_signed = number_type->is_signed;
    }
    else if (value.is_signed && !number_type->is_signed)
    {
        assert(value.is_float == number_type->is_float);

        value.u64_value = value.s64_value;
        value.is_signed = false;
    }

    value.bit_count_power_of_two = number_type->bit_count_power_of_two;
    value.type_is_fixed = true;

    return value;
}

bool evaluate(parsed_number *out_value, ast_node *expression)
{
    switch (expression->node_type)
    {
        default:
        {
            return false;
        } break;

        case ast_node_type_name_reference:
        {
            local_node_type(name_reference, expression);

            if (!name_reference->reference || !is_node_type(name_reference->reference, constant))
                return false;

            local_node_type(constant, name_reference->reference);
            return evaluate(out_value, constant->expression);
        } break;

        case ast_node_type_field_dereference:
        {
            local_node_type(field_dereference, expression);

            if (!field_dereference->reference)
                return false;

            switch (field_dereference->reference->node_type)
            {
                default:
                {
                    return false;
                } break;

                case ast_node_type_array_type:
                {
                    local_node_type(array_type, field_dereference->reference);

                    if ((field_dereference->name != s("count")) || !array_type->item_count_expression)
                        return false;

                    parsed_number value = {};
                    value.u64_value = get_array_item_count(array_type);
                    value.bit_count_power_of_two = get_bit_count_power_of_two(value.u64_value);
                    *out_value = value;
                    return true;
                } break;

                case ast_node_type_enumeration_type:
                {
                    assert(field_dereference->name == s("count"));

                    local_node_type(enumeration_type, field_dereference->reference);
                    parsed_number value = {};
                    value.u64_value = enumeration_type->item_count;
                    value.bit_count_power_of_two = get_bit_count_power_of_two(value.u64_value);
                    *out_value = value;
                    return true;
                } break;

                /*case ast_node_type_variable:
                {
                    local_node_type(variable, field_dereference->reference);
                    return variable->type;
                } break;
                */

                case ast_node_type_enumeration_item:
                {
                    local_node_type(enumeration_item, field_dereference->reference);

                    local_node_type(enumeration_type, enumeration_item->node.parent);
                    if (!enumeration_type->item_type.base_type.node)
                        return false;

                    parsed_number value = {};
                    value.u64_value = get_enumeration_item_value(enumeration_item);
                    value.bit_count_power_of_two = get_bit_count_power_of_two(value.u64_value);
                    *out_value = value;
                    return true;
                } break;
            }
        } break;

        case ast_node_type_unary_operator:
        {
            local_node_type(unary_operator, expression);

            parsed_number value;
            if (!evaluate(&value, unary_operator->expression))
                return false;

            switch (unary_operator->operator_type)
            {
                cases_complete;

                case ast_unary_operator_type_cast:
                {
                    if (!is_node_type(unary_operator->type.base_type.node, number_type))
                        return false;

                    local_node_type(number_type, unary_operator->type.base_type.node);

                    value = cast_number(value, number_type);
                    *out_value = value;
                    return true;
                } break;
            }
        } break;

        case ast_node_type_binary_operator:
        {
            local_node_type(binary_operator, expression);

            parsed_number left;
            parsed_number right;
            if (!evaluate(&left, binary_operator->left) || !evaluate(&right, binary_operator->left->next))
                return false;

            switch (binary_operator->operator_type)
            {
                case ast_binary_operator_type_is:
                {
                    left.u64_value = (left.u64_value == right.u64_value);
                } break;

                case ast_binary_operator_type_is_not:
                {
                    left.u64_value = (left.u64_value != right.u64_value);
                } break;

                case ast_binary_operator_type_is_less:
                {
                    left.u64_value = (left.u64_value < right.u64_value);
                } break;

                case ast_binary_operator_type_is_less_equal:
                {
                    left.u64_value = (left.u64_value <= right.u64_value);
                } break;

                case ast_binary_operator_type_is_greater:
                {
                    left.u64_value = (left.u64_value > right.u64_value);
                } break;

                case ast_binary_operator_type_is_greater_equal:
                {
                    left.u64_value = (left.u64_value >= right.u64_value);
                } break;

                case ast_binary_operator_type_and:
                {
                    left.u64_value = (left.u64_value && right.u64_value);
                } break;

                case ast_binary_operator_type_add:
                {
                    left.u64_value += right.u64_value;
                } break;

                case ast_binary_operator_type_subtract:
                {
                    left.u64_value -= right.u64_value;
                } break;

                case ast_binary_operator_type_multiply:
                {
                    if (left.is_signed || right.is_signed)
                        left.s64_value *= right.s64_value;
                    else
                        left.u64_value *= right.u64_value;
                } break;

                case ast_binary_operator_type_divide:
                {
                    if (left.is_signed || right.is_signed)
                        left.s64_value /= right.s64_value;
                    else
                        left.u64_value /= right.u64_value;
                } break;

                case ast_binary_operator_type_modulo:
                {
                    assert(!left.is_signed && !right.is_signed);
                    left.u64_value %= right.u64_value;
                } break;

                case ast_binary_operator_type_bit_shift_left:
                {
                    left.u64_value = (left.u64_value << right.u64_value);
                } break;

                case ast_binary_operator_type_bit_shift_right:
                {
                    left.u64_value = (left.u64_value >> right.u64_value);
                } break;

                default:
                {
                    // assert in debug, but just fail in release
                    assert(0);
                    return false;
                }
            }

            left.bit_count_power_of_two = get_bit_count_power_of_two(left.u64_value);
            *out_value = left;
            return true;
        } break;

        case ast_node_type_number:
        {
            local_node_type(number, expression);
            *out_value = number->value;
            return true;
        } break;
    }

    unreachable_codepath;
    return false;
}

u64 get_array_item_count(ast_array_type *array_type, bool is_required)
{
    assert(array_type->item_count_expression);

    if (!array_type->item_count)
    {
        parsed_number value;
        bool ok = evaluate(&value, array_type->item_count_expression);
        assert(!is_required || (ok && !value.is_float && !value.is_signed));
        if (ok)
            array_type->item_count = value.u64_value;
    }

    return array_type->item_count;
}

bool get_array_index_value(u64 *out_value, ast_array_index *array_index)
{
    if (!array_index->index.was_evaluated)
    {
        parsed_number value;
        array_index->index.is_constant = evaluate(&value, array_index->index_expression);
        array_index->index.value = value.u64_value;
        array_index->index.was_evaluated = true;
    }

    *out_value = array_index->index.value;
    return array_index->index.is_constant;
}

get_enumeration_item_value_declaration
{
    local_node_type(enumeration_type, enumeration_item->node.parent);
    assert(enumeration_type->item_type.base_type.node);

    if (!enumeration_item->u64_value)
    {
        parsed_number value;
        bool ok = evaluate(&value, enumeration_item->expression);
        assert(ok && !value.is_float);
        enumeration_item->u64_value = value.u64_value;
    }

    return enumeration_item->u64_value;
}

struct type_is_complete_parent
{
    type_is_complete_parent *parent;
    ast_node                *base_type;
};

bool type_is_complete(lang_complete_type type, type_is_complete_parent *parent = null)
{
    if (!type.base_type.node)
        return false;

    type_is_complete_parent current;
    current.parent    = parent;
    current.base_type = type.base_type.node;

    switch (type.base_type.node->node_type)
    {
        cases_complete;

        case ast_node_type_empty_type:
        case ast_node_type_number_type:
        break;

        case ast_node_type_enumeration_type:
        {
            local_node_type(enumeration_type, type.base_type.node);
            return type_is_complete(enumeration_type->item_type, &current);
        } break;

        case ast_node_type_function_type:
        {
            local_node_type(function_type, type.base_type.node);

            if (!type_is_complete(function_type->input, &current) || !type_is_complete(function_type->output, &current))
                return false;
        } break;

        case ast_node_type_compound_type:
        case ast_node_type_union_type:
        {
            auto compound_or_union_type = (ast_compound_type *) type.base_type.node;
            for (auto it = compound_or_union_type->first_field; it; it = (ast_variable *) it->node.next)
            {
                // avoid recursion to self
                {
                    auto parent = &current;
                    while (parent)
                    {
                        if (parent->base_type == it->type.base_type.node)
                            break;

                        parent = parent->parent;
                    }

                    if (parent)
                        continue;
                }

                if (!type_is_complete(it->type, &current))
                    return false;
            }
        } break;

        case ast_node_type_array_type:
        {
            local_node_type(array_type, type.base_type.node);

            if (array_type->item_count_expression)
            {
                parsed_number value;
                if (!evaluate(&value, array_type->item_count_expression))
                    return false;
            }

            return type_is_complete(array_type->item_type, &current);
        } break;
    }

    return true;
}

lang_complete_type get_indirect_type(lang_parser *parser, lang_complete_type type, u32 indirection_count = 1)
{
    if (!type.base_type.node)
        return {};

    // keep the original base_type around, helps with unique types
    // otherwise alias_types (which are always unique) will always use the non-unique base type the originally had
    auto base_type = type.base_type.node;
    type.base_type = {};
    type.name_type.indirection_count += indirection_count;
    resolve_complete_type(parser, &type);
    type.base_type.node = base_type;

    return type;
}

types_are_compatible_declaration
{
    assert(type_is_complete(to) && type_is_complete(from));

    if (!type_is_not_empty(from))
        return type_compatibility_false;

    if (is_node_type(to.base_type.node, union_type))
    {
        auto to_union_type = get_node_type(union_type, to.base_type.node);

        ast_variable *best_field = null;
        auto best_compatibility = type_compatibility_false;

        for (auto field = to_union_type->first_field; field; field = (ast_variable *) field->node.next)
        {
            if (field->can_expand)
            {
                auto compatibility = types_are_compatible(parser, get_indirect_type(parser, field->type, to.name_type.indirection_count), from);
                if (compatibility > best_compatibility)
                {
                    best_field = field;
                    best_compatibility = compatibility;
                }
            }
        }

        if (best_compatibility)
            return best_compatibility;
    }

    if (!to.name_type.indirection_count)
    {
        // implicit cast to lang_typed_value
        if ((to.name_type.node == get_type(parser, lang_base_type_lang_typed_value).name_type.node) && ((to.name_type.node != from.name_type.node) || from.name_type.indirection_count))
            return type_compatibility_requires_cast;

        // implicit cast intergers and pointers to b8 (default bool)
        if ((to.name_type.node != from.name_type.node) && (to.name_type.node == get_type(parser, lang_base_type_b8).name_type.node))
        {
            if (is_node_type(from.base_type.node, number_type))
            {
                auto from_number_type = get_node_type(number_type, from.base_type.node);
                if (!from_number_type->is_float)
                    return type_compatibility_requires_cast;
            }
            else if (from.base_type.indirection_count || is_node_type(from.base_type.node, function_type))
            {
                return type_compatibility_requires_cast;
            }
        }

        // prevent implicit cast from b8 (default bool) to other types
        if ((from.name_type.node != to.name_type.node) && (from.name_type.node == get_type(parser, lang_base_type_b8).name_type.node))
            return type_compatibility_false;
    }

    // implicit cast to and from u8 pointer
    auto u8_reference_node = get_type(parser, lang_base_type_u8).base_type.node;
    if (
        ((to.base_type.node != from.base_type.node) || (to.base_type.indirection_count != from.base_type.indirection_count)) &&
        (((to.base_type.node == u8_reference_node) && (to.base_type.indirection_count == 1) && (from.base_type.indirection_count || is_node_type(from.base_type.node, function_type))) ||
        ((from.base_type.node == u8_reference_node) && (from.base_type.indirection_count == 1) && (to.base_type.indirection_count || is_node_type(to.base_type.node, function_type)))))
        return type_compatibility_requires_cast;

    if (to.base_type.indirection_count != from.base_type.indirection_count)
        return type_compatibility_false;

    if (to.name_type.node == from.name_type.node)
        return type_compatibility_equal;

    if (is_node_type(to.base_type.node, enumeration_type) && is_node_type(from.base_type.node, enumeration_type))
    {
        local_node_type(enumeration_type, to.base_type.node);

        if (is_node_type(enumeration_type->item_type.base_type.node, enumeration_type))
        {
            auto compatibility = types_are_compatible(parser, enumeration_type->item_type, from);
            if (compatibility)
                return compatibility;
        }
    }

    while (is_node_type(to.base_type.node, enumeration_type))
    {
        local_node_type(enumeration_type, to.base_type.node);

        // enum is not strict
        if (!enumeration_type->item_type.name.count)
            break;

        to = enumeration_type->item_type;
    }

    while (is_node_type(from.base_type.node, enumeration_type))
    {
        local_node_type(enumeration_type, from.base_type.node);

        // enum is not strict
        if (!enumeration_type->item_type.name.count)
            break;

        from = enumeration_type->item_type;
    }

    auto result = type_compatibility_equal;

    if (is_node_type(to.base_type.node, number_type) && is_node_type(from.base_type.node, number_type))
    {
        auto to_number_type   = get_node_type(number_type, to.base_type.node);
        auto from_number_type = get_node_type(number_type, from.base_type.node);

        if ((from_number_type->is_float && !to_number_type->is_float) ||
            (from_number_type->is_signed && !to_number_type->is_signed) ||
            (from_number_type->bit_count_power_of_two > to_number_type->bit_count_power_of_two))
            return type_compatibility_false;

        if (to_number_type->is_float && !from_number_type->is_float)
            return type_compatibility_requires_cast;

        if (to_number_type->is_signed && !from_number_type->is_signed)
            result = type_compatibility_number_sign_expand;
        else if (to_number_type->bit_count_power_of_two > from_number_type->bit_count_power_of_two)
            result = type_compatibility_number_size_expand;

        //if ((to_number_type->is_float && !from_number_type->is_float) || (to_number_type->is_signed && !from_number_type->is_signed))
        //if (to_number_type != from_number_type)


        //if (to_number_type != from_number_type)
            //result = type_compatibility_implicit;
    }
    else if (is_node_type(to.base_type.node, array_type) && is_node_type(from.base_type.node, array_type))
    {
        auto to_array_type   = get_node_type(array_type, to.base_type.node);
        auto from_array_type = get_node_type(array_type, from.base_type.node);

        if (types_are_compatible(parser, to_array_type->item_type, from_array_type->item_type) != type_compatibility_equal)
        {

        //TODO: make implict cast to lang_base_array  possible!

            // implicit cast any array to u8[]
            //if (!to_array_type->item_type.name_type.indirection_count && (to_array_type->item_type.name_type.node == get_type(parser, lang_base_type_u8).name_type.node))
                //return type_compatibility_requires_cast;
            //else
                return type_compatibility_false;
        }

        if (!to_array_type->item_count_expression && from_array_type->item_count_expression)
            return type_compatibility_requires_cast;

        if (to_array_type->item_count_expression && !from_array_type->item_count_expression)
            return type_compatibility_false;

        if (to_array_type->item_count_expression && from_array_type->item_count_expression && (get_array_item_count(to_array_type) != get_array_item_count(from_array_type)))
            return type_compatibility_false;
    }
    else if (to.base_type.node != from.base_type.node)
    {
        return type_compatibility_false;
    }

    if (!is_node_type(to.name_type.node, alias_type) || !is_node_type(from.name_type.node, alias_type) || (to.name_type.node == from.name_type.node))
    {
        return result;
    }
    else
    {
        return type_compatibility_requires_cast;
    }
}

maybe_add_cast_declaration
{
    if (compatibility == type_compatibility_equal)
        return false;

    // fetch expression, since *expression_pointer may change
    auto expression = *expression_pointer;
    auto parent = expression->parent;

    ast_node *new_expression = null;
    ast_node *new_parent = null;

    if (!type.name_type.indirection_count && (type.name_type.node == get_type(parser, lang_base_type_b8).name_type.node))
    {
        new_local_named_node(is_not, binary_operator, parser->node_locations.base[expression->index].text);
        is_not->node.parent = parent;
        is_not->node.next     = expression->next;
        is_not->operator_type = ast_binary_operator_type_is_not;

        // order is important, expression->next needs to remain
        is_not->left = get_base_node(new_number_u64(parser, parser->node_locations.base[expression->index].text, 0));
        is_not->left->next = expression;
        is_not->type = type; // set type to b8, so no need to check for further compatibilty

        new_parent     = get_base_node(is_not);
        new_expression = get_base_node(is_not);
    }
    else if (!type.base_type.indirection_count && is_node_type(type.base_type.node, number_type) && is_node_type(expression, number))
    {
        local_node_type(number, expression);
        local_node_type(number_type, type.base_type.node);

        number->value = cast_number(number->value, number_type);
        return true;
    }
    else if (!type.name_type.indirection_count && is_node_type(type.base_type.node, array_type))
    {
        auto expression_type = get_expression_type(parser, expression);
        local_node_type(array_type, expression_type.base_type.node);

        new_local_node(compound_literal, parser->node_locations.base[expression->index].text);
        compound_literal->type        = type;
        compound_literal->node.parent = parent;
        compound_literal->node.next   = expression->next;

        new_expression = get_base_node(compound_literal);

        {
            new_local_node(argument, parser->node_locations.base[expression->index].text);
            argument->name = s("count");
            argument->expression = clone(parser, array_type->item_count_expression, get_base_node(argument));
            compound_literal->first_argument = argument;
        }

        {
            new_local_node(argument, parser->node_locations.base[expression->index].text);
            argument->name = s("base");
            compound_literal->first_argument->node.next = get_base_node(argument);

            new_local_node(field_dereference, parser->node_locations.base[expression->index].text);
            field_dereference->name       = s("base");
            field_dereference->expression = expression;
            field_dereference->type = get_indirect_type(parser, array_type->item_type);
            field_dereference->reference  = get_base_node(array_type);

            argument->expression = get_base_node(field_dereference);

            new_parent = get_base_node(field_dereference);
        }
    }
    else if (!type.name_type.indirection_count && (type.name_type.node == get_type(parser, lang_base_type_lang_typed_value).name_type.node))
    {
        new_local_node(compound_literal, parser->node_locations.base[expression->index].text);
        compound_literal->type        = get_type(parser, lang_base_type_lang_typed_value);
        compound_literal->node.parent = parent;
        compound_literal->node.next   = expression->next;

        auto expression_type = get_expression_type(parser, expression);

        {
            new_local_node(argument, parser->node_locations.base[expression->index].text);
            compound_literal->first_argument = argument;

            new_local_node(get_type_info, parser->node_locations.base[expression->index].text);
            get_type_info->type = expression_type;

            argument->name = s("type");
            argument->expression = get_base_node(get_type_info);
        }

        {
            new_local_node(argument, parser->node_locations.base[expression->index].text);
            compound_literal->first_argument->node.next = get_base_node(argument);

            argument->name = s("value");

        #if 0
            // requires proper support for arbitrary union literal field choice
            if (is_node_type(expression_type.base_type.node, number_type))
            {
                argument->expression = expression;
                new_parent = get_base_node(argument);
            }
            else
        #else
            {
                new_local_named_node(cast, unary_operator, parser->node_locations.base[expression->index].text);
                cast->operator_type = ast_unary_operator_type_cast;

                // don't take pointer on a pointer or a dereference
                if (is_node_type(expression, dereference))
                {
                    local_node_type(dereference, expression);
                    cast->expression = dereference->expression;
                    dereference->expression->parent = get_base_node(cast);

                    new_expression = dereference->expression;
                    new_parent = get_base_node(cast);
                }
                else if (!expression_type.base_type.indirection_count)
                {
                    new_local_named_node(take_reference, unary_operator, parser->node_locations.base[expression->index].text);
                    take_reference->operator_type = ast_unary_operator_type_take_reference;
                    take_reference->expression = expression;
                    take_reference->type = get_indirect_type(parser, expression_type);
                    new_parent = get_base_node(take_reference);

                    cast->expression = get_base_node(take_reference);
                }
                else
                {
                    cast->expression = expression;
                    new_parent = get_base_node(cast);
                }

                cast->type = get_indirect_type(parser, get_type(parser, lang_base_type_u8));
                argument->expression = get_base_node(cast);
            }
        #endif
        }

        new_expression = get_base_node(compound_literal);
    }
    else
    {
        new_local_leaf_node(unary_operator, parser->node_locations.base[expression->index].text);
        unary_operator->operator_type = ast_unary_operator_type_cast;
        unary_operator->expression    = expression;
        unary_operator->type          = type;
        unary_operator->node.parent   = parent;
        unary_operator->node.next     = expression->next;

        new_expression = get_base_node(unary_operator);
        new_parent     = new_expression;
    }

    // NOTE: expression my be changed below

    assert(new_expression && new_parent);

    // redirect children to point to cast instead of expression
    {
        local_buffer(queue, ast_queue)
        enqueue_one(&queue, &parent);
        ast_node *ignored;

        // only iterate over parents children
        next(&ignored, &queue);
        for (u32 i = 0; i < queue.count; i++)
        {
            auto entry = queue.base[i];
            if (*entry.node_field == expression)
                *entry.node_field = new_expression;
        }
    }

    // after iterating
    expression->parent = new_parent;
    expression->next   = null;

    *expression_pointer = new_expression;
    return true;
}

struct byte_count_and_alignment
{
    u32 byte_count;
    u32 byte_alignment;
};

byte_count_and_alignment get_type_byte_count_and_alignment(lang_complete_type type)
{
    // all pointers have the same byte count and alignment
    if (type.base_type.indirection_count)
        return { 8, 8 };

    auto base_type = type.base_type.node;

    if (!base_type)
        return { (u32) -1 };

    switch (base_type->node_type)
    {
        cases_complete;

        // HACK:
        // is same as pointer for now...
        case ast_node_type_function_type:
        {
            return { 8, 8 };
        } break;

        case ast_node_type_enumeration_type:
        {
            local_node_type(enumeration_type, base_type);
            return get_type_byte_count_and_alignment(enumeration_type->item_type);
        } break;

        case ast_node_type_number_type:
        {
            local_node_type(number_type, base_type);
            u32 byte_count = 1 << (number_type->bit_count_power_of_two - 3);
            return { byte_count, byte_count };
        } break;

        case ast_node_type_array_type:
        {
            local_node_type(array_type, base_type);

            if (array_type->item_count_expression)
            {
                auto count_and_alignment = get_type_byte_count_and_alignment(array_type->item_type);
                if (count_and_alignment.byte_count == -1)
                    return count_and_alignment;

                count_and_alignment.byte_count *= get_array_item_count(array_type);
                return count_and_alignment;
            }
            else
            {
                // usize + pointer
                return { 16, 8 };
            }
        } break;

        case ast_node_type_union_type:
        {
            local_node_type(union_type, base_type);

            if (!union_type->byte_count)
            {
                u32 byte_count = 0;
                u32 byte_alignment = 1;

                for (auto field = union_type->first_field; field; field = (ast_variable *) field->node.next)
                {
                    auto count_and_alignment = get_type_byte_count_and_alignment(field->type);
                    if (count_and_alignment.byte_count == -1)
                        return count_and_alignment;

                    field->field_byte_offset = 0;

                    byte_count     = maximum(byte_count, count_and_alignment.byte_count);
                    byte_alignment = maximum(byte_alignment, count_and_alignment.byte_alignment);
                }

                union_type->byte_count     = byte_count;
                union_type->byte_alignment = byte_alignment;
            }

            assert(union_type->byte_alignment);

            return { union_type->byte_count, union_type->byte_alignment };
        } break;

        case ast_node_type_compound_type:
        {
            local_node_type(compound_type, base_type);

            if (!compound_type->byte_count)
            {
                u32 byte_count = 0;
                u32 byte_alignment = 1;

                for (auto field = compound_type->first_field; field; field = (ast_variable *) field->node.next)
                {
                    auto count_and_alignment = get_type_byte_count_and_alignment(field->type);
                    if (count_and_alignment.byte_count == -1)
                        return count_and_alignment;

                    auto mask = count_and_alignment.byte_alignment - 1;
                    byte_count = (byte_count + mask) & ~mask;
                    field->field_byte_offset = byte_count;
                    byte_count += count_and_alignment.byte_count;
                    byte_alignment = maximum(byte_alignment, count_and_alignment.byte_alignment);
                }

                // byte_count is multiple of byte_alignment
                auto mask = byte_alignment - 1;
                byte_count = (byte_count + mask) & ~mask;

                compound_type->byte_count     = byte_count;
                compound_type->byte_alignment = byte_alignment;
            }

            assert(compound_type->byte_alignment);

            return { compound_type->byte_count, compound_type->byte_alignment };
        } break;
    }

    return { (u32) -1 };
}

bool is_type(ast_node *node)
{
    return (node->node_type <= ast_node_type_alias_type);
}


lang_complete_type to_type(lang_parser *parser, ast_node *name_type)
{
    assert(is_type(name_type));
    lang_complete_type type = {};
    type.name_type.node = name_type;
    resolve_complete_type(parser, &type);

    return type;
}

get_expression_type_declaration
{
    switch (node->node_type)
    {
        cases_complete_message("%.*s", fs(ast_node_type_names[node->node_type]));

        case ast_node_type_array_literal:
        {
            local_node_type(array_literal, node);

            return array_literal->type;
        } break;

        case ast_node_type_compound_literal:
        {
            local_node_type(compound_literal, node);

            return compound_literal->type;
        } break;

        case ast_node_type_field_dereference:
        {
            local_node_type(field_dereference, node);

            if (!field_dereference->type.base_type.node)
            {
                if (!field_dereference->reference)
                    return {};

                switch (field_dereference->reference->node_type)
                {
                    cases_complete;

                    case ast_node_type_array_type:
                    {
                        local_node_type(array_type, field_dereference->reference);
                        if (field_dereference->name == s("count"))
                        {
                            if (array_type->item_count_expression)
                                field_dereference->type = get_expression_type(parser, array_type->item_count_expression);
                            else
                                field_dereference->type = get_type(parser, lang_base_type_usize);
                        }
                        else if (field_dereference->name == s("base"))
                        {
                            field_dereference->type = get_indirect_type(parser, array_type->item_type);
                        }
                        else
                        {
                            unreachable_codepath;
                        }
                    } break;

                    case ast_node_type_enumeration_type:
                    {
                        local_node_type(enumeration_type, field_dereference->reference);

                        assert(field_dereference->name == s("count"));
                        local_node_type(alias_type, enumeration_type->node.parent);
                        field_dereference->type = to_type(parser, get_base_node(alias_type));
                    } break;

                    case ast_node_type_variable:
                    {
                        local_node_type(variable, field_dereference->reference);
                        field_dereference->type = variable->type;
                    } break;

                    case ast_node_type_enumeration_item:
                    {
                        local_node_type(enumeration_item, field_dereference->reference);

                        local_node_type(alias_type, enumeration_item->node.parent->parent);

                        lang_complete_type type = to_type(parser, get_base_node(alias_type));
                        field_dereference->type = type;
                    } break;
                }
            }

            return field_dereference->type;
        } break;

        case ast_node_type_unary_operator:
        {
            local_node_type(unary_operator, node);

            switch (unary_operator->operator_type)
            {
                case ast_unary_operator_type_cast:
                {
                    return unary_operator->type;
                } break;

                case ast_unary_operator_type_take_reference:
                {
                    if (!unary_operator->type.base_type.node)
                    {
                        unary_operator->type = get_indirect_type(parser, get_expression_type(parser, unary_operator->expression));
                    }

                    return unary_operator->type;
                } break;

                default:
                {
                    if (!unary_operator->type.base_type.node)
                        unary_operator->type = get_expression_type(parser, unary_operator->expression);

                    return unary_operator->type;
                }
            }
        } break;

        case ast_node_type_binary_operator:
        {
            local_node_type(binary_operator, node);

            switch (binary_operator->operator_type)
            {
                default:
                {
                    if (!binary_operator->type.base_type.node)
                    {
                        if (binary_operator->function && binary_operator->function->type.base_type.node)
                        {
                            local_node_type(function_type, binary_operator->function->type.base_type.node);
                            binary_operator->type = get_function_return_type(function_type);
                        }
                        else
                        {
                            auto left_type  = get_expression_type(parser, binary_operator->left);
                            auto right_type = get_expression_type(parser, binary_operator->left->next);

                            if (!left_type.base_type.node || !right_type.base_type.node)
                                return {};

                            switch (binary_operator->operator_type)
                            {
                                // convert result to b8
                                case ast_binary_operator_type_is:
                                case ast_binary_operator_type_is_not:
                                case ast_binary_operator_type_is_less:
                                case ast_binary_operator_type_is_less_equal:
                                case ast_binary_operator_type_is_greater:
                                case ast_binary_operator_type_is_greater_equal:
                                {
                                    auto b8_type = get_type(parser, lang_base_type_b8);

                                    auto left_compatibility  = types_are_compatible(parser, right_type, left_type);
                                    auto right_compatibility = types_are_compatible(parser, left_type, right_type);

                                    // don't do both casts, or we just swap the types and they would still be incompatible
                                    if (left_compatibility == type_compatibility_requires_cast)
                                        maybe_add_cast(parser, &binary_operator->left, left_compatibility, right_type);
                                    else
                                        maybe_add_cast(parser, &binary_operator->left->next, right_compatibility, left_type);
                                    if (left_compatibility || right_compatibility)
                                        binary_operator->type = b8_type;
                                } break;

                                // convert arguments to b8
                                case ast_binary_operator_type_and:
                                case ast_binary_operator_type_or:
                                case ast_binary_operator_type_xor:
                                {
                                    auto b8_type = get_type(parser, lang_base_type_b8);
                                    auto left_compatibility = types_are_compatible(parser, b8_type, left_type);
                                    maybe_add_cast(parser, &binary_operator->left, left_compatibility, b8_type);

                                    auto right_compatibility = types_are_compatible(parser, b8_type, right_type);
                                    maybe_add_cast(parser, &binary_operator->left->next, right_compatibility, b8_type);

                                    if (left_compatibility && right_compatibility)
                                        binary_operator->type = b8_type;
                                } break;

                                // pointer math
                                case ast_binary_operator_type_add:
                                case ast_binary_operator_type_subtract:
                                {
                                    if (left_type.base_type.indirection_count && !right_type.base_type.indirection_count && is_node_type(right_type.base_type.node, number_type))
                                    {
                                        binary_operator->type = left_type;
                                        break;
                                    }

                                } // fallthrough

                                default:
                                {
                                    // check normal compatibility
                                    auto left_compatibility  = types_are_compatible(parser, left_type, right_type);
                                    auto right_compatibility = types_are_compatible(parser, right_type, left_type);

                                    if (right_compatibility > left_compatibility)
                                    {
                                        binary_operator->type = right_type;
                                        maybe_add_cast(parser, &binary_operator->left, right_compatibility, right_type);
                                    }
                                    else if (left_compatibility)
                                    {
                                        binary_operator->type = left_type;
                                        maybe_add_cast(parser, &binary_operator->left->next, left_compatibility, left_type);
                                    }
                                }
                            }
                        }
                    }

                    return binary_operator->type;
                }
            }
        } break;

        case ast_node_type_dereference:
        {
            local_node_type(dereference, node);

            if (!dereference->type.base_type.node)
            {
                dereference->type = get_expression_type(parser, dereference->expression);

                // trying to dereference a value, check semantics later
                if (!dereference->type.base_type.indirection_count)
                    return {};

                dereference->type.base_type.indirection_count--;
                if (dereference->type.name_type.indirection_count - 1 == dereference->type.base_type.indirection_count)
                    dereference->type.name_type.indirection_count--;
                else
                    dereference->type.name_type = dereference->type.base_type;
            }

            return dereference->type;
        } break;

        case ast_node_type_number:
        {
            local_node_type(number, node);

            u32 base_type;
            if (number->value.is_float)
                base_type = lang_base_type_f32 + (number->value.bit_count_power_of_two - 5);
            else
                base_type = number->value.is_signed * lang_base_type_s8 + (number->value.bit_count_power_of_two - 3);

            return get_type(parser, (lang_base_type) base_type);
        } break;

        case ast_node_type_string_literal:
        {
            return get_type(parser, lang_base_type_string);
        } break;

        case ast_node_type_get_type_info:
        {
            return get_type(parser, lang_base_type_lang_type_info);
        } break;

        case ast_node_type_type_byte_count:
        {
            local_node_type(type_byte_count, node);

            if (!type_byte_count->type.base_type.node)
                return {};

            if (!type_byte_count->byte_count.bit_count_power_of_two)
            {
                auto byte_count = get_type_byte_count_and_alignment(type_byte_count->type).byte_count;
                if (byte_count == -1)
                    return {};

                type_byte_count->byte_count.u64_value = byte_count;
                type_byte_count->byte_count.bit_count_power_of_two = get_bit_count_power_of_two(type_byte_count->byte_count.u64_value);
            }

            return get_type(parser, (lang_base_type) (lang_base_type_u8 + type_byte_count->byte_count.bit_count_power_of_two - 3));
        } break;

        case ast_node_type_array_index:
        {
            local_node_type(array_index, node);
            auto type = get_expression_type(parser, array_index->array_expression);

            // TODO: right now we allow auto dereferncing array pointers
            //if (!type.name_type.node || type.base_type.indirection_count || !is_node_type(type.base_type.node, array_type))
            if (!type.base_type.node || !is_node_type(type.base_type.node, array_type))
                return {};

            local_node_type(array_type, type.base_type.node);

            return array_type->item_type;
        } break;

        case ast_node_type_name_reference:
        {
            local_node_type(name_reference, node);

            if (!name_reference->reference)
                return {};

            switch (name_reference->reference->node_type)
            {
                cases_complete("%.*s", fs(ast_node_type_names[name_reference->reference->node_type]));

                // not fully resolved
                case ast_node_type_function_overloads:
                {
                    return {};
                } break;

                case ast_node_type_alias_type:
                {
                    local_node_type(alias_type, name_reference->reference);
                    return to_type(parser, name_reference->reference);
                } break;

                case ast_node_type_variable:
                {
                    local_node_type(variable, name_reference->reference);
                    return variable->type;
                } break;

                case ast_node_type_constant:
                {
                    local_node_type(constant, name_reference->reference);
                    return get_expression_type(parser, constant->expression);
                } break;

                case ast_node_type_function:
                {
                    local_node_type(function, name_reference->reference);
                    return function->type;
                } break;
            }
        } break;

        case ast_node_type_function_call:
        {
            local_node_type(function_call, node);
            auto type = get_expression_type(parser, function_call->expression);
            if (!type_is_complete(type))
                return {};

            local_node_type(function_type, type.base_type.node);
            return get_function_return_type(function_type);
        } break;

        case ast_node_type_get_call_location:
        {
            return get_type(parser, lang_base_type_lang_code_location);
        } break;

        case ast_node_type_get_call_argument_text:
        {
            local_node_type(get_call_argument_text, node);
            if (!get_call_argument_text->argument->reference)
                return {};
            else
                return get_type(parser, lang_base_type_string);
        } break;

        case ast_node_type_get_function_reference:
        {
            local_node_type(get_function_reference, node);
            return get_function_reference->type;
        } break;
    }

    return {};
}

struct ast_list_entry
{
    ast_list_entry *next;
    ast_node *scope;
    ast_node *node;
};

ast_node * parse_file_statements(lang_parser *parser, string source, string source_name)
{
    parser->source_name = source_name;
    parser->source = source;
    parser->iterator = parser->source;

    consume_white_or_comment(parser);
    parser->parse_state.node_location_base = parser->iterator.base;
    advance_node_location(parser);

    return lang_require_call(parse_statements(parser, true));
}

bool parse(lang_parser *parser, string source, string source_name)
{
    for (auto it = parser->file_list.first; it; it = (ast_file *) it->node.next)
    {
        assert(it->path != source_name);
    }

    parser->parse_state.last_location_token = {};

    new_local_node(file);
    file->path = source_name;
    file->text = source;
    file->index = parser->file_count;
    parser->file_count++;
    parser->current_file = file;
    append_list(&parser->file_list, file);

    file->first_statement = lang_require_call_return_value(parse_file_statements(parser, source, source_name), false);

    lang_require_return_value(parser->iterator.count == 0, false, parser->iterator, "expected statements, unexpected '%c'", parser->iterator.base[0]);

    if (!file->module)
    {
        file->module = get_or_create_module(parser, {});

        new_local_node(file_reference);
        file_reference->file = file;

        file_reference->node.next = (ast_node *) file->module->first_file;
        file->module->first_file = file_reference;
    }

    return !parser->error;
}

void clear_unique_types(lang_parser *parser)
{
    if (!parser->unique_types.table.count)
        init(&parser->unique_types.table, 1024);

    clear(&parser->unique_types.table);

    ast_base_node_bucket_array *bucket_arrays[] = {
        (ast_base_node_bucket_array *) &parser->unique_types.unique_array_type_buckets,
        (ast_base_node_bucket_array *) &parser->unique_types.unique_compound_type_buckets,
        (ast_base_node_bucket_array *) &parser->unique_types.unique_union_type_buckets,
        (ast_base_node_bucket_array *) &parser->unique_types.unique_function_type_buckets,
    };

    usize bucket_item_byte_counts[] = {
        ast_node_type_byte_counts[ast_node_type_array_type],
        ast_node_type_byte_counts[ast_node_type_compound_type],
        ast_node_type_byte_counts[ast_node_type_union_type],
        ast_node_type_byte_counts[ast_node_type_function_type],
    };

    for (u32 bucket_array_index = 0; bucket_array_index < carray_count(bucket_arrays); bucket_array_index++)
    {
        auto bucket_array = bucket_arrays[bucket_array_index];
        bucket_array->tail_next = &bucket_array->first;
        bucket_array->item_count = 0;

        for (auto it = bucket_array->first; it; it = it->next)
        {
            it->count = 0;
            memset(it->base, 0, bucket_item_byte_counts[bucket_array_index] * ast_bucket_item_count);
        }
    }
}

void reset(lang_parser *parser)
{
    crc32_init();

    // reset memory and clear everything else
    {
        auto backup = *parser;
        *parser = {};

        for (u32 node_type = 0; node_type < ast_node_type_count; node_type++)
        {
            parser->bucket_arrays[node_type] = backup.bucket_arrays[node_type];
            auto bucket_array = &parser->bucket_arrays[node_type];
            bucket_array->tail_next = &bucket_array->first;
            bucket_array->item_count = 0;

            for (auto it = bucket_array->first; it; it = it->next)
            {
                it->count = 0;
                memset(it->base, 0, ast_node_type_byte_counts[node_type] * ast_bucket_item_count);
            }
        }

        parser->node_comments = backup.node_comments;
        resize_buffer(&parser->node_comments, 0);

        parser->node_locations = backup.node_locations;
        resize_buffer(&parser->node_locations, 0);

        parser->error_messages.memory = backup.error_messages.memory;
        resize_buffer(&parser->error_messages.memory, 0);

        parser->temp_builder.memory = backup.temp_builder.memory;
        resize_buffer(&parser->temp_builder.memory, 0);

        parser->lang_internal_source = backup.lang_internal_source;

        clear(&backup.required_nodes);
        parser->required_nodes = backup.required_nodes;

        clear(&backup.resolve_table);
        parser->resolve_table = backup.resolve_table;

        {
            if (!backup.clone_table.count)
                init(&backup.clone_table, 1024);
            else
                clear(&backup.clone_table);
            parser->clone_table = backup.clone_table;

            parser->clone_queue = backup.clone_queue;
        }

        // reset unique types
        parser->unique_types = backup.unique_types;
        clear_unique_types(parser);
    }

    {
        // HACK: to support empty return
        new_local_node(empty_type);

        parser->empty_type_node = empty_type;
        parser->empty_type = {};
        parser->empty_type.base_type.node = get_base_node(empty_type);
        parser->empty_type.name_type      = parser->empty_type.base_type;
    }

    begin_list(&parser->module_list);
    begin_list(&parser->file_list);

    base_single_list statements;
    begin_list(&statements);

    for (u32 is_signed = 0; is_signed <= 1; is_signed++)
    {
        for (u32 byte_count_power_of_two = 0; byte_count_power_of_two < 4; byte_count_power_of_two++)
        {
            u32 base_type = is_signed * 4 + byte_count_power_of_two;
            new_local_node(number_type);
            number_type->name = lang_base_type_names[base_type];
            number_type->is_signed = is_signed;
            number_type->is_float  = false;
            number_type->bit_count_power_of_two = 3 + byte_count_power_of_two;

            parser->base_types[base_type] = get_base_node(number_type);

            append_list(&statements, &number_type->node);
        }
    }

    for (u32 i = 0; i < 2; i++)
    {
        u32 base_type = 8 + i;
        new_local_node(number_type);
        number_type->name = lang_base_type_names[base_type];
        number_type->is_signed = true;
        number_type->is_float  = true;
        number_type->bit_count_power_of_two = 5 + i;

        parser->base_types[base_type] = get_base_node(number_type);
        append_list(&statements, &number_type->node);
    }

    assert(parser->lang_internal_source.count);

    auto ok = parse(parser, parser->lang_internal_source, s("lang_internal"));
    assert(ok, "internal compile error");

    auto file = parser->file_list.first;
    parser->lang_file   = file;
    parser->lang_module = file->module;

    // prepend basic types into file
    *statements.tail_next = (base_single_list_entry *) file->first_statement;
    file->first_statement = (ast_node *) statements.first;

    auto parent = get_base_node(file);
    for (auto it = file->first_statement; it; it = it->next)
    {
        if (is_node_type(it, alias_type))
        {
            local_node_type(alias_type, it);

            for (u32 i = lang_base_number_type_count; i < lang_base_number_type_count + lang_base_alias_type_count; i++)
            {
                if (alias_type->name == lang_base_type_names[i])
                {
                    parser->base_types[i] = get_base_node(alias_type);
                    break;
                }
            }
        }
        else if (is_node_type(it, constant))
        {
            local_node_type(constant, it);

            for (u32 i = 0; i < lang_base_constant_count; i++)
            {
                if (constant->name == lang_base_constant_names[i])
                    parser->base_constants[i] = constant;
            }
        }
        else if (is_node_type(it, function))
        {
            local_node_type(function, it);

            for (u32 i = 0; i < lang_base_function_count; i++)
            {
                if (function->name == lang_base_function_names[i])
                    parser->base_functions[i] = function;
            }
        }

        it->parent = parent;
    }

    #if 0
// init dependency_grap
    auto graph = &parser->dependency_graph;

    free_graph(graph);

    if (!graph->table.keys)
    {
        u32 default_count = 1 << 17;
        graph->table = make_dependency_table(default_count, parser->next_node_index);
    }
    else
    {
        memset(graph->table.values, 0, sizeof(*graph->table.values) * graph->table.count);
    }
    #endif

}

ast_node * get_parent_scope(ast_node *node)
{
    while (true)
    {
        node = node->parent;

        if (!node)
            return null;

        switch (node->node_type)
        {
            case ast_node_type_file:
            case ast_node_type_scope:
            case ast_node_type_function:
            case ast_node_type_compound_type:
            case ast_node_type_union_type:
            case ast_node_type_function_type:
            case ast_node_type_loop:
            case ast_node_type_loop_with_counter:
            case ast_node_type_branch:
            case ast_node_type_branch_switch:
            case ast_node_type_branch_switch_case:
                return node;
        }
    }

    unreachable_codepath;
    return null;
}

ast_file * get_file_scope(ast_node *node)
{
    assert(node);

    while (!is_node_type(node, file))
        node = node->parent;

    return (ast_file *) node;
}

ast_node * get_node(lang_resolve_table *table, string name, ast_node *scope)
{
    auto value = get_value(table, { name, scope });
    if (value)
        return value->node;
    else
        return null;
}

bool insert(lang_resolve_table_value **value, lang_resolve_table *table, string name, ast_node *scope, ast_node *node, bool in_initialization_scope = false)
{
    lang_resolve_table_key key = { name, scope };
    auto is_new = insert(value, table, { name, scope });
    if (is_new)
        **value = { node, in_initialization_scope };

    return is_new;
}

bool insert(lang_resolve_table *table, string name, ast_node *scope, ast_node *node, bool in_initialization_scope = false)
{
    lang_resolve_table_value *ignored;
    return insert(&ignored, table, name, scope, node, in_initialization_scope);
}

bool insert(lang_resolve_table *table, string name, ast_node *node, bool in_initialization_scope = false)
{
    return insert(table, name, get_parent_scope(node), node, in_initialization_scope);
}

lang_resolve_table_value find_node_in_scope(lang_resolve_table *resolve_table, ast_node *scope, string name)
{
    // TODO: fix this!
    if (!scope)
        return {};

    lang_resolve_table_key key = { name, scope };
    auto value = get_value(resolve_table, key);
    if (value)
        return *value;
    else
         return {};
}

ast_node * find_node_in_module(lang_resolve_table *resolve_table, ast_module *module, string name)
{
    for (auto file_it = module->first_file; file_it; file_it = (ast_file_reference *) file_it->node.next)
    {
        auto scope = get_base_node(file_it->file);

        auto node = find_node_in_scope(resolve_table, scope, name).node;
        if (node)
            return node;
    }

    return null;
}

bool is_declared_before_node(lang_resolve_table_value value, ast_node *scope, ast_node *at_node, ast_node *at_scope)
{
    // node in same scope should be defined before at_node, to be able to refer to it
    if (!value.in_initialization_scope)
    {
        auto at_statement = at_node;
        while (at_statement->parent != scope)
            at_statement = at_statement->parent;

        for (auto it = value.node; it; it = it->next)
        {
            if (it == at_statement)
                return true;
        }

        // at_node comes before so
        return false;
    }
    else
    {
        return true;
    }
}

ast_node * find_node(lang_parser *parser, ast_node *at_node, string name)
{
    auto file = get_file_scope(at_node);

    auto at_scope = get_parent_scope(at_node);
    auto scope = at_scope;

    bool is_in_local_scope = false;
    for (; scope; scope = get_parent_scope(scope))
    {
        auto value = find_node_in_scope(&parser->resolve_table, scope, name);
        // nodes in scopes are ordered, except for compounds and unions
        if (value.node && (is_node_type(scope, compound_type) || is_node_type(scope, union_type) || is_declared_before_node(value, scope, at_node, at_scope)))
            return value.node;

        // don't cross these scopes, this also skipps global declarations but they will be handled in modules
        if (is_node_type(scope, function) || is_node_type(scope, compound_type) || is_node_type(scope, union_type) || is_node_type(scope, function_type))
        {
            is_in_local_scope = true;
            break;
        }
    }

    {
        {
            auto module = parser->lang_module;

            auto value = find_node_in_scope(&parser->resolve_table, get_base_node(module), name);
            if (value.node)
                return value.node;
        }

        assert(file->module);

        {
            auto module = file->module;

            auto value = find_node_in_scope(&parser->resolve_table, get_base_node(module), name);
            if (value.node && !is_node_type(value.node, function_overloads) && (!is_in_local_scope || !is_node_type(value.node, variable) || ((ast_variable *) value.node)->is_global))
                return value.node;
        }

        for (auto module_it = file->module->first_module_dependency; module_it; module_it = (ast_module_reference *) module_it->node.next)
        {
            auto module = module_it->module;

            auto node = find_node_in_scope(&parser->resolve_table, get_base_node(module), name).node;
            if (node && !is_node_type(node, function_overloads) && (!is_in_local_scope || !is_node_type(node, variable) || ((ast_variable *) node)->is_global))
                return node;
        }
    }

    return null;
}

void update(ast_node_buffer *scope_stack, ast_node *scope)
{
    bool found = false;
    for (u32 i = 0; i < scope_stack->count; i++)
    {
        if (scope_stack->base[i] == scope)
        {
            scope_stack->count = i + 1;
            found = true;
            break;
        }
    }

    if (!found)
    {
        resize_buffer(scope_stack, scope_stack->count + 1);
        scope_stack->base[scope_stack->count - 1] = scope;
    }
}

struct resolve_name_entry
{
    ast_node *node;
    string name;

    union
    {
        ast_node           **storage;
        lang_complete_type *type;
    };
};

buffer_type(resolve_name_buffer, resolve_name_array, resolve_name_entry);

void print_type(lang_parser *parser, string_builder *builder, lang_complete_type type)
{
    if (!type.name_type.node)
    {
        print(builder, "/* not resolved type */ '%.*s'", fs(type.name));
        return;
    }

    switch (type.name_type.node->node_type)
    {
        cases_complete;

        case ast_node_type_number_type:
        {
            local_node_type(number_type, type.name_type.node);
            print(builder, "%.*s", fs(number_type->name));
        } break;
        /*
        case ast_node_type_enumeration_type:
        {
        } break;
        */

        case ast_node_type_function_type:
        {
            print(builder, "<anonymous function type %i>", type.name_type.node->index);
        } break;


        case ast_node_type_compound_type:
        {
            print(builder, "<anonymous compound type %i>", type.name_type.node->index);
        } break;

        case ast_node_type_union_type:
        {
            print(builder, "<anonymous union type %i>", type.name_type.node->index);
        } break;

        case ast_node_type_array_type:
        {
            local_node_type(array_type, type.name_type.node);
            print_type(parser, builder, array_type->item_type);

            if (array_type->item_count_expression)
                print(builder, "[%llu]", get_array_item_count(array_type));
            else
                print(builder, "[]");
        } break;

        case ast_node_type_alias_type:
        {
            local_node_type(alias_type, type.name_type.node);
            print(builder, "%.*s", fs(alias_type->name));
        } break;
    }

    for (u32 i = 0; i < type.name_type.indirection_count; i++)
        print(builder, " ref");
}

void print_name(lang_parser *parser, string_builder *builder, ast_node *node)
{
    if (is_type(node))
    {
        print_type(parser, builder, to_type(parser, node));
    }
    else
    {
        auto name = get_name(node);
        print(builder, "%.*s", fs(name));
    }
}

struct arguments_are_compatible_result
{
    type_compatibility compatibility;
    ast_argument *first_incompatible_argument;
};

arguments_are_compatible_result arguments_are_compatible(lang_parser *parser, lang_complete_type type, bool type_can_expand, ast_argument **arguments)
{
    if (*arguments)
    {
        auto argument_type = get_expression_type(parser, (*arguments)->expression);
        auto compatibility = types_are_compatible(parser, type, argument_type);
        if (compatibility)
        {
            // number literals are treated as the maximum type the function needs
            switch (compatibility)
            {
                case type_compatibility_number_size_expand:
                case type_compatibility_number_sign_expand:
                {
                    if (is_node_type((*arguments)->expression, number))
                    {
                        local_node_type(number, (*arguments)->expression);
                        if (!number->value.type_is_fixed)
                            compatibility = type_compatibility_equal;
                    }
                } break;
            }

            (*arguments) = (ast_argument *) (*arguments)->node.next;

            return { compatibility, null };
        }
    }

    if (!type_can_expand)
        return { type_compatibility_false, *arguments };

    auto base_type = type.base_type.node;
    switch (base_type->node_type)
    {
        cases_complete;

        case ast_node_type_empty_type:
            return { type_compatibility_false, *arguments };

        case ast_node_type_union_type:
        {
            auto union_type = (ast_compound_or_union_type *) base_type;

            type_compatibility best_compatibility = type_compatibility_false;
            auto best_arguments = *arguments;

            for (auto field = union_type->first_field; field; field = (ast_variable *) field->node.next)
            {
                auto test_arguments = *arguments;
                auto compatibility = arguments_are_compatible(parser, field->type, field->can_expand, &test_arguments).compatibility;
                if (compatibility > best_compatibility)
                {
                    best_compatibility = compatibility;
                    best_arguments = test_arguments;
                }
            }

            if (!best_compatibility)
                break;

            *arguments = best_arguments;

            return { best_compatibility, null };
        } break;

        case ast_node_type_compound_type:
        {
            auto compound_type = (ast_compound_or_union_type *) base_type;

            type_compatibility worst_compatibility = type_compatibility_equal;

            auto field = compound_type->first_field;
            for (; field; field = (ast_variable *) field->node.next)
            {
                auto result = arguments_are_compatible(parser, field->type, field->can_expand, arguments);
                if (!result.compatibility)
                {
                    if (field->default_expression)
                        continue;
                    else
                        return result;
                }

                if (worst_compatibility > result.compatibility)
                    worst_compatibility = result.compatibility;
            }

            if (!worst_compatibility)
                break;

            while (field && field->default_expression)
                field = (ast_variable *) field->node.next;

            // too few arguments
            if (field)
                break;

            return { worst_compatibility, null };
        } break;

        case ast_node_type_array_type:
        {
            local_node_type(array_type, base_type);

#if 0
            lang_complete_type next_type = {};
            if (iterator->input_variable->node.next)
            {
                local_node_type(variable, iterator->input_variable->node.next);
                next_type = variable->type;
            }
#endif

            type_compatibility worst_compatibility = type_compatibility_equal;

            usize item_count = 0;
            auto item_type = array_type->item_type;

            usize max_item_count = 0;
            if (array_type->item_count_expression)
                max_item_count = get_array_item_count(array_type);

            // stop on next argument matching
            while ((!max_item_count || (item_count < max_item_count)) && *arguments)
            {
                auto type = get_expression_type(parser, (*arguments)->expression);
                auto compatibility = types_are_compatible(parser, item_type, type);
                if (!compatibility)
                    break;

                if (worst_compatibility > compatibility)
                    worst_compatibility = compatibility;

                item_count++;

                (*arguments) = (ast_argument *) (*arguments)->node.next;
            }

            if (!worst_compatibility)
                break;

            if (!item_count)
                break;

            if (max_item_count && (item_count != max_item_count))
                break;

            return { worst_compatibility, null };
        } break;
    }

    return { type_compatibility_false, *arguments };
}

ast_argument * add_default_argument(lang_parser *parser, ast_compound_type *compound_type, ast_variable *function_variable, ast_node *parent, string location, bool is_function_input)
{
    auto default_value = function_variable->default_expression;

    // handle pseodo functions for default arguments
    switch (default_value->node_type)
    {
        case ast_node_type_get_call_location:
        {
            local_node_type(get_call_location, default_value);

            assert(is_function_input);

            new_local_node(argument, location);

            new_local_node(compound_literal, location);
            compound_literal->type.name_type.node = parser->base_types[lang_base_type_lang_code_location];
            resolve_complete_type(parser, &compound_literal->type);

            argument->expression = get_base_node(compound_literal);
            argument->expression->parent = get_base_node(argument);

            auto tail_next = make_tail_next(&compound_literal->first_argument);

            auto location_line = get_location_line(parser, location);

            {
                new_local_node(argument, location);
                argument->name = s("module");

                new_local_node(string_literal, location);
                string_literal->text = location_line.file->module->name;
                argument->expression = get_base_node(string_literal);

                append_tail_next(&tail_next, get_base_node(argument));
            }

            {
                new_local_node(argument, location);
                argument->name = s("file");

                new_local_node(string_literal, location);
                string_literal->text = location_line.file->path;
                argument->expression = get_base_node(string_literal);

                append_tail_next(&tail_next, get_base_node(argument));
            }

            {
                auto function = (ast_function *) parent;
                while (function && !is_node_type(get_base_node(function), function))
                    function = (ast_function *) function->node.parent;

                new_local_node(argument, location);
                argument->name = s("function");

                new_local_leaf_node(string_literal, location);
                if (function)
                    string_literal->text = function->name;
                else
                    string_literal->text = s("main");
                argument->expression = get_base_node(string_literal);

                append_tail_next(&tail_next, get_base_node(argument));
            }

            {
                new_local_node(argument, location);
                argument->name = s("file_index");

                new_local_node(number, location);
                number->value.u64_value = location_line.file->index;
                number->value.bit_count_power_of_two = 5;
                argument->expression = get_base_node(number);

                append_tail_next(&tail_next, get_base_node(argument));
            }

            {
                new_local_node(argument, location);
                argument->name = s("line");

                new_local_node(number, location);
                number->value.u64_value = location_line.line + 1;
                number->value.bit_count_power_of_two = 5;
                argument->expression = get_base_node(number);

                append_tail_next(&tail_next, get_base_node(argument));
            }

            {
                new_local_node(argument, location);
                argument->name = s("column");

                new_local_node(number, location);
                number->value.u64_value = location_line.column + 1;
                number->value.bit_count_power_of_two = 5;
                argument->expression = get_base_node(number);

                append_tail_next(&tail_next, get_base_node(argument));
            }

            return argument;
        } break;

        case ast_node_type_get_call_argument_text:
        {
            local_node_type(get_call_argument_text, default_value);

            assert(is_function_input);

            auto input_argument_variable = get_node_type(variable, get_call_argument_text->argument->reference);

            lang_require_return_value(input_argument_variable, null, input_argument_variable->name, "pseudo function get_call_argument_text argument reference could not be resolved");

            lang_require_return_value(function_variable != input_argument_variable, null, input_argument_variable->name, "pseudo function get_call_argument_text can not have itself as the argument reference");

            lang_require_return_value(input_argument_variable->node.parent == get_base_node(compound_type), null, input_argument_variable->name, "pseudo function get_call_argument_text argument reference was not resolved to an argument of function input");

            local_node_type(function_call, parent);

            auto call_argument = function_call->first_argument;
            for (auto field = compound_type->first_field; field; field = (ast_variable *) field->node.next)
            {
                // get_call_argument_text could come before the referenced argument in the function
                // argument comes after get_call_argument_text, so reset call arguments
                if (field->name == function_variable->name)
                {
                    call_argument = function_call->first_argument;
                    continue;
                }

                // found referenced call_argument
                if (field->name == input_argument_variable->name)
                    break;

                call_argument = (ast_argument *) call_argument->node.next;
            }

            new_local_node(argument, location);

            new_local_leaf_node(string_literal, location);
            string_literal->text = parser->node_locations.base[call_argument->node.index].text;

            argument->expression = get_base_node(string_literal);
            argument->expression->parent = get_base_node(argument);

            return argument;
        } break;

        default:
        {
            new_local_node(argument, location);

            auto default_expression = clone(parser, default_value, null);

            argument->expression = get_base_node(default_expression);
            argument->expression->parent = get_base_node(argument);

            return argument;
        }
    }
}


ast_argument * consume_arguments(lang_parser *parser, lang_complete_type type, bool type_can_expand, ast_node *parent, ast_argument **arguments, bool add_compound_or_union_argument = false)
{
    if (*arguments)
    {
        auto argument = *arguments;
        auto argument_type = get_expression_type(parser, argument->expression);
        auto compatibility = types_are_compatible(parser, type, argument_type);
        if (compatibility)
        {
            maybe_add_cast(parser, &argument->expression, compatibility, type);
            (*arguments) = (ast_argument *) (*arguments)->node.next;

            return argument;
        }
    }

    assert(type_can_expand);

    auto base_type = type.base_type.node;
    switch (base_type->node_type)
    {
        cases_complete;

        case ast_node_type_union_type:
        {
            auto union_type = (ast_compound_or_union_type *) base_type;

            type_compatibility best_compatibility = type_compatibility_false;
            ast_variable *best_field = null;

            for (auto field = union_type->first_field; field; field = (ast_variable *) field->node.next)
            {
                auto test_arguments = *arguments;
                auto compatibility = arguments_are_compatible(parser, field->type, field->can_expand, &test_arguments).compatibility;
                if (compatibility > best_compatibility)
                {
                    best_compatibility = compatibility;
                    best_field = field;
                }
            }

            assert(best_compatibility);

            auto location = get_node_location(parser, parent);

            ast_argument *argument = null;
            ast_compound_literal *compound_literal =null;

            if (!add_compound_or_union_argument)
            {
                argument = new_leaf_node(argument, location);

                compound_literal = new_leaf_node(compound_literal, location);
                compound_literal->type = type;

                argument->expression = get_base_node(compound_literal);
                argument->expression->parent = get_base_node(argument);

                parent = get_base_node(compound_literal);
            }

            auto field_argument = consume_arguments(parser, best_field->type, best_field->can_expand, parent, arguments);
            field_argument->name = best_field->name;
            field_argument->node.parent = parent;
            field_argument->node.next = null;

            if (!add_compound_or_union_argument)
            {
                compound_literal->first_argument = field_argument;
                compound_literal->first_argument->node.parent = get_base_node(compound_literal);
            }
            else
            {
                argument = field_argument;
            }

            return argument;
        } break;

        case ast_node_type_compound_type:
        {
            auto compound_type = (ast_compound_or_union_type *) base_type;

            auto location = get_node_location(parser, parent);

            ast_argument *argument = null;
            ast_compound_literal *compound_literal =null;

            if (!add_compound_or_union_argument)
            {
                argument = new_leaf_node(argument, location);

                compound_literal = new_leaf_node(compound_literal, location);
                compound_literal->type = type;

                argument->expression = get_base_node(compound_literal);
                argument->expression->parent = get_base_node(argument);

                parent = get_base_node(compound_literal);
            }

            ast_argument *head = null;
            ast_argument **tail = &head;

            auto field = compound_type->first_field;
            for (; field; field = (ast_variable *) field->node.next)
            {
                auto test_arguments = *arguments;
                auto compatibility = arguments_are_compatible(parser, field->type, field->can_expand, &test_arguments).compatibility;

                ast_argument *field_argument;
                if (compatibility)
                {
                    field_argument = consume_arguments(parser, field->type, field->can_expand, parent, arguments);
                }
                else
                {
                    assert(field->default_expression);
                    field_argument = add_default_argument(parser, compound_type, field, parent, location, add_compound_or_union_argument);
                }

                field_argument->name = field->name;
                field_argument->node.parent = parent;

                *tail = field_argument;
                tail = &(ast_argument *) field_argument->node.next;
            }

            while (field)
            {
                assert(field->default_expression);

                auto field_argument = add_default_argument(parser, compound_type, field, parent, location, add_compound_or_union_argument);

                field_argument->name = field->name;
                field_argument->node.parent = parent;

                *tail = field_argument;
                tail = &(ast_argument *) field_argument->node.next;

                field = (ast_variable *) field->node.next;
            }

            // too few arguments
            assert(!field);

            *tail = null;

            if (!add_compound_or_union_argument)
            {
                compound_literal->first_argument = head;
                head = argument;
            }

            return head;
        } break;

        case ast_node_type_array_type:
        {
            local_node_type(array_type, base_type);

#if 0
            lang_complete_type next_type = {};
            if (iterator->input_variable->node.next)
            {
                local_node_type(variable, iterator->input_variable->node.next);
                next_type = variable->type;
            }
#endif

            auto location = get_node_location(parser, (*arguments)->node.parent);

            new_local_node(argument, location);

            new_local_leaf_node(array_literal, location);

            auto array_item_type = array_type->item_type;

            auto array_literal_type = new_leaf_node(array_type, location);
            array_literal_type->item_type = array_item_type;

            array_literal->type = to_type(parser, get_base_node(array_literal_type));
            array_literal->type.base_type.node->parent = get_base_node(array_literal);

            argument->expression = get_base_node(array_literal);
            argument->expression->parent = get_base_node(argument);

            usize item_count = 0;

            auto tail = &array_literal->first_argument;

            while (*arguments)
            {
                auto item_argument = (*arguments);
                auto type = get_expression_type(parser, item_argument->expression);
                auto compatibility = types_are_compatible(parser, array_item_type, type);
                if (!compatibility)
                    break;

                maybe_add_cast(parser, &item_argument->expression, compatibility, array_item_type);
                item_argument->node.parent = get_base_node(array_literal);

                *tail = item_argument;
                tail = &(ast_argument *) item_argument->node.next;

                (*arguments) = (ast_argument *) (*arguments)->node.next;
                item_count++;
            }

            *tail = null;

            assert(array_literal->first_argument);

            array_literal_type->item_count_expression = new_number_u64_node(parser, location, item_count, get_base_node(array_literal_type));

            auto compatibility = types_are_compatible(parser, type, array_literal->type);
            maybe_add_cast(parser, &argument->expression, compatibility, type);

            return argument;
        } break;
    }

    unreachable_codepath;
    return null;
}

arguments_are_compatible_result arguments_are_compatible(lang_parser *parser, ast_function_type *function_type, ast_argument *first_argument)
{
    if (!type_is_not_empty(function_type->input))
    {
        // too many arguments
        if (first_argument)
            return { type_compatibility_false, first_argument };
        else
            return { type_compatibility_equal, null };
    }

    auto result = arguments_are_compatible(parser, function_type->input, true, &first_argument);

    // too many arguments
    if (first_argument)
        return { type_compatibility_false, first_argument };

    return result;
}

void consume_arguments(lang_parser *parser, ast_function_type *function_type, ast_node *parent, ast_argument **first_argument)
{
    if (!type_is_not_empty(function_type->input))
    {
        // too many arguments
        assert(!*first_argument);

        return;
    }

    // so we can preserve the function call arguments, until the end
    auto test_arguments = *first_argument;
    auto new_first = consume_arguments(parser, function_type->input, true, parent, &test_arguments, true);
    assert(new_first);
    assert(!test_arguments);
    *first_argument = new_first;
}

arguments_are_compatible_result arguments_are_compatible(lang_parser *parser, ast_compound_literal *compound_literal)
{
    // empty compound literals are always valid
    if (!compound_literal->first_argument)
        return { type_compatibility_equal, null };

    auto test_arguments = compound_literal->first_argument;

    arguments_are_compatible_result result;

    if (is_node_type(compound_literal->type.base_type.node, array_type))
    {
        local_node_type(array_type, compound_literal->type.base_type.node);

        // TODO: what is this for?
        if (array_type->item_count_expression)
            return { type_compatibility_false, null };

        auto usize_type = get_type(parser, lang_base_type_usize);
        result = arguments_are_compatible(parser, usize_type, false, &test_arguments);
        if (result.compatibility)
        {
            auto item_result = arguments_are_compatible(parser, get_indirect_type(parser, array_type->item_type), false, &test_arguments);
            if (!item_result.compatibility)
                return item_result;

            result.compatibility = (type_compatibility) minimum((u32) result.compatibility, (u32) item_result.compatibility);
        }
    }
    else
    {
        result = arguments_are_compatible(parser, compound_literal->type, true, &test_arguments);
    }

    // too many arguments
    if (test_arguments)
        return { type_compatibility_false, test_arguments };

    return result;
}

void print_incompatible_arguments_error(lang_parser *parser, string_builder *builder, arguments_are_compatible_result result)
{
    assert(!result.compatibility);
    print(builder, "arguments are incompatible");
    if (result.first_incompatible_argument)
    {
        print_line(builder, ", see first incompatible argument");

        parser_error_location_source(parser, get_node_location(parser, get_base_node(result.first_incompatible_argument)));

        auto type = get_expression_type(parser, result.first_incompatible_argument->expression);
        if (!type_is_not_empty(type))
            print_line(builder, "expression has no type");
    }
    else
    {
        print_line(builder, ", too few arguemnts");
    }
}

void consume_arguments(lang_parser *parser, ast_compound_literal *compound_literal)
{
    if (!compound_literal->first_argument)
        return;

    // so we can preserve the function call arguments, until the end
    auto test_arguments = compound_literal->first_argument;

    ast_argument *new_first;

    if (is_node_type(compound_literal->type.base_type.node, array_type))
    {
        local_node_type(array_type, compound_literal->type.base_type.node);

        assert(!array_type->item_count_expression);

        auto usize_type = get_type(parser, lang_base_type_usize);

        new_first = consume_arguments(parser, usize_type, false, get_base_node(compound_literal), &test_arguments);
        new_first->node.parent = get_base_node(compound_literal);
        new_first->node.next = get_base_node(consume_arguments(parser, get_indirect_type(parser, array_type->item_type), false, get_base_node(compound_literal), &test_arguments));

        new_first->node.next->parent = get_base_node(compound_literal);
        new_first->node.next->next = null;
    }
    else
    {
        new_first = consume_arguments(parser, compound_literal->type, true, get_base_node(compound_literal), &test_arguments, true);
    }

    assert(new_first);
    assert(!test_arguments);
    compound_literal->first_argument = new_first;
}

struct function_overload_iterator
{
    string name;
    ast_file *file;

    u32 state;
    union
    {
        ast_node             *scope;
        ast_module_reference *module_reference;
    };
};

function_overload_iterator find_matching_function_begin(ast_node *at_node, string name)
{
    function_overload_iterator iterator = {};
    iterator.name     = name;
    iterator.scope    = get_parent_scope(at_node);
    iterator.file     = get_file_scope(at_node);
    return iterator;
}

bool find_matching_function_next(ast_function_overloads **out_function_overloads, lang_parser *parser, function_overload_iterator *iterator)
{
    auto name     = iterator->name;

    while (true)
    {
        switch (iterator->state)
        {
            case 0:
            {
                if (!iterator->scope)
                {
                    iterator->state++;
                    break;
                }

                *out_function_overloads = (ast_function_overloads *) get_node(&parser->resolve_table, name, iterator->scope);
                iterator->scope = get_parent_scope(iterator->scope);

                if (*out_function_overloads && is_node_type(get_base_node(*out_function_overloads), function_overloads))
                    return true;
            } break;

            // check module
            case 1:
            {
                assert(iterator->file->module);
                *out_function_overloads = (ast_function_overloads *) get_node(&parser->resolve_table, name, get_base_node(iterator->file->module));

                iterator->module_reference = iterator->file->module->first_module_dependency;
                iterator->state++;

                if (*out_function_overloads && is_node_type(get_base_node(*out_function_overloads), function_overloads))
                    return true;
            } break;

            // check imported modules
            case 2:
            {
                if (!iterator->module_reference)
                {
                    // if we are in lang module, we skip next state (checking lang module again)
                    if (iterator->file->module == parser->lang_module)
                        iterator->state = 4;
                    else
                        iterator->state++;
                    break;
                }

                auto module = iterator->module_reference->module;
                *out_function_overloads = (ast_function_overloads *) get_node(&parser->resolve_table, name, get_base_node(module));

                iterator->module_reference = (ast_module_reference *) iterator->module_reference->node.next;

                if (*out_function_overloads && is_node_type(get_base_node(*out_function_overloads), function_overloads))
                    return true;
            } break;

            // check lang module
            case 3:
            {
                auto module = parser->lang_module;
                *out_function_overloads = (ast_function_overloads *) get_node(&parser->resolve_table, name, get_base_node(module));
                iterator->state++;

                if (*out_function_overloads && is_node_type(get_base_node(*out_function_overloads), function_overloads))
                    return true;
            } break;

            default:
                return false;
        }
    }

    return false;
}

// in layout, not by names
bool compound_types_match(lang_parser *parser, ast_compound_type *left, ast_compound_type *right)
{
    auto right_field = right->first_field;
    for (auto left_field = left->first_field; left_field; left_field = (ast_variable *) left_field->node.next)
    {
        if (!right_field)
            return false;

        if (types_are_compatible(parser, left_field->type, right_field->type) != type_compatibility_equal)
            return false;

        right_field = (ast_variable *) right_field->node.next;
    }

    if (right_field)
        return false;

    return true;
}

void print_duplicate_name_message(lang_parser *parser, string name, ast_node *scope)
{
    auto builder = parser_error_begin(parser, name, "identifier with same name '%.*s' allready declared in the same scope.", fs(name));

    auto other_node = get_node(&parser->resolve_table, name, scope);
    auto other_location = get_location_line(parser, parser->node_locations.base[other_node->index].text);

    print_newline(builder);
    print_line(builder, "see other declaration:");
    print_location_source(builder, other_location);
    parser_error_end(parser);
    return;
}

#define get_or_add_unique_type_declaration lang_complete_type get_or_add_unique_type(lang_parser *parser, lang_complete_type type)
get_or_add_unique_type_declaration;

lang_complete_type get_unique_type(lang_parser *parser, lang_complete_type type)
{
    assert(parser->debug_unique_types_are_finalized);
    auto name_type = type.name_type.node;
    assert(name_type && is_type(name_type));
    assert(type.base_type.node);

    lang_complete_type *unique_type = get_value(&parser->unique_types.table, name_type);
    assert(unique_type);
    return get_indirect_type(parser, *unique_type, type.name_type.indirection_count);
}

ast_node * get_unique_node(lang_parser *parser, ast_node *node)
{
    assert(node);
    if (is_type(node))
        return get_unique_type(parser, to_type(parser, node)).name_type.node;
    else
        return node;
}

void print_call_argument_types(lang_parser *parser, string_builder *builder, ast_function_call *function_call)
{
    print(builder, "(");

    bool is_first = true;
    for (auto call_argument = function_call->first_argument; call_argument; call_argument = (ast_argument *) call_argument->node.next)
    {
        if (!is_first)
            print(builder, ", ");

        print_type(parser, builder, get_expression_type(parser, call_argument->expression));
        is_first = false;
    }
    print(builder, ")");
}

void insert_compound_fields(lang_parser *parser, ast_node *scope, ast_compound_type *compound_type, bool in_initialization_scope)
{
    for (auto it = compound_type->first_field; it; it = (ast_variable *) it->node.next)
    {
        lang_resolve_table_value *value;
        if (!insert(&value, &parser->resolve_table, it->name, scope, get_base_node(it), in_initialization_scope))
        {
            print_duplicate_name_message(parser, it->name, scope);
            return;
        }
    }
}

void insert_function_arguments_and_results(lang_parser *parser, ast_function *function)
{
    assert(type_is_complete(function->type));
    local_node_type(function_type, function->type.base_type.node);

    auto scope = get_parent_scope(get_base_node(function));
    if (is_node_type(scope, file))
    {
        local_node_type(file, scope);
        scope = get_base_node(file->module);
    }

    auto function_overloads = (ast_function_overloads *) get_node(&parser->resolve_table, function->name, scope);
    assert(function_overloads);

    {
        auto unique_function_type = get_or_add_unique_type(parser, function->type);

        auto function_was_overridden = false;
        ast_function_reference **function_next = null;

        auto other_function_next = &function_overloads->first_function_reference;
        for (; *other_function_next; )
        {
            auto other_function = (*other_function_next)->function;

            if (other_function == function)
            {
                // remember pointer, so we can remove ourself, if we where overridden
                function_next = other_function_next;
                other_function_next = (ast_function_reference **) &(*other_function_next)->node.next;
                continue;
            }

            if (!type_is_complete(other_function->type))
            {
                other_function_next = (ast_function_reference **) &(*other_function_next)->node.next;
                continue;
            }

            auto other_function_type = get_or_add_unique_type(parser, other_function->type);
            if (other_function_type.name_type.node == unique_function_type.name_type.node)
            {
                if (function->is_override)
                {
                    lang_require_return_value(!other_function->is_override, , other_function->name, "trying to override function '%.*s' again, you can only override once", fs(function->name));

                    // remove other function from overloads
                    *other_function_next = (ast_function_reference *) (*other_function_next)->node.next;
                    continue; // skip advance below
                }
                else
                {
                    lang_require_return_value(other_function->is_override, , other_function->name, "function '%.*s' is defined again. exactly one of the definitions must be marked with override.", fs(function->name));
                    function_was_overridden = true;
                }
            }

            other_function_next = (ast_function_reference **) &(*other_function_next)->node.next;
        }

        // remove function, if it wasn't already removed
        if (function_next && function_was_overridden)
            *function_next = (ast_function_reference *) (*function_next)->node.next;
    }

    if (type_is_not_empty(function_type->input))
    {
        local_node_type(compound_type, function_type->input.base_type.node);
        lang_require_call_return_value(insert_compound_fields(parser, get_base_node(function), compound_type, true), );
    }
}

bool function_type_has_multiple_return_values(ast_function_type *function_type)
{
    if (!type_is_not_empty(function_type->output))
        return false;

    local_node_type(compound_type, function_type->output.base_type.node);
    return (compound_type->first_field && compound_type->first_field->node.next);
}

bool is_required(lang_parser *parser, ast_node *node)
{
    return contains_key(&parser->required_nodes, node);
}

void collect_required_nodes_and_unique_types(lang_parser *parser)
{
    auto required_nodes = &parser->required_nodes;
    if (!required_nodes->count)
        init(required_nodes, 1024);
    else
        clear(required_nodes);

    local_buffer(required_functions, ast_node_buffer);

    for (auto file = parser->file_list.first; file; file = (ast_file *) file->node.next)
    {
        resize_buffer(&required_functions, required_functions.count + 1);
        required_functions.base[required_functions.count - 1] = get_base_node(file);
    }

    // everything in the lang module is required
    {
        local_buffer(queue, ast_queue);

        auto root = get_base_node(parser->lang_file);
        enqueue_one(&queue, &root);

        ast_node *node;
        while (next(&node, &queue))
        {
            ast_node *required_node = null;

            switch (node->node_type)
            {
                case ast_node_type_alias_type:
                {
                    required_node = node;
                } break;

                case ast_node_type_function:
                {
                    required_node = node;

                    resize_buffer(&required_functions, required_functions.count + 1);
                    required_functions.base[required_functions.count - 1] = node;
                } break;

                case ast_node_type_variable:
                {
                    local_node_type(variable, node);

                    if (!variable->is_global)
                        continue;

                    required_node = node;
                } break;
            }

            if (required_node)
                insert(required_nodes, required_node);
        }
    }

    while (required_functions.count)
    {
        auto scope = required_functions.base[required_functions.count - 1];
        resize_buffer(&required_functions, required_functions.count - 1);

        local_buffer(queue, ast_queue);

        bool is_inside_file = is_node_type(scope, file);

        enqueue_one(&queue, &scope);

        // ignore scope node
        ast_node *node;
        if (!next(&node, &queue))
            continue;

        while (next(&node, &queue))
        {
            ast_node *required_node = null;

            switch (node->node_type)
            {
                // skip global declarations
                case ast_node_type_enumeration_type:
                case ast_node_type_alias_type:
                case ast_node_type_number_type:
                case ast_node_type_array_type:
                case ast_node_type_compound_type:
                case ast_node_type_union_type:
                {
                    continue;
                } break;

                case ast_node_type_function:
                {
                    skip_children(&queue, node);

                    local_node_type(function, node);

                    if (function->do_export)
                        required_node = node;
                    else
                        continue;
                } break;

                case ast_node_type_function_type:
                {
                    local_node_type(function_type, node);

                    if (!function_type_has_multiple_return_values(function_type))
                        continue;

                    required_node = function_type->output.base_type.node;
                } break;

                case ast_node_type_expression_reference_type:
                {
                    local_node_type(expression_reference_type, node);
                    //if (expression_reference_type->type.name_type.node)
                    required_node = expression_reference_type->type.name_type.node;
                } break;

                case ast_node_type_name_reference:
                {
                    local_node_type(name_reference, node);

                    assert(name_reference->reference);

                    if (is_node_type(name_reference->reference, variable))
                    {
                        local_node_type(variable, name_reference->reference);
                        if (!variable->is_global)
                            continue;
                    }
                    else if (!is_node_type(name_reference->reference->parent, file))
                    {
                        continue;
                    }

                    required_node = name_reference->reference;

                    auto type = get_expression_type(parser, node);
                    insert(required_nodes, type.name_type.node);
                } break;

                case ast_node_type_variable:
                {
                    local_node_type(variable, node);

                    if (is_inside_file && variable->is_global)
                        continue;

                    //if (variable->type.name_type.node)
                    required_node = variable->type.name_type.node;
                } break;

                case ast_node_type_constant:
                {
                    local_node_type(constant, node);

                    auto type = get_expression_type(parser, constant->expression);
                    //if (type.name_type.node)
                    required_node = type.name_type.node;
                } break;

                case ast_node_type_array_literal:
                {
                    local_node_type(array_literal, node);
                    //if (array_literal->type.name_type.node)
                    required_node = array_literal->type.name_type.node;
                } break;

                case ast_node_type_compound_literal:
                {
                    local_node_type(compound_literal, node);
                    //if (compound_literal->type.name_type.node)
                    required_node = compound_literal->type.name_type.node;
                } break;

                case ast_node_type_get_function_reference:
                {
                    local_node_type(get_function_reference, node);

                    if (get_function_reference->function)
                        required_node = get_base_node(get_function_reference->function);
                } break;

                case ast_node_type_unary_operator:
                {
                    local_node_type(unary_operator, node);
                    if (unary_operator->function)
                        required_node = get_base_node(unary_operator->function);
                } break;

                case ast_node_type_binary_operator:
                {
                    local_node_type(binary_operator, node);
                    if (binary_operator->function)
                        required_node = get_base_node(binary_operator->function);
                } break;

                case ast_node_type_get_type_info:
                {
                    local_node_type(get_type_info, node);

                    auto type = get_type_info->type;
                    required_node = type.name_type.node;

                    // if you use get_type_info, you need the type table

                    auto type_table = parser->base_constants[lang_base_constant_lang_type_table];
                    insert(required_nodes, get_base_node(type_table));
                } break;

                case ast_node_type_type_byte_count:
                {
                    local_node_type(type_byte_count, node);

                    auto type = type_byte_count->type;
                    required_node = type.name_type.node;
                } break;

                default:
                {
                }
            }

            if (required_node)
            {
                if (insert(required_nodes, required_node))
                {
                    if (is_node_type(required_node, function))
                    {
                        resize_buffer(&required_functions, required_functions.count + 1);
                        required_functions.base[required_functions.count - 1] = required_node;

                        local_node_type(function, required_node);
                        auto type = function->type;
                        if (is_node_type(type.name_type.node, alias_type))
                            insert(required_nodes, type.name_type.node);
                    }
                #if 0
                    else if (!is_type(required_node))
                    {
                        auto type = get_expression_type(parser, required_node);
                        hash_set_insert(required_nodes, type.name_type.node);
                        hash_set_insert(required_nodes, type.base_type.node);
                    }
                #endif
                }
            }
        }
    }

    // get unique types after we found all required nodes
    {
        auto unique_types = &parser->unique_types;

        // resolve may added unique types, but they may not be required
        clear_unique_types(parser);

        for (u32 i = 0; i < required_nodes->count; i++)
        {
            auto key = required_nodes->keys[i];
            if (!key)
                continue;

            if (is_type(key))
                get_or_add_unique_type(parser, to_type(parser, key));
        }

        // get unique base types

        for (usize i = 0; i < unique_types->table.count; i++)
        {
            if (unique_types->table.keys[i])
            {
                unique_types->table.values[i].base_type.node = get_or_add_unique_type(parser, to_type(parser, unique_types->table.values[i].base_type.node)).name_type.node;
            }
        }

    #if _DEBUG
        // get_unique_type enable get_unique_type calls
        parser->debug_unique_types_are_finalized = true;
    #endif
    }

    // update global variable count
    {
        u32 global_variable_count = 0;

        for_bucket_item(bucket, index, parser->variable_buckets)
        {
            auto variable = &bucket->base[index];

            if (variable->is_global)
            {
                if (is_required(parser, get_base_node(variable)))
                    global_variable_count++;
            }
        }

        auto global_variables = parser->base_constants[lang_base_constant_lang_global_variables];
        auto type = get_expression_type(parser, global_variables->expression);
        local_node_type(array_type, type.base_type.node);
        array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), global_variable_count, get_base_node(array_type)));
        array_type->item_count = 0; // force reevaluation
    }

    // update type table type counts
    {
        auto type_table = parser->base_constants[lang_base_constant_lang_type_table];
        auto type = get_expression_type(parser, type_table->expression);
        local_node_type(compound_type, type.base_type.node);

        u32 global_variable_count = 0;

        auto unique_types = &parser->unique_types;

        auto field = compound_type->first_field;

        {
            assert(field->name == s("number_types"));
            local_node_type(array_type, field->type.base_type.node);
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), carray_count(parser->base_number_types), get_base_node(array_type)));
            array_type->item_count = 0; // force reevaluation

            field = (ast_variable *) field->node.next;
        }

        {
            assert(field->name == s("enumeration_types"));
            local_node_type(array_type, field->type.base_type.node);
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), parser->enumeration_type_buckets.item_count, get_base_node(array_type)));
            array_type->item_count = 0; // force reevaluation

            field = (ast_variable *) field->node.next;
        }

        {
            u32 enumeration_item_count = 0;
            for_bucket_item(bucket, index, parser->enumeration_type_buckets)
            {
                auto enumeration_type = &bucket->base[index];
                enumeration_item_count += enumeration_type->item_count;
            }

            assert(field->name == s("enumeration_item_types"));
            local_node_type(array_type, field->type.base_type.node);
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), enumeration_item_count, get_base_node(array_type)));
            array_type->item_count = 0; // force reevaluation

            field = (ast_variable *) field->node.next;
        }

        {
            assert(field->name == s("array_types"));
            local_node_type(array_type, field->type.base_type.node);
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), unique_types->unique_array_type_buckets.item_count, get_base_node(array_type)));
            array_type->item_count = 0; // force reevaluation

            field = (ast_variable *) field->node.next;
        }

        {
            assert(field->name == s("compound_types"));
            local_node_type(array_type, field->type.base_type.node);
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), unique_types->unique_compound_type_buckets.item_count, get_base_node(array_type)));
            array_type->item_count = 0; // force reevaluation

            field = (ast_variable *) field->node.next;
        }

        {
            u32 compound_field_count = 0;
            for_bucket_item(bucket, index, unique_types->unique_compound_type_buckets)
            {
                auto compound_type = &bucket->base[index];
                compound_field_count += compound_type->field_count;
            }

            assert(field->name == s("compound_field_types"));
            local_node_type(array_type, field->type.base_type.node);
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), compound_field_count, get_base_node(array_type)));
            array_type->item_count = 0; // force reevaluation

            field = (ast_variable *) field->node.next;
        }

        {
            assert(field->name == s("union_types"));
            local_node_type(array_type, field->type.base_type.node);
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), unique_types->unique_union_type_buckets.item_count, get_base_node(array_type)));
            array_type->item_count = 0; // force reevaluation

            field = (ast_variable *) field->node.next;
        }

        {
            u32 union_field_count = 0;
            for_bucket_item(bucket, index, unique_types->unique_union_type_buckets)
            {
                auto union_type = &bucket->base[index];
                union_field_count += union_type->field_count;
            }

            assert(field->name == s("union_field_types"));
            local_node_type(array_type, field->type.base_type.node);
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), union_field_count, get_base_node(array_type)));
            array_type->item_count = 0; // force reevaluation

            field = (ast_variable *) field->node.next;
        }

        {
            assert(field->name == s("function_types"));
            local_node_type(array_type, field->type.base_type.node);
            array_type->item_count_expression = get_base_node(new_number_u64(parser, get_node_location(parser, get_base_node(array_type)), unique_types->unique_function_type_buckets.item_count, get_base_node(array_type)));
            array_type->item_count = 0; // force reevaluation

            field = (ast_variable *) field->node.next;
        }

        assert(!field);
    }
}

void replace_node(ast_node *to, ast_node *from)
{
    auto parent = from->parent;

    local_buffer(queue, ast_queue);
    enqueue_one(&queue, &parent);

    bool found;
    ast_queue_entry entry;
    while (next(&entry, &queue))
    {
        if (*entry.node_field == from)
        {
            *entry.node_field = to;
            found = true;
            break;
        }
    }

    to->parent = from->parent;
    to->next   = from->next;

    // not neccessary
    from->parent = null;
    from->next = null;

    assert(found);
}

lang_complete_type try_resolve_expand_array_literal(lang_complete_type type)
{
    if (is_node_type(type.base_type.node, union_type))
    {
        local_node_type(union_type, type.base_type.node);
        for (auto field = union_type->first_field; field; field = (ast_variable *) field->node.next)
        {
            if (field->can_expand)
            {
                if (is_node_type(field->type.base_type.node, array_type))
                    return field->type;
                else if (is_node_type(field->type.base_type.node, union_type))
                    return try_resolve_expand_array_literal(field->type);
            }
        }
    }

    return type;
}

bool try_resolve_expand_array_index(lang_parser *parser, ast_array_index *array_index, lang_complete_type expression_type)
{
    auto base_type = expression_type.base_type.node;
    if (!is_node_type(base_type, compound_type) && !is_node_type(base_type, union_type))
        return false;

    auto compound_or_union_type = (ast_compound_or_union_type *) base_type;
    for (auto field = compound_or_union_type->first_field; field; field = (ast_variable *) field->node.next)
    {
        if (field->can_expand)
        {
            if (is_node_type(field->type.base_type.node, array_type))
            {
                new_local_node(field_dereference, get_node_location(parser, get_base_node(array_index)));

                field_dereference->name = field->name;
                field_dereference->type = field->type;
                field_dereference->reference = get_base_node(field);
                field_dereference->expression = array_index->array_expression;
                field_dereference->expression->parent = get_base_node(field_dereference);

                array_index->array_expression = get_base_node(field_dereference);
                array_index->array_expression->parent = get_base_node(array_index);

                return true;
            }
            else
            {
                bool ok = try_resolve_expand_array_index(parser, array_index, field->type);
                if (ok)
                {
                    local_node_type(field_dereference, array_index->array_expression);

                    new_local_named_node(child_field_dereference, field_dereference, get_node_location(parser, get_base_node(array_index)));
                    child_field_dereference->name = field->name;
                    child_field_dereference->type = field->type;
                    child_field_dereference->reference = get_base_node(field);
                    child_field_dereference->expression = field_dereference->expression;
                    child_field_dereference->expression->parent = get_base_node(child_field_dereference);

                    field_dereference->expression = get_base_node(child_field_dereference);
                    field_dereference->expression->parent = get_base_node(field_dereference);
                    return true;
                }
            }
        }
    }

    return false;
}

void resolve_field_dereference(lang_parser *parser, ast_field_dereference *field_dereference, lang_complete_type expression_type)
{
    auto field_name = field_dereference->name;
    auto base_type = expression_type.base_type.node;
    assert(base_type);

    switch (base_type->node_type)
    {
        cases_complete_message("%.*s", fnode_type_name(base_type));

        case ast_node_type_number_type:
        {
            local_node_type(number_type, base_type);

            lang_require_return_value(false, , field_name, "number type %.*s has no field '%.*s'", fs(number_type->name), fs(field_name));
        } break;

        case ast_node_type_compound_type:
        case ast_node_type_union_type:
        {
            auto compound_or_union_type = (ast_compound_or_union_type *) base_type;

            for (auto field = compound_or_union_type->first_field; field; field = (ast_variable *) field->node.next)
            {
                if (field->name == field_name)
                {
                    field_dereference->reference = get_base_node(field);
                    field_dereference->type      = field->type;
                    return;
                }
            }

            for (auto field = compound_or_union_type->first_field; field; field = (ast_variable *) field->node.next)
            {
                if (field->can_expand)
                {
                    //auto child_field_dereference = *field_dereference;

                    auto expression = field_dereference->expression;

                    lang_require_call_return_value(resolve_field_dereference(parser, field_dereference, field->type), );
                    //auto reference = child_field_dereference->reference;

                    auto current                   = expression->parent;
                    auto current_field_dereference = get_node_type(field_dereference, current);

                    if (current_field_dereference->reference)
                    {
                        new_local_named_node(parent_field_dereference, field_dereference, field_name);

                        replace_node(get_base_node(parent_field_dereference), expression);

                        parent_field_dereference->name      = field->name;
                        parent_field_dereference->type      = field->type;
                        parent_field_dereference->reference = get_base_node(field);
                        parent_field_dereference->expression = expression;
                        parent_field_dereference->expression->parent = get_base_node(parent_field_dereference);

                    #if 0
                        parent_field_dereference->name      = child_field_dereference->name;
                        parent_field_dereference->type      = child_field_dereference->type;
                        parent_field_dereference->reference = child_field_dereference->reference;

                        parent_field_dereference->expression = get_base_node(child_field_dereference);
                    #endif

                        //*field_dereference = parent_field_dereference;
                        return;
                    }
                }
            }
        } break;

        case ast_node_type_enumeration_type:
        {
            local_node_type(enumeration_type, base_type);

            if (field_name == s("count"))
            {
                field_dereference->reference = base_type;
                get_expression_type(parser, get_base_node(field_dereference));
                return;
            }
            else
            {
                for (auto item = enumeration_type->first_item; item; item = (ast_enumeration_item *) item->node.next)
                {
                    if (item->name == field_name)
                    {
                        field_dereference->reference = get_base_node(item);
                        get_expression_type(parser, get_base_node(field_dereference));
                        return;
                    }
                }

                if (is_node_type(enumeration_type->item_type.base_type.node, enumeration_type))
                {
                    lang_require_call_return_value(resolve_field_dereference(parser, field_dereference, enumeration_type->item_type), );
                    if (field_dereference->reference)
                        return;
                }

                local_node_type(alias_type, enumeration_type->node.parent);

                lang_require_return_value(false, , field_name, "enumeration type %.*s has no item '%.*s'", fs(alias_type->name), fs(field_name));
            }
        } break;

        case ast_node_type_array_type:
        {
            local_node_type(array_type, base_type);

            lang_require_return_value(field_name == s("count") || field_name == s("base"), , field_name, "array has no field '%.*s'", fs(field_name));

            field_dereference->reference = base_type;
            get_expression_type(parser, get_base_node(field_dereference));
            return;
        } break;
    }
}

ast_function * resolve_function_overload(lang_parser *parser, ast_node *at_node, string name, ast_node *arguments_parent, ast_argument **first_argument)
{
    for (auto it = *first_argument; it; it = (ast_argument *) it->node.next)
    {
        auto type = get_expression_type(parser, it->expression);
        if (!type_is_complete(type))
            return null;
    }

    local_buffer(matches, ast_node_buffer);
    auto best_match = type_compatibility_false;

    auto iterator = find_matching_function_begin(at_node, name);
    ast_function_overloads *function_overloads;
    while (find_matching_function_next(&function_overloads, parser, &iterator))
    {
        for (auto function_reference = function_overloads->first_function_reference; function_reference; function_reference = (ast_function_reference *) function_reference->node.next)
        {
            auto function = function_reference->function;

            if (!type_is_complete(function->type))
                return null;
        }

        for (auto function_reference = function_overloads->first_function_reference; function_reference; function_reference = (ast_function_reference *) function_reference->node.next)
        {
            auto function = function_reference->function;
            local_node_type(function_type, function->type.base_type.node);

            auto compatibility = arguments_are_compatible(parser, function_type, *first_argument).compatibility;
            if (compatibility)
            {
                if (best_match < compatibility)
                {
                    best_match = compatibility;

                    resize_buffer(&matches, 1);
                    matches.base[0] = get_base_node(function);
                }
                else if (best_match == compatibility)
                {
                    resize_buffer(&matches, matches.count + 1);
                    matches.base[matches.count - 1] = get_base_node(function);
                }
            }
        }
    }

    if (matches.count > 1)
    {
        auto builder = parser_error_begin(parser, get_node_location(parser, at_node), "ambigious function call to '%.*s'", fs(name));

        print_line(builder, "possible function overloads are:");

        for (u32 i = 0; i < matches.count; i++)
        {
            local_node_type(function, matches.base[i]);
            local_node_type(function_type, function->type.base_type.node);

            parser_error_location_source(parser, function->name);
            print_line(builder, "%.*s func%.*s", fs(function->name), fs(get_node_location(parser, get_base_node(function_type))));
        }

        //auto other_node = get(table, name, scope).node;
        //auto other_location = get_location_line(parser, parser->node_locations.base[other_node->index].text);

        //print_newline(builder);
        //print_line(builder, "see other declaration:");
        //print_location_source(builder, other_location);
        parser_error_end(parser);
        return null;
    }
    else if (matches.count == 1)
    {
        local_node_type(function, matches.base[0]);
        local_node_type(function_type, function->type.base_type.node);

        consume_arguments(parser, function_type, arguments_parent, first_argument);
        return function;
    }
    else
    {
        return null;
    }
}

ast_function * resolve_function_reference(lang_parser *parser, ast_node *at_node, string name, ast_function_type *function_type)
{
    ast_function *matching_function = null;

    auto iterator = find_matching_function_begin(at_node, name);
    ast_function_overloads *function_overloads;
    while (find_matching_function_next(&function_overloads, parser, &iterator))
    {
        for (auto function_reference = function_overloads->first_function_reference; function_reference; function_reference = (ast_function_reference *) function_reference->node.next)
        {
            auto function = function_reference->function;

            if (!type_is_complete(function->type))
                return null;
        }

        for (auto function_reference = function_overloads->first_function_reference; function_reference; function_reference = (ast_function_reference *) function_reference->node.next)
        {
            auto function = function_reference->function;
            auto other_function_type = get_node_type(function_type, function->type.base_type.node);

            if (type_is_not_empty(function_type->input) != type_is_not_empty(other_function_type->input))
                continue;

            if (type_is_not_empty(function_type->output) != type_is_not_empty(other_function_type->output))
                continue;

            if (type_is_not_empty(function_type->input))
            {
                auto input_compound       = get_node_type(compound_type, function_type->input.base_type.node);
                auto other_input_compound = get_node_type(compound_type, other_function_type->input.base_type.node);
                if (!compound_types_match(parser, input_compound, other_input_compound))
                    continue;
            }

            if (type_is_not_empty(function_type->output))
            {
                auto output_compound       = get_node_type(compound_type, function_type->output.base_type.node);
                auto other_output_compound = get_node_type(compound_type, other_function_type->output.base_type.node);
                if (!compound_types_match(parser, output_compound, other_output_compound))
                    continue;
            }

            if (matching_function)
            {
                auto builder = parser_error_begin(parser, get_node_location(parser, at_node), "ambigious function reference", fs(name));

                print_line(builder, "previous matching functio here:");

                local_node_type(function_type, matching_function->type.base_type.node);

                parser_error_location_source(parser, matching_function->name);
                print_line(builder, "%.*s func%.*s", fs(matching_function->name), fs(get_node_location(parser, get_base_node(function_type))));

                parser_error_end(parser);
                return null;
            }

            matching_function = function;
        }
    }

    return matching_function;
}

ast_variable * type_contains_other(lang_complete_type type, lang_complete_type other)
{
    //if (type.name_type.node == other.name_type.node)

    if (!is_node_type(type.name_type.node, alias_type))
        return null;

    local_node_type(alias_type, type.name_type.node);

    if (alias_type->type.name_type.indirection_count)
        return null;

    if (!is_node_type(alias_type->type.name_type.node, compound_type) && !is_node_type(alias_type->type.name_type.node, union_type))
        return null;

    auto compound_or_union_type = (ast_compound_or_union_type *) alias_type->type.name_type.node;

    for (auto field = compound_or_union_type->first_field; field; field = (ast_variable *) field->node.next)
    {
        if (!field->type.name_type.indirection_count && (field->type.name_type.node == other.name_type.node))
            return field;
    }

    for (auto field = compound_or_union_type->first_field; field; field = (ast_variable *) field->node.next)
    {
        if (field->type.name_type.indirection_count)
            continue;

        auto result = type_contains_other(field->type, other);
        if (result)
            return result;
    }

    return null;
}

void parser_error_types_are_incompatible(lang_parser *parser, ast_node *at, lang_complete_type to_type, lang_complete_type from_type)
{
    auto builder = parser_error_begin(parser, parser->node_locations.base[at->index].text, "incompatible types");

    print(builder, "    can not convert expression of type ");
    print_type(parser, builder, from_type);
    print(builder, " to expression of type ");
    print_type(parser, builder, to_type);
    print_newline(builder);
    parser_error_end(parser);
}

bool is_assignable(ast_node *expression, bool is_top_call = true)
{
    switch (expression->node_type)
    {
        cases_complete;

        case ast_node_type_number:
        case ast_node_type_string_literal:
        case ast_node_type_array_literal:
        case ast_node_type_compound_literal:
        case ast_node_type_function_call:
        case ast_node_type_binary_operator:
        case ast_node_type_unary_operator:
        case ast_node_type_get_type_info:
        case ast_node_type_constant:
        return false;

        case ast_node_type_dereference:
        return true;

        case ast_node_type_variable:
        {
            assert(!is_top_call); // variables are not expressions, be we can refere to a variable
            return true;
        } break;

        case ast_node_type_name_reference:
        {
            local_node_type(name_reference, expression);
            return is_assignable(name_reference->reference, false);
        } break;

        case ast_node_type_array_index:
        {
            local_node_type(array_index, expression);
            return is_assignable(array_index->array_expression, false);
        } break;

        // TODO: make complete
        case ast_node_type_field_dereference:
        {
            local_node_type(field_dereference, expression);

            switch (field_dereference->reference->node_type)
            {
                case ast_node_type_array_type:
                {
                    local_node_type(array_type, field_dereference->reference);
                    return !array_type->item_count_expression;
                } break;
            }

            return is_assignable(field_dereference->reference, false);
        } break;
    }

    return false;
}

bool scope_control_requires_label(ast_scope_control *scope_control)
{
    auto parent_scope = get_parent_scope(get_base_node(scope_control));

    while (parent_scope)
    {
        if (is_node_type(parent_scope, loop) || is_node_type(parent_scope, loop_with_counter) || (!scope_control->is_continue && is_node_type(parent_scope, branch_switch)))
            break;

        parent_scope = get_parent_scope(parent_scope);
    }

    auto actual_scope = get_base_node(scope_control->scope);
    bool requires_label = is_node_type(actual_scope, scope) || (actual_scope != parent_scope);
    return requires_label;
}

void resolve(lang_parser *parser)
{
#if 0
    // print ast
    {
        local_buffer(queue, ast_queue);

        auto root = get_base_node(parser->file_list.first);
        if (root)
            enqueue(&queue, &root);

        ast_node *node;
        while (next(&node, &queue))
        {
            printf("%.*s 0x%p\n", fs(ast_node_type_names[node->node_type]), node);
        }
    }
#endif

#if 0
    // print modules and files
    for (auto module = parser->module_list.first; module; module = (ast_module *) module->node.next)
    {
        printf("\nmodule %.*s\n", fs(module->name));

        for (auto file_it = module->first_file; file_it; file_it = (ast_file_reference *) file_it->node.next)
        {
            printf("\tfile \"%.*s\"\n", fs(file_it->file->path));
        }
    }
#endif

    // collect all module dependencies from files
    for (auto module = parser->module_list.first; module; module = (ast_module *) module->node.next)
    {
        auto dependency_tail_next = &module->first_module_dependency;

        for (auto file_it = module->first_file; file_it; file_it = (ast_file_reference *) file_it->node.next)
        {
            auto file = file_it->file;

            for (auto file_dependency = file->first_module_dependency; file_dependency; file_dependency = (ast_module_reference *) file_dependency->node.next)
            {

                if (file_dependency->module == module)
                {
                    parser_error_return_value(, parser, get_node_location(parser, get_base_node(file_dependency)), "module %.*s must not importing itself");
                    //print(builder, " has no field '%.*s'", fs(field_dereference->name));
                    //parser_error_location_source(parser, field_dereference->name);
                    //parser_error_end(parser);
                }

                bool found = false;
                for (auto module_dependency = module->first_module_dependency; module_dependency; module_dependency = (ast_module_reference *) module_dependency->node.next)
                {
                    if (file_dependency->module == module_dependency->module)
                    {
                        found = true;
                        break;
                    }
                }

                if (!found)
                {
                    auto module_reference = new_leaf_node(module_reference, get_node_location(parser, get_base_node(file_dependency)));
                    module_reference->node.parent = get_base_node(module);
                    module_reference->module = file_dependency->module;
                    *dependency_tail_next = module_reference;
                    dependency_tail_next = &(ast_module_reference *) module_reference->node.next;
                }
            }
        }
    }

    auto resolve_table = &parser->resolve_table;
    if (!resolve_table->count)
        init(resolve_table, 1 << 14);

    // collect declarations
    {
        for_bucket_item(bucket, index, parser->alias_type_buckets)
        {
            auto alias_type = &bucket->base[index];

            auto scope = get_parent_scope(get_base_node(alias_type));
            if (is_node_type(scope, file))
            {
                local_node_type(file, scope);
                scope = get_base_node(file->module);
            }

            if (!insert(resolve_table, alias_type->name, scope, get_base_node(alias_type)))
            {
                print_duplicate_name_message(parser, alias_type->name, scope);
                return;
            }
        }

        for_bucket_item(bucket, index, parser->variable_buckets)
        {
            auto variable = &bucket->base[index];

            auto scope = get_parent_scope(get_base_node(variable));
            if (variable->is_global && is_node_type(scope, file))
            {
                local_node_type(file, scope);
                scope = get_base_node(file->module);
            }

            bool in_initialization_scope = false;
            switch (variable->node.parent->node_type)
            {
                case ast_node_type_loop_with_counter:
                {
                    local_node_type(loop_with_counter, variable->node.parent);
                    in_initialization_scope = (loop_with_counter->counter_statement == get_base_node(variable));
                } break;
            }

            if (!insert(resolve_table, variable->name, scope, get_base_node(variable), in_initialization_scope))
            {
                print_duplicate_name_message(parser, variable->name, scope);
                return;
            }
        }

        for_bucket_item(bucket, index, parser->constant_buckets)
        {
            auto constant = &bucket->base[index];

            auto scope = get_parent_scope(get_base_node(constant));
            if (is_node_type(scope, file))
            {
                local_node_type(file, scope);
                scope = get_base_node(file->module);
            }

            lang_resolve_table_value *value;
            if (!insert(&value, resolve_table, constant->name, scope, get_base_node(constant)))
            {
                if (is_node_type(value->node, constant))
                {
                    auto other_constant = get_node_type(constant, value->node);
                    if (constant->is_override)
                    {
                        lang_require_return_value(!other_constant->is_override, , other_constant->name, "trying to override constant '%.*s' again, you can only override once", fs(constant->name));
                        value->node = get_base_node(constant);
                    }
                    else
                    {
                        lang_require_return_value(other_constant->is_override, , other_constant->name, "constant '%.*s' is defined again. exactly one of the definitions must be marked with override.", fs(constant->name));
                    }
                }
            }
        }

        for_bucket_item(bucket, index, parser->function_buckets)
        {
            auto function = &bucket->base[index];

            auto scope = get_parent_scope(get_base_node(function));
            if (is_node_type(scope, file))
            {
                local_node_type(file, scope);
                scope = get_base_node(file->module);
            }

            auto function_overloads = (ast_function_overloads *) get_node(resolve_table, function->name, scope);
            if (!function_overloads)
            {
                function_overloads = new_leaf_node(function_overloads, function->name);
                function_overloads->name        = function->name;
                function_overloads->node.parent = scope;

                auto is_new = insert(resolve_table, function_overloads->name, scope, get_base_node(function_overloads));
                assert(is_new);
            }

            new_local_leaf_node(function_reference, function->name);
            function_reference->function = function;

            function_reference->node.next = get_base_node(function_overloads->first_function_reference);
            function_overloads->first_function_reference = function_reference;

            if (type_is_complete(function->type))
            {
                lang_require_call_return_value(insert_function_arguments_and_results(parser, function), );
            }
        }

        for_bucket_item(bucket, index, parser->scope_buckets)
        {
            auto scope = &bucket->base[index];
            if (!scope->label.count)
                continue;

            if (!insert(resolve_table, scope->label, get_base_node(scope)))
            {
                print_duplicate_name_message(parser, scope->label, get_parent_scope(get_base_node(scope)));
                return;
            }
        }

        for_bucket_item(bucket, index, parser->branch_buckets)
        {
            auto branch = &bucket->base[index];
            if (!branch->scope.label.count)
                continue;

            if (!insert(resolve_table, branch->scope.label, get_base_node(branch)))
            {
                print_duplicate_name_message(parser, branch->scope.label, get_parent_scope(get_base_node(branch)));
                return;
            }
        }

        for_bucket_item(bucket, index, parser->branch_switch_buckets)
        {
            auto branch_switch = &bucket->base[index];
            if (!branch_switch->scope.label.count)
                continue;

            if (!insert(resolve_table, branch_switch->scope.label, get_base_node(branch_switch)))
            {
                print_duplicate_name_message(parser, branch_switch->scope.label, get_parent_scope(get_base_node(branch_switch)));
                return;
            }
        }

        for_bucket_item(bucket, index, parser->loop_buckets)
        {
            auto loop = &bucket->base[index];
            if (!loop->scope.label.count)
                continue;

            if (!insert(resolve_table, loop->scope.label, get_base_node(loop)))
            {
                print_duplicate_name_message(parser, loop->scope.label, get_parent_scope(get_base_node(loop)));
                return;
            }
        }

        for_bucket_item(bucket, index, parser->loop_with_counter_buckets)
        {
            auto loop_with_counter = &bucket->base[index];
            if (!loop_with_counter->scope.label.count)
                continue;

            if (!insert(resolve_table, loop_with_counter->scope.label, get_base_node(loop_with_counter)))
            {
                print_duplicate_name_message(parser, loop_with_counter->scope.label, get_parent_scope(get_base_node(loop_with_counter)));
                return;
            }
        }
    }

    local_buffer(unresolved_names, resolve_name_buffer);
    local_buffer(unresolved_types, resolve_name_buffer);
    local_buffer(unresolved_field_dereferences, ast_node_buffer);
    local_buffer(unresolved_array_indices, ast_node_buffer);
    local_buffer(unresolved_variables, ast_node_buffer);
    local_buffer(unresolved_enumeration_types, ast_node_buffer);
    local_buffer(unresolved_expression_reference_types, ast_node_buffer);
    local_buffer(unresolved_function_calls, ast_node_buffer);
    local_buffer(unresolved_unary_operations, ast_node_buffer);
    local_buffer(unresolved_binary_operations, ast_node_buffer);
    local_buffer(unresolved_get_function_references, ast_node_buffer);
    local_buffer(unresolved_functions, ast_node_buffer);
    local_buffer(unresolved_compound_literals, ast_node_buffer);

    // collect
    {
        for_bucket_item(bucket, index, parser->name_reference_buckets)
        {
            auto name_reference = &bucket->base[index];

            if (!name_reference->reference)
            {
                resize_buffer(&unresolved_names, unresolved_names.count + 1);
                unresolved_names.base[unresolved_names.count - 1] = { get_base_node(name_reference), name_reference->name, &name_reference->reference };
            }
        }

        for_bucket_item(bucket, index, parser->function_call_buckets)
        {
            auto function_call = &bucket->base[index];

            if (is_node_type(function_call->expression, name_reference))
            {
                resize_buffer(&unresolved_function_calls, unresolved_function_calls.count + 1);
                unresolved_function_calls.base[unresolved_function_calls.count - 1] = get_base_node(function_call);
            }
        }

        for_bucket_item(bucket, index, parser->binary_operator_buckets)
        {
            auto binary_operator = &bucket->base[index];

            resize_buffer(&unresolved_binary_operations, unresolved_binary_operations.count + 1);
                unresolved_binary_operations.base[unresolved_binary_operations.count - 1] = get_base_node(binary_operator);
        }

        for_bucket_item(bucket, index, parser->unary_operator_buckets)
        {
            auto unary_operator = &bucket->base[index];

            resize_buffer(&unresolved_unary_operations, unresolved_unary_operations.count + 1);
                unresolved_unary_operations.base[unresolved_unary_operations.count - 1] = get_base_node(unary_operator);
        }

        for_bucket_item(bucket, index, parser->field_dereference_buckets)
        {
            auto field_dereference = &bucket->base[index];

            if (!field_dereference->reference)
            {
                resize_buffer(&unresolved_field_dereferences, unresolved_field_dereferences.count + 1);
                unresolved_field_dereferences.base[unresolved_field_dereferences.count - 1] = get_base_node(field_dereference);
            }
        }

        for_bucket_item(bucket, index, parser->array_index_buckets)
        {
            auto array_index = &bucket->base[index];

            resize_buffer(&unresolved_array_indices, unresolved_array_indices.count + 1);
            unresolved_array_indices.base[unresolved_array_indices.count - 1] = get_base_node(array_index);
        }

        for_bucket_item(bucket, index, parser->variable_buckets)
        {
            auto variable = &bucket->base[index];

            if (!variable->type.base_type.node)
            {
                if (variable->type.name.count)
                {
                    resize_buffer(&unresolved_types, unresolved_types.count + 1);
                    auto entry = &unresolved_types.base[unresolved_types.count - 1];
                    entry->node = get_base_node(variable);
                    entry->type = &variable->type;
                    entry->name = variable->type.name;
                }
                else if (is_node_type(variable->default_expression, number))
                {
                    // default number is either u32 or s32
                    local_node_type(number, variable->default_expression);
                    if (!number->value.type_is_fixed)
                        number->value.bit_count_power_of_two = maximum(number->value.bit_count_power_of_two, 5);

                    variable->type = get_expression_type(parser, variable->default_expression);
                    assert(variable->type.base_type.node);
                }
                else
                {
                    assert(variable->default_expression);
                    resize_buffer(&unresolved_variables, unresolved_variables.count + 1);
                    unresolved_variables.base[unresolved_variables.count - 1] = get_base_node(variable);
                }
            }
        }

        for_bucket_item(bucket, index, parser->enumeration_type_buckets)
        {
            auto enumeration_type = &bucket->base[index];

            if (!enumeration_type->item_type.base_type.node)
            {
                if (enumeration_type->item_type.name.count)
                {
                    resize_buffer(&unresolved_types, unresolved_types.count + 1);
                    auto entry = &unresolved_types.base[unresolved_types.count - 1];
                    entry->node = get_base_node(enumeration_type);
                    entry->type = &enumeration_type->item_type;
                    entry->name = enumeration_type->item_type.name;

                    resize_buffer(&unresolved_enumeration_types, unresolved_enumeration_types.count + 1);
                    unresolved_enumeration_types.base[unresolved_enumeration_types.count - 1] = get_base_node(enumeration_type);
                }
                else
                {
                    // HACK:
                    enumeration_type->item_type = get_type(parser, lang_base_type_u32);
                }
            }
        }

        for_bucket_item(bucket, index, parser->array_literal_buckets)
        {
            auto array_literal = &bucket->base[index];

            if (!array_literal->type.base_type.node)
            {
                resize_buffer(&unresolved_types, unresolved_types.count + 1);
                auto entry = &unresolved_types.base[unresolved_types.count - 1];
                entry->node = get_base_node(array_literal);
                entry->type = &array_literal->type;
                entry->name = array_literal->type.name;
            }
        }

        for_bucket_item(bucket, index, parser->compound_literal_buckets)
        {
            auto compound_literal = &bucket->base[index];

            if (!compound_literal->type.base_type.node)
            {
                resize_buffer(&unresolved_types, unresolved_types.count + 1);
                auto entry = &unresolved_types.base[unresolved_types.count - 1];
                entry->node = get_base_node(compound_literal);
                entry->type = &compound_literal->type;
                entry->name = compound_literal->type.name;
            }

            resize_buffer(&unresolved_compound_literals, unresolved_compound_literals.count + 1);
            unresolved_compound_literals.base[unresolved_compound_literals.count - 1] = get_base_node(compound_literal);
        }

        for_bucket_item(bucket, index, parser->alias_type_buckets)
        {
            auto alias_type = &bucket->base[index];

            if (!alias_type->type.base_type.node)
            {
                resize_buffer(&unresolved_types, unresolved_types.count + 1);
                auto entry = &unresolved_types.base[unresolved_types.count - 1];
                entry->node = get_base_node(alias_type);
                entry->type = &alias_type->type;
                entry->name = alias_type->type.name;
            }
        }

        for_bucket_item(bucket, index, parser->get_type_info_buckets)
        {
            auto get_type_info = &bucket->base[index];

            if (!get_type_info->type.base_type.node)
            {
                resize_buffer(&unresolved_types, unresolved_types.count + 1);
                auto entry = &unresolved_types.base[unresolved_types.count - 1];
                entry->node = get_base_node(get_type_info);
                entry->type = &get_type_info->type;
                entry->name = get_type_info->type.name;
            }
        }

        for_bucket_item(bucket, index, parser->type_byte_count_buckets)
        {
            auto type_byte_count = &bucket->base[index];

            if (!type_byte_count->type.base_type.node)
            {
                resize_buffer(&unresolved_types, unresolved_types.count + 1);
                auto entry = &unresolved_types.base[unresolved_types.count - 1];
                entry->node = get_base_node(type_byte_count);
                entry->type = &type_byte_count->type;
                entry->name = type_byte_count->type.name;
            }
        }

        for_bucket_item(bucket, index, parser->expression_reference_type_buckets)
        {
            auto expression_reference_type = &bucket->base[index];

            if (!expression_reference_type->type.base_type.node)
            {
                resize_buffer(&unresolved_expression_reference_types, unresolved_expression_reference_types.count + 1);
                unresolved_expression_reference_types.base[unresolved_expression_reference_types.count - 1] = get_base_node(expression_reference_type);
            }
        }

        for_bucket_item(bucket, index, parser->function_buckets)
        {
            auto function = &bucket->base[index];

            if (!type_is_complete(function->type))
            {
                resize_buffer(&unresolved_types, unresolved_types.count + 1);
                auto entry = &unresolved_types.base[unresolved_types.count - 1];
                entry->node = get_base_node(function);
                entry->type = &function->type;
                entry->name = function->type.name;

                // we need to also insert function arguments and return values to resolution table
                resize_buffer(&unresolved_functions, unresolved_functions.count + 1);
                unresolved_functions.base[unresolved_functions.count - 1] = get_base_node(function);
            }
        }

        for_bucket_item(bucket, index, parser->array_type_buckets)
        {
            auto array_type = &bucket->base[index];

            if (!array_type->item_type.base_type.node)
            {
                resize_buffer(&unresolved_types, unresolved_types.count + 1);
                auto entry = &unresolved_types.base[unresolved_types.count - 1];
                entry->node = get_base_node(array_type);
                entry->type = &array_type->item_type;
                entry->name = array_type->item_type.name;
            }
        }

        for_bucket_item(bucket, index, parser->unary_operator_buckets)
        {
            auto unary_operator = &bucket->base[index];

            if (unary_operator->operator_type == ast_unary_operator_type_cast)
            {
                resize_buffer(&unresolved_types, unresolved_types.count + 1);
                auto entry = &unresolved_types.base[unresolved_types.count - 1];
                entry->node = get_base_node(unary_operator);
                entry->type = &unary_operator->type;
                entry->name = unary_operator->type.name;
            }
        }

        for_bucket_item(bucket, index, parser->get_function_reference_buckets)
        {
            auto get_function_reference = &bucket->base[index];

            if (!get_function_reference->type.base_type.node)
            {
                resize_buffer(&unresolved_types, unresolved_types.count + 1);
                auto entry = &unresolved_types.base[unresolved_types.count - 1];
                entry->node = get_base_node(get_function_reference);
                entry->type = &get_function_reference->type;
                entry->name = get_function_reference->type.name;
            }

            resize_buffer(&unresolved_get_function_references, unresolved_get_function_references.count + 1);
            unresolved_get_function_references.base[unresolved_get_function_references.count - 1] = get_base_node(get_function_reference);
        }

        for_bucket_item(bucket, index, parser->scope_control_buckets)
        {
            auto scope_control = &bucket->base[index];

            if (scope_control->label.count)
            {
                resize_buffer(&unresolved_names, unresolved_names.count + 1);
                unresolved_names.base[unresolved_names.count - 1] = { get_base_node(scope_control), scope_control->label, &get_base_node(scope_control->scope) };
            }
            else
            {
                scope_control->scope = (ast_scope *) get_parent_scope(get_base_node(scope_control));

                assert(scope_control->label != s("main_loop"));

                if (scope_control->is_continue)
                {
                    bool found_loop = false;
                    while (scope_control->scope && !found_loop)
                    {
                        auto scope = get_base_node(scope_control->scope);
                        switch (scope->node_type)
                        {
                            case ast_node_type_loop:
                            case ast_node_type_loop_with_counter:
                            {
                                found_loop = true;
                            } break;

                            default:
                            {
                                scope_control->scope = (ast_scope *) get_parent_scope(scope);
                            }
                        }
                    }
                }
                else
                {
                    while (true)
                    {
                        auto scope = get_base_node(scope_control->scope);
                        if (is_node_type(scope, branch))
                        {
                            scope_control->scope = (ast_scope *) get_parent_scope(scope);
                            continue;
                        }
                        else if (is_node_type(scope, scope) && is_node_type(scope->parent, branch))
                        {
                            local_node_type(branch, scope->parent);
                            if (branch->false_scope == scope_control->scope)
                            {
                                scope_control->scope = (ast_scope *) get_parent_scope(scope->parent);
                                continue;
                            }
                        }

                        break;
                    }

                    if (is_node_type(get_base_node(scope_control->scope), branch_switch_case))
                    {
                        scope_control->scope = (ast_scope *) scope_control->scope->node.parent;
                        assert(is_node_type(get_base_node(scope_control->scope), branch_switch));
                    }
                }
            }
        }
    }

    // resolve
    {
        bool did_resolve_entry = true;
        while (did_resolve_entry)
        {
            did_resolve_entry = false;

            for (u32 i = 0; i < unresolved_names.count; i++)
            {
                auto entry = unresolved_names.base[i];
                auto reference = find_node(parser, entry.node, entry.name);
                if (reference)
                {
                    *entry.storage = reference;
                    unresolved_names.base[i] = unresolved_names.base[--unresolved_names.count];
                    resize_buffer(&unresolved_names, unresolved_names.count);
                    did_resolve_entry = true;
                    i--; // repeat index
                }
            }

            for (u32 i = 0; i < unresolved_types.count; i++)
            {
                auto entry = unresolved_types.base[i];

                if (!entry.type->name_type.node)
                {
                    auto type_node = find_node(parser, entry.node, entry.name);
                    if (type_node)
                    {
                        // found a node, that's not a type
                        if (type_node->node_type > ast_node_type_alias_type)
                        {
                            auto builder = parser_error_begin(parser, entry.name, "could not resolve '%.*s' as a type", fs(entry.name));
                            print_newline(builder);
                            print_line(builder, "closest reference '%.*s' is %.*s see:", fnode_name(type_node), fnode_type_name(type_node));
                            parser_error_location_source(parser, get_node_location(parser, type_node));
                            parser_error_end(parser);
                            return;
                        }

                        entry.type->name_type.node = type_node;
                        did_resolve_entry |= (entry.type->name_type.node != null);
                    }
                }

                if (!entry.type->base_type.node)
                {
                    resolve_complete_type(parser, entry.type);
                    did_resolve_entry |= (entry.type->base_type.node != null);
                }

                if (entry.type->base_type.node)
                {
                    unresolved_types.base[i] = unresolved_types.base[--unresolved_types.count];
                    resize_buffer(&unresolved_types, unresolved_types.count);
                    i--; // repeat index
                    did_resolve_entry = true;
                }
            }

            for (u32 i = 0; i < unresolved_variables.count; i++)
            {
                auto node = unresolved_variables.base[i];
                local_node_type(variable, node);

                auto type = get_expression_type(parser, variable->default_expression);
                if (type.base_type.node)
                {
                    variable->type = type;

                    unresolved_variables.base[i] = unresolved_variables.base[--unresolved_variables.count];
                    resize_buffer(&unresolved_variables, unresolved_variables.count);
                    did_resolve_entry = true;
                    i--; // repeat index
                }
            }

            for (u32 i = 0; i < unresolved_enumeration_types.count; i++)
            {
                auto node = unresolved_enumeration_types.base[i];
                local_node_type(enumeration_type, node);

                if (enumeration_type->item_type.base_type.node)
                {
                    lang_require_return_value(is_node_type(enumeration_type->item_type.base_type.node, number_type) || is_node_type(enumeration_type->item_type.base_type.node, enumeration_type), , get_node_location(parser, node), "enumeration type must be a integer type or another enumeration type");

                    if (is_node_type(enumeration_type->item_type.base_type.node, number_type))
                    {
                        local_node_type(number_type, enumeration_type->item_type.base_type.node);
                        lang_require_return_value(!number_type->is_float, , get_node_location(parser, node), "enumeration type must be a integer type or another enumeration type");
                    }
                    else if (is_node_type(enumeration_type->item_type.base_type.node, enumeration_type))
                    {
                        auto other_enumeration_type = get_node_type(enumeration_type, enumeration_type->item_type.base_type.node);

                        if (!other_enumeration_type->item_type.base_type.node)
                            continue;

                        enumeration_type->item_count += other_enumeration_type->item_count;

                        // take the last value + 1 as offset for inheriting enumeration type
                        parsed_number item_offset = {};
                        for (auto item = other_enumeration_type->first_item; item; item = (ast_enumeration_item *) item->node.next)
                        {
                            auto ok = evaluate(&item_offset, item->expression);
                            assert(ok);
                        }

                        item_offset.u64_value += 1;

                        for (auto item = enumeration_type->first_item; item; item = (ast_enumeration_item *) item->node.next)
                        {
                            auto expression = item->expression;

                            switch (expression->node_type)
                            {
                                case ast_node_type_number:
                                {
                                    local_node_type(number, expression);
                                    assert(!number->value.is_float);
                                    number->value.u64_value += item_offset.u64_value;
                                    continue;
                                } break;

                                case ast_node_type_binary_operator:
                                {
                                    local_node_type(binary_operator, expression);

                                    if (binary_operator->operator_type != ast_binary_operator_type_add)
                                        break;

                                    auto right = binary_operator->left->next;
                                    if (!is_node_type(right, number))
                                        break;

                                    local_node_type(number, expression);
                                    assert(!number->value.is_float);

                                    number->value.u64_value += item_offset.u64_value;
                                    continue;
                                } break;
                            }

                            new_local_node(binary_operator, item->name);
                            binary_operator->operator_type = ast_binary_operator_type_add;

                            binary_operator->left = expression;
                            binary_operator->left->next = get_base_node(new_number_u64(parser, item->name, item_offset.u64_value, get_base_node(binary_operator)));

                            binary_operator->left->parent = get_base_node(binary_operator);

                            item->expression = get_base_node(binary_operator);
                            item->expression->parent = get_base_node(item);
                        }
                    }

                    unresolved_enumeration_types.base[i] = unresolved_enumeration_types.base[--unresolved_enumeration_types.count];
                    resize_buffer(&unresolved_enumeration_types, unresolved_enumeration_types.count);
                    did_resolve_entry = true;
                    i--; // repeat index
                }
            }

            for (u32 i = 0; i < unresolved_compound_literals.count; i++)
            {
                auto node = unresolved_compound_literals.base[i];
                local_node_type(compound_literal, node);

                if (!compound_literal->type.base_type.node)
                    continue;

                bool is_complete = true;
                for (auto argument = compound_literal->first_argument; argument; argument = (ast_argument *) argument->node.next)
                {
                    auto type = get_expression_type(parser, argument->expression);
                    if (!type_is_complete(type))
                    {
                        is_complete = false;
                        break;
                    }
                }

                if (!is_complete)
                    continue;

                auto arguments = &compound_literal->first_argument;
                auto result = arguments_are_compatible(parser, compound_literal);
                if (!result.compatibility)
                {
                    auto builder = parser_error_begin(parser, get_node_location(parser, node));
                    print_incompatible_arguments_error(parser, builder, result);
                    parser_error_end(parser);
                    return;
                }

                consume_arguments(parser, compound_literal);

                unresolved_compound_literals.base[i] = unresolved_compound_literals.base[--unresolved_compound_literals.count];
                resize_buffer(&unresolved_compound_literals, unresolved_compound_literals.count);
                did_resolve_entry = true;
                i--; // repeat index
            }

            for (u32 i = 0; i < unresolved_functions.count; i++)
            {
                auto node = unresolved_functions.base[i];
                local_node_type(function, node);

                if (type_is_complete(function->type))
                {
                    lang_require_call_return_value(insert_function_arguments_and_results(parser, function), );

                    unresolved_functions.base[i] = unresolved_functions.base[--unresolved_functions.count];
                    resize_buffer(&unresolved_functions, unresolved_functions.count);
                    did_resolve_entry = true;
                    i--; // repeat index
                }
            }

            for (u32 i = 0; i < unresolved_expression_reference_types.count; i++)
            {
                auto node = unresolved_expression_reference_types.base[i];
                local_node_type(expression_reference_type, node);

                auto type = get_expression_type(parser, expression_reference_type->expression);
                if (type.base_type.node)
                {
                    expression_reference_type->type = type;

                    unresolved_expression_reference_types.base[i] = unresolved_expression_reference_types.base[--unresolved_expression_reference_types.count];
                    resize_buffer(&unresolved_expression_reference_types, unresolved_expression_reference_types.count);
                    did_resolve_entry = true;
                    i--; // repeat index
                }
            }

            for (u32 i = 0; i < unresolved_field_dereferences.count; i++)
            {
                auto node = unresolved_field_dereferences.base[i];
                local_node_type(field_dereference, node);

                lang_complete_type expression_type = get_expression_type(parser, field_dereference->expression);
                if (!type_is_not_empty(expression_type))
                {
                    lang_require_return_value(expression_type.base_type.node, , field_dereference->name, "can not dereference return value field '%.*s', function has no return value", fs(field_dereference->name));
                }

                if (expression_type.base_type.node)
                {
                    auto base_type = expression_type.base_type.node;
                    if (base_type)
                        lang_require_call_return_value(resolve_field_dereference(parser, field_dereference, expression_type), );

                    if (field_dereference->reference)
                    {
                        unresolved_field_dereferences.base[i] = unresolved_field_dereferences.base[--unresolved_field_dereferences.count];
                        resize_buffer(&unresolved_field_dereferences, unresolved_field_dereferences.count);
                        did_resolve_entry = true;
                        i--; // repeat index
                    }
                }
            }

            for (u32 i = 0; i < unresolved_array_indices.count; i++)
            {
                auto node = unresolved_array_indices.base[i];
                local_node_type(array_index, node);

                auto expression_type = get_expression_type(parser, array_index->array_expression);
                if (expression_type.base_type.node && try_resolve_expand_array_index(parser, array_index, expression_type))
                    expression_type = get_expression_type(parser, array_index->array_expression);

                if (expression_type.base_type.node && is_node_type(expression_type.base_type.node, array_type))
                {

                    unresolved_array_indices.base[i] = unresolved_array_indices.base[--unresolved_array_indices.count];
                    resize_buffer(&unresolved_array_indices, unresolved_array_indices.count);
                    did_resolve_entry = true;
                    i--; // repeat index
                }
            }

            for (u32 i = 0; i < unresolved_unary_operations.count; i++)
            {
                auto node = unresolved_unary_operations.base[i];
                local_node_type(unary_operator, node);

                assert(!unary_operator->expression->next);

                auto function_name = ast_unary_operator_names[unary_operator->operator_type];

                ast_argument argument = {};
                argument.node.parent = get_base_node(unary_operator);
                argument.node.node_type = ast_node_type_argument;
                argument.expression = unary_operator->expression;

                auto arguments = &argument;
                auto function = lang_require_call_return_value(resolve_function_overload(parser, node, function_name, get_base_node(unary_operator), &arguments), );
                if (function)
                {
                    assert(&argument == arguments);
                    //unary_operator->expression = arguments->expression;
                    //unary_operator->expression->parent = get_base_node(unary_operator);

                    unary_operator->function = function;

                    unresolved_unary_operations.base[i] = unresolved_unary_operations.base[--unresolved_unary_operations.count];
                    resize_buffer(&unresolved_unary_operations, unresolved_unary_operations.count);
                    did_resolve_entry = true;
                    i--; // repeat index
                }
            }

            for (u32 i = 0; i < unresolved_binary_operations.count; i++)
            {
                auto node = unresolved_binary_operations.base[i];
                local_node_type(binary_operator, node);

                assert(binary_operator->left->next && !binary_operator->left->next->next);

                ast_argument arguments[2] = {};
                arguments[0].node.parent = get_base_node(binary_operator);
                arguments[0].node.node_type = ast_node_type_argument;
                arguments[0].expression = binary_operator->left;
                arguments[1].node.parent = get_base_node(binary_operator);
                arguments[1].node.node_type = ast_node_type_argument;
                arguments[1].expression = binary_operator->left->next;
                arguments[0].node.next = get_base_node(&arguments[1]);

                auto first_argument = &arguments[0];

                auto function_name = ast_binary_operator_names[binary_operator->operator_type];
                auto function = lang_require_call_return_value(resolve_function_overload(parser, node, function_name, get_base_node(binary_operator), &first_argument), );
                if (function)
                {
                    assert(first_argument == &arguments[0]);
                    assert(first_argument->node.next == get_base_node(&arguments[1]));

                    binary_operator->function = function;

                    unresolved_binary_operations.base[i] = unresolved_binary_operations.base[--unresolved_binary_operations.count];
                    resize_buffer(&unresolved_binary_operations, unresolved_binary_operations.count);
                    did_resolve_entry = true;
                    i--; // repeat index
                }
            }

            for (u32 i = 0; i < unresolved_get_function_references.count; i++)
            {
                auto node = unresolved_get_function_references.base[i];
                local_node_type(get_function_reference, node);

                if (!get_function_reference->type.base_type.node)
                    continue;

                local_node_type(function_type, get_function_reference->type.base_type.node);

                auto matching_function = lang_require_call_return_value(resolve_function_reference(parser, node, get_function_reference->name, function_type), );
                if (matching_function)
                {
                    get_function_reference->function = matching_function;

                    unresolved_get_function_references.base[i] = unresolved_get_function_references.base[--unresolved_get_function_references.count];
                    resize_buffer(&unresolved_get_function_references, unresolved_get_function_references.count);
                    did_resolve_entry = true;
                    i--; // repeat index
                }
            }

            for (u32 i = 0; i < unresolved_function_calls.count; i++)
            {
                auto node = unresolved_function_calls.base[i];
                local_node_type(function_call, node);

                if (is_node_type(function_call->expression, name_reference))
                {
                    local_node_type(name_reference, function_call->expression);

                    auto function = lang_require_call_return_value(resolve_function_overload(parser, node, name_reference->name, get_base_node(function_call), &function_call->first_argument), );
                    if (function)
                        name_reference->reference = get_base_node(function);
                }

                auto type = get_expression_type(parser, function_call->expression);

                if (!type.base_type.node)
                    continue;

                lang_require_return_value(!type.base_type.indirection_count && is_node_type(type.base_type.node, function_type), , parser->node_locations.base[function_call->node.index].text, "expected function call expression to be of function_type without indirection, but type is %.*s (ref %i)", fnode_type_name(type.base_type.node), type.base_type.indirection_count);

#if 1
                bool is_complete = true;
                for (auto argument = function_call->first_argument; argument; argument = (ast_argument *) argument->node.next)
                {
                    auto type = get_expression_type(parser, argument->expression);
                    if (!type_is_complete(type))
                    {
                        is_complete = false;
                        break;
                    }
                }

                if (!is_complete)
                    continue;
#endif

                local_node_type(function_type, type.base_type.node);

                // function call does not always call a function directly, so we need to check compatibility
                auto result = arguments_are_compatible(parser, function_type, function_call->first_argument);
                if (!result.compatibility)
                {
                    auto builder = parser_error_begin(parser, get_node_location(parser, node));
                    print_incompatible_arguments_error(parser, builder, result);
                    parser_error_end(parser);
                    return;
                }

                consume_arguments(parser, function_type, get_base_node(function_call), &function_call->first_argument);

                unresolved_function_calls.base[i] = unresolved_function_calls.base[--unresolved_function_calls.count];
                resize_buffer(&unresolved_function_calls, unresolved_function_calls.count);
                did_resolve_entry = true;
                i--; // repeat index
            }
        }
    }

    // semantic checks
    {
        for (u32 i = 0; i < unresolved_types.count; i++)
        {
            auto type = *unresolved_types.base[i].type;

            assert(type.name.count);

            auto builder = parser_error_begin(parser, type.name, "no type '%.*s' found", fs(type.name));

            for (auto module = parser->module_list.first; module; module = (ast_module *) module->node.next)
            {
                auto node = get_node(resolve_table, type.name, get_base_node(module));
                if (node && is_node_type(node, alias_type))
                {
                    local_node_type(alias_type, node);
                    print_newline(builder);
                    print_line(builder, "could be: %.*s (import %.*s)", fs(type.name), fs(module->name));
                    parser_error_location_source(parser, alias_type->name);
                }
            }

            parser_error_end(parser);
            return;
        }

        for (u32 i = 0; i < unresolved_variables.count; i++)
        {
            auto node = unresolved_variables.base[i];
            local_node_type(variable, node);

            if (!variable->type.base_type.node)
            {
                auto type = get_expression_type(parser, variable->default_expression);
                if (type.base_type.node)
                {
                    parser_error_return(parser, parser->node_locations.base[variable->node.index].text, "could not infere variable type");
                }
            }
        }

        for (u32 i = 0; i < unresolved_field_dereferences.count; i++)
        {
            auto node = unresolved_field_dereferences.base[i];
            local_node_type(field_dereference, node);

            auto type = get_expression_type(parser, field_dereference->expression);
            if (type.base_type.node)
            {
                auto builder = parser_error_begin(parser, field_dereference->name);
                print(builder, "type ");
                print_type(parser, builder, type);
                print(builder, " has no field '%.*s'", fs(field_dereference->name));
                parser_error_location_source(parser, field_dereference->name);
                parser_error_end(parser);
                return;
            }
        }

        for (u32 i = 0; i < unresolved_function_calls.count; i++)
        {
            auto node = unresolved_function_calls.base[i];
            local_node_type(function_call, node);

            local_node_type(name_reference, function_call->expression);

            bool is_incomplete = false;
            for (auto call_argument = function_call->first_argument; call_argument; call_argument = (ast_argument *) call_argument->node.next)
            {
                auto type = get_expression_type(parser, call_argument->expression);
                if (!type_is_complete(type))
                {
                    is_incomplete = true;
                    break;
                }
            }

            {
                auto iterator = find_matching_function_begin(node, name_reference->name);

                ast_function_overloads *function_overloads;
                while (!is_incomplete && find_matching_function_next(&function_overloads, parser, &iterator))
                {
                    for (auto function_reference = function_overloads->first_function_reference; function_reference; function_reference = (ast_function_reference *) function_reference->node.next)
                    {
                        auto function = function_reference->function;
                        local_node_type(function_type, function->type.base_type.node);

                        if (!type_is_complete(function->type))
                        {
                            is_incomplete = true;
                            break;
                        }
                    }
                }
            }

            // only error on function with complete types
            if (is_incomplete)
                continue;

            auto builder = parser_error_begin(parser, parser->node_locations.base[function_call->node.index].text, "no matching function overload found");

            print_newline(builder);
            print_line(builder, "for function call:");
            builder->indent++;

            print_line(builder, "%.*s", fs(parser->node_locations.base[function_call->node.index].text));
            builder->indent--;

            print_newline(builder);
            print(builder, "with argument types: ");
            print_call_argument_types(parser, builder, function_call);
            print_newline(builder);

            bool first_function = true;

            auto iterator = find_matching_function_begin(node, name_reference->name);

            ast_function_overloads *function_overloads;
            while (find_matching_function_next(&function_overloads, parser, &iterator))
            {
                if (first_function)
                {
                    print_newline(builder);
                    print_line(builder, "possible functions are:");
                    print_newline(builder);
                    builder->indent++;

                    first_function = false;
                }

                for (auto function_reference = function_overloads->first_function_reference; function_reference; function_reference = (ast_function_reference *) function_reference->node.next)
                {
                    auto function = function_reference->function;
                    local_node_type(function_type, function->type.base_type.node);

                    if (!type_is_complete(function->type))
                    {
                        print_line(builder, "%.*s func%.*s type was not completly resolved", fs(function->name), fs(parser->node_locations.base[function_type->node.index].text));
                        break;
                    }

                    // print whole token
                    print_line(builder, "%.*s func%.*s", fs(function->name), fs(parser->node_locations.base[function_type->node.index].text));

                    auto result = arguments_are_compatible(parser, function_type, function_call->first_argument);
                    if (!result.compatibility)
                        print_incompatible_arguments_error(parser, builder, result);

                    print_newline(builder);
                }
            }

            if (first_function)
            {
                print_line(builder, "no functions called '%.*s' found.", fs(name_reference->name));

                print_newline(builder);

                for (auto module = parser->module_list.first; module; module = (ast_module *) module->node.next)
                {
                    auto function_overloads = (ast_function_overloads *) get_node(resolve_table, name_reference->name, get_base_node(module));

                    if (function_overloads && is_node_type(get_base_node(function_overloads), function_overloads))
                    {
                        for (auto it = function_overloads->first_function_reference; it; it = (ast_function_reference *) it->node.next)
                        {
                            auto function = it->function;

                            local_node_type(function_type, function->type.base_type.node);
                            print_newline(builder);
                            print_line(builder, "could be: %.*s (import %.*s)", fs(function->name), fs(module->name));
                            parser_error_location_source(parser, function->name);
                        }
                    }
                }

            }
            else
                builder->indent--;

            parser_error_end(parser);
            return;
        }

        for_bucket_item(bucket, index, parser->name_reference_buckets)
        {
            auto name_reference = &bucket->base[index];

            if (!name_reference->reference)
            {
                auto node = get_base_node(name_reference);

                // function call expressions, will be handled in function calls
                if (is_node_type(node->parent, function_call))
                {
                    local_node_type(function_call, node->parent);
                    if (function_call->expression == node)
                        continue;
                }

                auto builder = parser_error_begin(parser, name_reference->name, "could not find name '%.*s'", fs(name_reference->name));

                for (auto module = parser->module_list.first; module; module = (ast_module *) module->node.next)
                {
                    auto node = get_node(resolve_table, name_reference->name, get_base_node(module));
                    if (node && !is_node_type(node, function_overloads))
                    {
                        print_newline(builder);
                        print_line(builder, "could be: %.*s %.*s (import %.*s)", fs(name_reference->name), fnode_type_name(node), fs(module->name));
                        parser_error_location_source(parser, get_name(node));
                    }
                }

                parser_error_end(parser);
                return;
            }
        }

        for_bucket_item(bucket, index, parser->assignment_buckets)
        {
            auto assignment = &bucket->base[index];

            auto left_type  = get_expression_type(parser, assignment->left);
            auto right_type = get_expression_type(parser, assignment->right);

            if (!type_is_complete(left_type))
                continue;

            if (!type_is_complete(right_type))
                continue;

            auto compatibility = types_are_compatible(parser, left_type, right_type);
            maybe_add_cast(parser, &assignment->right, compatibility, left_type);

            if (compatibility == type_compatibility_false)
            {
                parser_error_types_are_incompatible(parser, get_base_node(assignment), left_type, right_type);
                return;
            }
        }


        for_bucket_item(bucket, index, parser->variable_buckets)
        {
            auto variable = &bucket->base[index];

            if (!variable->default_expression)
            {
                if (!variable->type.base_type.node)
                    parser_error_return(parser, variable->type.name, "could not resolve variable type");

                continue;
            }

            auto left_type  = variable->type;
            auto right_type = get_expression_type(parser, variable->default_expression);

            if (!type_is_complete(left_type) || !type_is_complete(right_type))
                continue;

            auto compatibility = types_are_compatible(parser, left_type, right_type);
            maybe_add_cast(parser, &variable->default_expression, compatibility, left_type);

            if (compatibility == type_compatibility_false)
            {
                parser_error_types_are_incompatible(parser, get_base_node(variable), left_type, right_type);
                return;
            }
        }

        for_bucket_item(bucket, index, parser->array_literal_buckets)
        {
            auto array_literal = &bucket->base[index];
            auto type = array_literal->type;
            if (!type.base_type.node)
                continue;

            type = try_resolve_expand_array_literal(type);

            lang_require_return_value(is_node_type(type.base_type.node, array_type), , parser->node_locations.base[array_literal->node.index].text, "array literal type must be array, but is '%.*s'", fnode_type_name(type.base_type.node));

            local_node_type(array_type, type.base_type.node);
            array_literal->array_type = array_type;

            auto item_type = array_type->item_type;
            if (!item_type.base_type.node)
                continue;

            for (auto it = array_literal->first_argument; it; it = (ast_argument *) it->node.next)
            {
                auto type = get_expression_type(parser, it->expression);
                if (!type.base_type.node)
                    break;

                //lang_require_return_value(type.base_type.node, , parser->node_locations.base[it->node.index].text, "array literal item type is not resolved");

                auto compatibility = types_are_compatible(parser, item_type, type);

                if (!compatibility)
                {
                    parser_error_types_are_incompatible(parser, get_base_node(it), item_type, type);
                    return;
                }

                // TODO: maybe we need to keap track of next pointer
                maybe_add_cast(parser, &it->expression, compatibility, item_type);
            }
        }

        {
            auto assert_array_bounds_function = parser->base_functions[lang_base_function_lang_assert_array_bounds];
            auto usize_type = get_type(parser, lang_base_type_usize);

            for_bucket_item(bucket, index, parser->array_index_buckets)
            {
                auto array_index = &bucket->base[index];

                auto expression_type = get_expression_type(parser, array_index->array_expression);
                auto base_type = expression_type.base_type.node;
                lang_require_return_value(base_type, , parser->node_locations.base[array_index->array_expression->index].text, "can't index expression of unkown type");

                lang_require_return_value(is_node_type(base_type, array_type), , parser->node_locations.base[array_index->array_expression->index].text, "can't index expression of type '%.*s'", fnode_type_name(base_type));
                local_node_type(array_type, base_type);

                // array is constant
                u64 index_value;
                if (array_type->item_count_expression && get_array_index_value(&index_value, array_index))
                {
                    auto item_count = get_array_item_count(array_type);
                    lang_require_return_value(index_value < item_count, , parser->node_locations.base[array_index->array_expression->index].text, "array index %llu is out of bounds, should be less then array item count %llu", index_value, item_count);
                }
            }
        }

        for_bucket_item(bucket, index, parser->array_type_buckets)
        {
            auto array_type = &bucket->base[index];

            lang_require_return_value(array_type->item_type.base_type.node, , parser->node_locations.base[array_type->node.index].text, "could not resolve array type");

            parsed_number ignored;
            lang_require_return_value(!array_type->item_count_expression || evaluate(&ignored, array_type->item_count_expression), , parser->node_locations.base[array_type->item_count_expression->index].text, "array count is not constant");
        }

        for_bucket_item(bucket, index, parser->array_literal_buckets)
        {
            auto array_literal = &bucket->base[index];

            lang_require_return_value(array_literal->type.base_type.node, , get_node_location(parser, get_base_node(array_literal)), "could not resolve array literal type");
        }

        for_bucket_item(bucket, index, parser->compound_literal_buckets)
        {
            auto compound_literal = &bucket->base[index];

            lang_require_return_value(compound_literal->type.base_type.node, , get_node_location(parser, get_base_node(compound_literal)), "could not resolve compound literal type");
        }

        for_bucket_item(bucket, index, parser->type_byte_count_buckets)
        {
            auto type_byte_count = &bucket->base[index];

            lang_require_return_value(type_byte_count->type.base_type.node, , get_node_location(parser, get_base_node(type_byte_count)), "could not resolve type");
        }

        for_bucket_item(bucket, index, parser->binary_operator_buckets)
        {
            auto binary_operator = &bucket->base[index];

            auto type = get_expression_type(parser, get_base_node(binary_operator));
            if (!type.base_type.node)
            {
                auto left_type  = get_expression_type(parser, binary_operator->left);
                auto right_type = get_expression_type(parser, binary_operator->left->next);

                if (!left_type.base_type.node || !right_type.base_type.node)
                    continue;

                auto builder = parser_error_begin(parser, parser->node_locations.base[binary_operator->node.index].text, "argument types of binary operation '%.*s' are not compatible", fs(ast_binary_operator_names[binary_operator->operator_type]));

                print_newline(builder);
                print(builder, "    left expression of type ");
                print_type(parser, builder, left_type);
                print(builder, " not compatible with right expression of type ");
                print_type(parser, builder, right_type);

                print_newline(builder);
                parser_error_end(parser);
                return;
            }
        }

        for_bucket_item(bucket, index, parser->get_function_reference_buckets)
        {
            auto get_function_reference = &bucket->base[index];
            if (!get_function_reference->function)
                parser_error_return(parser, parser->node_locations.base[get_function_reference->node.index].text, "couldn't find function '%.*s'", fs(get_function_reference->name));
        }

        for_bucket_item(bucket, index, parser->function_call_buckets)
        {
            auto function_call = &bucket->base[index];

            auto type = get_expression_type(parser, function_call->expression);
            if (!type_is_complete(type))
                continue;

            if (!is_node_type(type.base_type.node, function_type) || (type.base_type.indirection_count > 1))
            {
                auto builder = parser_error_begin(parser, parser->node_locations.base[function_call->node.index].text, "function call expression must be of function type or function type ref, but is");
                print(builder, "    with argument types:");
                print_call_argument_types(parser,builder, function_call);
                print_newline(builder);
                print_newline(builder);
                print_line(builder, "    call expression type is: %.*s", fs(get_node_location(parser, type.base_type.node)));
                parser_error_end(parser);
                return;
            }
        }

        for_bucket_item(bucket, index, parser->dereference_buckets)
        {
            auto dereference = &bucket->base[index];

            auto type = get_expression_type(parser, dereference->expression);
            if (!type.base_type.indirection_count)
                parser_error_return(parser, get_node_location(parser, dereference->expression), "can not dereference expression of none reference type");

        }

        for_bucket_item(bucket, index, parser->alias_type_buckets)
        {
            auto alias_type = &bucket->base[index];

            auto type = to_type(parser, get_base_node(alias_type));
            auto result = type_contains_other(type, type);
            if (result)
            {
                auto builder = parser_error_begin(parser, parser->node_locations.base[alias_type->node.index].text, "type definition contains itself and results in infinite recursion");
                print_newline(builder);
                print(builder, "    here:");
                print_newline(builder);
                parser_error_location_source(parser, result->name);
                parser_error_end(parser);
                return;
            }
        }

        {
            auto b8_type = get_type(parser, lang_base_type_b8);
            for_bucket_item(bucket, index, parser->branch_buckets)
            {
                auto branch = &bucket->base[index];

                auto type = get_expression_type(parser, branch->condition);
                if (!type_is_complete(type))
                    continue;

                auto compatibility = types_are_compatible(parser, b8_type, type);
                if (compatibility == type_compatibility_false)
                    parser_error_return(parser, get_node_location(parser, branch->condition), "branch condition is not a b8 or can not be implicitly cast to b8");

                maybe_add_cast(parser, &branch->condition, compatibility, b8_type);
            }

            for_bucket_item(bucket, index, parser->loop_buckets)
            {
                auto loop = &bucket->base[index];

                auto type = get_expression_type(parser, loop->condition);

                auto compatibility = types_are_compatible(parser, b8_type, type);
                if (compatibility == type_compatibility_false)
                    parser_error_return(parser, get_node_location(parser, loop->condition), "loop condition is not a b8 or can not be implicitly cast to b8");

                maybe_add_cast(parser, &loop->condition, compatibility, b8_type);
            }
        }

        for_bucket_item(bucket, index, parser->scope_control_buckets)
        {
            auto scope_control = &bucket->base[index];

            auto name = ast_scope_control_names[scope_control->is_continue];

            if (!scope_control->scope)
            {
                parser_error_return(parser, get_node_location(parser, get_base_node(scope_control)), "%.*s scope was not found", fs(name));
            }
            else
            {
                bool ok = false;
                if (scope_control->is_continue)
                {
                    switch (scope_control->scope->node.node_type)
                    {
                        case ast_node_type_loop:
                        case ast_node_type_loop_with_counter:
                        {
                            ok = true;
                        } break;
                    }
                }
                else
                {
                    switch (scope_control->scope->node.node_type)
                    {
                        case ast_node_type_scope:
                        //case ast_node_type_branch:
                        case ast_node_type_loop:
                        case ast_node_type_loop_with_counter:
                        case ast_node_type_branch_switch:
                        {
                            ok = true;
                        } break;
                    }
                }

                if (!ok)
                {
                    parser_error_return(parser, get_node_location(parser, get_base_node(scope_control)), "%.*s has no proper enclosing scope, parent scope '%.*s' is not allowed", fs(name), fnode_type_name(get_base_node(scope_control->scope)));
                }
            }

            bool requires_label = scope_control_requires_label(scope_control);

            if (scope_control->is_continue)
                scope_control->scope->requires_begin_label = requires_label;
            else
                scope_control->scope->requires_end_label = requires_label;
        }

        for_bucket_item(bucket, index, parser->unary_operator_buckets)
        {
            auto unary_operator = &bucket->base[index];

            // TODO: separate casts to own ast type
            switch (unary_operator->operator_type)
            {
                case ast_unary_operator_type_cast:
                {
                    auto type = get_expression_type(parser, unary_operator->expression);
                    auto compatibility = types_are_compatible(parser, unary_operator->type, type);
                    if (!compatibility)
                    {
                        // allow arbitrary casts between reference, number and enumeration types
                        bool left_ok = unary_operator->type.base_type.indirection_count || is_node_type(unary_operator->type.base_type.node, number_type) || is_node_type(unary_operator->type.base_type.node, enumeration_type);
                        bool right_ok = type.base_type.indirection_count || is_node_type(type.base_type.node, number_type) || is_node_type(type.base_type.node, enumeration_type);

                        if (left_ok && right_ok)
                            compatibility = type_compatibility_requires_cast;
                    }

                    if (!compatibility)
                    {
                        parser_error_types_are_incompatible(parser, get_base_node(unary_operator), unary_operator->type, type);
                        return;
                    }
                } break;
            }
        }


        for_bucket_item(bucket, index, parser->get_type_info_buckets)
        {
            auto get_type_info = &bucket->base[index];
            if (!get_type_info->type.base_type.node)
            {
                parser_error_return(parser, parser->node_locations.base[get_type_info->node.index].text, "couldn't resolve type in get_type_info");
            }
        }

        // should have returned
        assert(!parser->error);
    }

    // optimization
    {
        // remove dead branches
        for_bucket_item(bucket, index, parser->branch_buckets)
        {
            auto branch = &bucket->base[index];
            auto branch_node = get_base_node(branch);

            parsed_number value;
            if (evaluate(&value, branch->condition) && !value.is_float)
            {
                auto parent = branch->node.parent;

                local_buffer(queue, ast_queue);
                enqueue_one(&queue, &parent);

                bool found;
                ast_queue_entry entry;
                while (next(&entry, &queue))
                {
                    if (*entry.node_field == branch_node)
                    {
                        ast_scope *scope;
                        if (value.u64_value)
                        {
                            new_local_named_node(new_scope, scope, get_node_location(parser, branch_node));
                            scope = new_scope;
                            scope->first_statement = branch->scope.first_statement;

                            for (auto it = scope->first_statement; it; it = it->next)
                                it->parent = get_base_node(scope);
                        }
                        else
                        {
                            scope = branch->false_scope;
                        }

                        if (scope)
                        {
                            auto node = scope->node;
                            auto first_statement = scope->first_statement;
                            *scope = branch->scope;
                            scope->node = node;
                            scope->first_statement = first_statement;

                            scope->node.parent = branch_node->parent;
                            scope->node.next = (*entry.node_field)->next;
                            *entry.node_field = get_base_node(scope);
                        }
                        else
                        {
                            // skip node
                            *entry.node_field = (*entry.node_field)->next;
                        }

                        branch->scope.first_statement = null;
                        branch->false_scope = null;
                        found = true;
                        break;
                    }
                }

                assert(found);

                // NOTE:
                // we can't just remove it from the buckets, since pointers are not allowed to move
                //bucket->base[index] = bucket->base[--bucket->count];
                //index--; // repeat bucket index
                //continue;
            }
        }

        // remove empty scopes
        {
            bool was_resolved = true;
            while (was_resolved)
            {
                was_resolved = false;

                for_bucket_item(bucket, index, parser->scope_buckets)
                {
                    auto scope = &bucket->base[index];
                    auto scope_node = get_base_node(scope);

                    if (!scope->first_statement)
                    {
                        auto parent = scope_node->parent;

                        local_buffer(queue, ast_queue);
                        enqueue_one(&queue, &parent);

                        bool found = false;
                        ast_queue_entry entry;
                        while (next(&entry, &queue))
                        {
                            if (*entry.node_field == scope_node)
                            {
                                // skip node
                                *entry.node_field = (*entry.node_field)->next;
                                found = true;
                                break;
                            }
                        }

                        // might not be found, because its parent was allready removed
                        was_resolved |= found;
                    }
                }

                // remove empty function calls
                for_bucket_item(bucket, index, parser->function_call_buckets)
                {
                    auto function_call = &bucket->base[index];
                    auto function_call_node = get_base_node(function_call);

                    if (is_node_type(function_call->expression, name_reference))
                    {
                        local_node_type(name_reference, function_call->expression);

                        if (is_node_type(name_reference->reference, function))
                        {
                            local_node_type(function, name_reference->reference);
                            if (!function->first_statement)
                            {
                                auto parent = function_call_node->parent;

                                local_buffer(queue, ast_queue);
                                enqueue_one(&queue, &parent);

                                bool found = false;
                                ast_queue_entry entry;
                                while (next(&entry, &queue))
                                {
                                    if (*entry.node_field == function_call_node)
                                    {
                                        // skip node
                                        *entry.node_field = (*entry.node_field)->next;
                                        found = true;
                                        break;
                                    }
                                }

                                // might not be found, because its parent was allready removed
                                was_resolved |= found;
                            }
                        }
                    }
                }
            }
        }

        collect_required_nodes_and_unique_types(parser);

        // add array bound checks
        {
            auto assert_array_bounds_function = parser->base_functions[lang_base_function_lang_assert_array_bounds];
            auto usize_type = get_type(parser, lang_base_type_usize);

            for_bucket_item(bucket, index, parser->array_index_buckets)
            {
                auto array_index = &bucket->base[index];

                auto base_type = get_expression_type(parser, array_index->array_expression).base_type.node;
                local_node_type(array_type, base_type);

                // insert array bounds check
                u64 index_value;
                if (!array_type->item_count_expression || !get_array_index_value(&index_value, array_index))
                {
                    bool requires_array_bounds_check = true;

                    // check if array index is loop variable and array.count is loop condition
                    if (is_node_type(array_index->array_expression, name_reference) && is_node_type(array_index->index_expression, name_reference))
                    {
                        auto array_reference = get_node_type(name_reference, array_index->array_expression);
                        auto index_reference = get_node_type(name_reference, array_index->index_expression);

                        auto parent = get_base_node(array_index);
                        while (parent)
                        {
                            parent = parent->parent;

                            while (parent && !is_node_type(parent, loop_with_counter))
                            {
                                parent = parent->parent;
                            }

                            if (parent)
                            {
                                local_node_type(loop_with_counter, parent);

                                if (is_node_type(loop_with_counter->counter_statement, variable))
                                {
                                    if (loop_with_counter->counter_statement != index_reference->reference)
                                        continue;
                                }
                                else if (is_node_type(loop_with_counter->counter_statement, name_reference))
                                {
                                    local_node_type(name_reference, loop_with_counter->counter_statement);
                                    if (name_reference->reference != index_reference->reference)
                                        continue;
                                }
                                else
                                {
                                    continue;
                                }

                                if (!is_node_type(loop_with_counter->end_condition, field_dereference))
                                    continue;

                                local_node_type(field_dereference, loop_with_counter->end_condition);

                                if ((field_dereference->name != s("count")) || !is_node_type(field_dereference->expression, name_reference))
                                    continue;

                                auto field_array_reference = get_node_type(name_reference, field_dereference->expression);
                                if (field_array_reference->reference != array_reference->reference)
                                    continue;

                                requires_array_bounds_check = false;
                                parent = null;
                                break;
                            }
                        }
                    }

                    if (!requires_array_bounds_check)
                        continue;

                    auto location_text = get_node_location(parser, get_base_node(array_index));

                    new_local_node(function_call, location_text);

                    {
                        new_local_node(name_reference);
                        name_reference->name = assert_array_bounds_function->name;
                        name_reference->reference = get_base_node(assert_array_bounds_function);
                        function_call->expression = get_base_node(name_reference);
                    }

                    {
                        new_local_node(argument, location_text);
                        argument->name = s("index");

                        auto index_type = get_expression_type(parser, array_index->index_expression);
                        auto compatibility = types_are_compatible(parser, usize_type, index_type);
                        if (compatibility == type_compatibility_false)
                        {
                            new_local_leaf_node(unary_operator, location_text);
                            unary_operator->operator_type = ast_unary_operator_type_cast;
                            unary_operator->type = usize_type;
                            unary_operator->expression = array_index->index_expression;
                            unary_operator->expression->parent = get_base_node(unary_operator);

                            argument->expression = get_base_node(unary_operator);
                        }
                        else
                        {
                            argument->expression = array_index->index_expression;
                            argument->expression->parent = get_base_node(argument);

                            maybe_add_cast(parser, &argument->expression, compatibility, usize_type);
                        }

                        function_call->first_argument = argument;
                        argument->node.parent = get_base_node(function_call);
                    }

                    {
                        new_local_node(argument, location_text);
                        argument->name = s("count");

                        if (array_type->item_count_expression)
                        {
                            argument->expression = get_base_node(new_number_u64(parser, location_text, get_array_item_count(array_type), get_base_node(argument)));
                        }
                        else
                        {
                            new_local_node(field_dereference);
                            field_dereference->name = s("count");
                            field_dereference->expression = clone(parser, array_index->array_expression, get_base_node(field_dereference));
                            field_dereference->reference = get_base_node(array_type);
                            field_dereference->type = usize_type;

                            argument->expression = get_base_node(field_dereference);
                        }

                        function_call->first_argument->node.next = get_base_node(argument);
                        argument->node.parent = get_base_node(function_call);
                    }

                    array_index->index_expression = get_base_node(function_call);
                    function_call->node.parent = get_base_node(array_index);
                }
            }
        }
    }
}

get_or_add_unique_type_declaration
{
    assert(!parser->debug_unique_types_are_finalized);

    auto name_type = type.name_type.node;
    assert(name_type && is_type(name_type));
    assert(type.base_type.node);

    auto unique_types = &parser->unique_types;
    auto table = &unique_types->table;

    {
        lang_complete_type *unique_type;
        if (!insert(&unique_type, table, name_type))
        {
            //assert(unique_type->name_type.node, "this unique_type is being constructed");
            return get_indirect_type(parser, *unique_type, type.name_type.indirection_count);
        }
    }

    assert(!parser->debug_unique_types_are_finalized);

    switch (name_type->node_type)
    {
        cases_complete_message("%.*s", fnode_type_name(name_type));

        case ast_node_type_empty_type:
        case ast_node_type_number_type:
        case ast_node_type_enumeration_type:
        case ast_node_type_alias_type:
        {
            if (is_node_type(name_type, enumeration_type))
            {
                local_node_type(enumeration_type, name_type);
                auto unique_item_type = get_or_add_unique_type(parser, enumeration_type->item_type);
            }
            else if (is_node_type(name_type, alias_type))
            {
                local_node_type(alias_type, name_type);
                if (is_node_type(alias_type->type.name_type.node, enumeration_type))
                    auto unique_item_type = get_or_add_unique_type(parser, alias_type->type);
            }

            // we need to get the value again at, since we potentially added new unique types and the table may have resized
            lang_complete_type *value = get_value(table, name_type);
            assert(value);
            *value = to_type(parser, name_type);
            return get_indirect_type(parser, *value, type.name_type.indirection_count);
        } break;

        #if 0
        // we want the base type to also be a unique type
        case ast_node_type_alias_type:
        {
            local_node_type(alias_type, name_type);

            unique_type = to_type(parser, name_type); // don't use type directly, since it may have indirections

            // we need to get the value again at, since we potentially added new unique types and the table may have resized
            lang_complete_type *value;
            auto ok = hash_table_get_value(&value, *table, name_type);
            assert(ok);
            *value = unique_type;
            return get_indirect_type(parser, unique_type, type.name_type.indirection_count);

            //unique_type.base_type.node = get_unique_type(parser, alias_type->type).base_type.node;
        } break;
        #endif

        case ast_node_type_expression_reference_type:
        {
            local_node_type(expression_reference_type, name_type);

            auto unique_type = get_or_add_unique_type(parser, expression_reference_type->type);
            // we need to get the value again at, since we potentially added new unique types and the table may have resized
            {
                lang_complete_type *value = get_value(table, name_type);
                assert(value);
                *value = unique_type;
            }

            return get_indirect_type(parser, unique_type, type.name_type.indirection_count);
        } break;

        case ast_node_type_function_type:
        {
            local_node_type(function_type, name_type);

            ast_function_type *unique_function_type = null;
            {
                auto input = get_or_add_unique_type(parser, function_type->input);
                auto output = get_or_add_unique_type(parser, function_type->output);

                for_bucket_item(bucket, index, unique_types->unique_function_type_buckets)
                {
                    auto other_function_type = &bucket->base[index];

                    if ((input.name_type.node == other_function_type->input.name_type.node) && (output.name_type.node == other_function_type->output.name_type.node))
                    {
                        unique_function_type = other_function_type;
                        break;
                    }
                }
            }

            if (!unique_function_type)
            {
                unique_function_type = new_bucket_item(&unique_types->unique_function_type_buckets);
                *unique_function_type = *function_type;
                unique_function_type->node.type_index = unique_types->unique_function_type_buckets.item_count - 1;
            }

             // insert ourselfs, so we can self reference
            // we need to get the value again at, since we potentially added new unique types and the table may have resized
            auto unique_type = to_type(parser, get_base_node(unique_function_type));
            {
                lang_complete_type *value = get_value(table, name_type);
                assert(value);
                *value = unique_type;
            }

            // get unique types again, so we can self reference
            {
                unique_function_type->input  = get_or_add_unique_type(parser, function_type->input);
                unique_function_type->output = get_or_add_unique_type(parser, function_type->output);
            }

            // map unique type to itself
            {
                lang_complete_type *value;
                if (insert(&value, table, get_base_node(unique_function_type)))
                    *value = unique_type;
            }

            return get_indirect_type(parser, unique_type, type.name_type.indirection_count);
        } break;

        case ast_node_type_compound_type:
        case ast_node_type_union_type:
        {
            auto compound_or_union_type = (ast_compound_or_union_type *) name_type;

            ast_compound_type_bucket_array *buckets;

            if (name_type->node_type == ast_node_type_union_type)
                buckets = (ast_compound_type_bucket_array *) &unique_types->unique_union_type_buckets;
            else
                buckets = &unique_types->unique_compound_type_buckets;

            ast_compound_or_union_type *unique_compound_or_union_type = null;
            for_bucket_item(bucket, index, *buckets)
            {
                auto other_compound_or_union_type = &bucket->base[index];

                if (compound_or_union_type->field_count != other_compound_or_union_type->field_count)
                    continue;

                bool do_match = true;

                auto right_field = compound_or_union_type->first_field;
                for (auto left_field = other_compound_or_union_type->first_field; left_field; left_field = (ast_variable *) left_field->node.next)
                {
                    if (left_field->name != right_field->name)
                    {
                        do_match = false;
                        break;
                    }

                    auto unique_right_type = get_or_add_unique_type(parser, right_field->type);

                    if (left_field->type.name_type.node != unique_right_type.name_type.node)
                    {
                        do_match = false;
                        break;
                    }

                    right_field = (ast_variable *) right_field->node.next;
                }

                if (do_match)
                {
                    unique_compound_or_union_type = other_compound_or_union_type;
                    break;
                }
            }

            if (!unique_compound_or_union_type)
            {
                unique_compound_or_union_type = new_bucket_item(buckets);
                *unique_compound_or_union_type = *compound_or_union_type;
                unique_compound_or_union_type->node.type_index = buckets->item_count -1;

                unique_compound_or_union_type->first_field = null;
            }

            // insert ourselfs, so we can self reference
            // we need to get the value again at, since we potentially added new unique types and the table may have resized
            auto unique_type = to_type(parser, get_base_node(unique_compound_or_union_type));
            {
                lang_complete_type *value = get_value(table, name_type);
                assert(value);
                *value = unique_type;
            }

            // now we can find self references
            if (!unique_compound_or_union_type->first_field)
            {
                auto tail_next = make_tail_next(&unique_compound_or_union_type->first_field);

                for (auto field = compound_or_union_type->first_field; field; field = (ast_variable *) field->node.next)
                {
                    new_local_leaf_node(variable, parser->node_locations.base[field->node.index].text);
                    *variable = *field;
                    variable->node.parent = get_base_node(unique_compound_or_union_type);

                #if 1
                    variable->type = get_or_add_unique_type(parser, field->type);
                #else
                    variable->type.name_type.node = get_or_add_unique_node(parser, field->type.name_type.node);
                    resolve_complete_type(parser, &variable->type);
                #endif

                    variable->node.next = null;
                    append_tail_next(&tail_next, &variable->node);
                }
            }

            // map unique type to itself
            {
                lang_complete_type *value;
                if (insert(&value, table, get_base_node(unique_compound_or_union_type)))
                    *value = unique_type;
            }

            return get_indirect_type(parser, unique_type, type.name_type.indirection_count);
        } break;

        case ast_node_type_array_type:
        {
            local_node_type(array_type, name_type);

            ast_array_type *unique_array_type = null;
            {
                auto unique_item_type = get_or_add_unique_type(parser, array_type->item_type);

                u64 item_count = 0;
                if (array_type->item_count_expression)
                    item_count = get_array_item_count(array_type);

                for_bucket_item(bucket, index, unique_types->unique_array_type_buckets)
                {
                    auto other_array_type = &bucket->base[index];

                    if (unique_item_type.name_type.node != other_array_type->item_type.name_type.node)
                        continue;

                    if (unique_item_type.name_type.indirection_count != other_array_type->item_type.name_type.indirection_count)
                        continue;

                    if (!array_type->item_count_expression != !other_array_type->item_count_expression)
                        continue;

                    if (array_type->item_count_expression && (item_count != get_array_item_count(other_array_type)))
                        continue;

                    unique_array_type = other_array_type;
                    break;
                }
            }

            if (!unique_array_type)
            {
                unique_array_type = new_bucket_item(&unique_types->unique_array_type_buckets);
                *unique_array_type = *array_type;
                unique_array_type->node.type_index = unique_types->unique_array_type_buckets.item_count -1;
            }

            // insert ourselfs, so we can self reference
            // we need to get the value again at, since we potentially added new unique types and the table may have resized
            auto unique_type = to_type(parser, get_base_node(unique_array_type));
            {
                lang_complete_type *value = get_value(table, name_type);
                assert(value);
                *value = unique_type;
            }

            // so we can self reference
            unique_array_type->item_type = get_or_add_unique_type(parser, array_type->item_type);

            // map unique type to itself
            {
                lang_complete_type *value;
                if (insert(&value, table, get_base_node(unique_array_type)))
                    *value = unique_type;
            }

            return get_indirect_type(parser, unique_type, type.name_type.indirection_count);
        } break;
    }

    unreachable_codepath;
    return {};
}
