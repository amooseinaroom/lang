#pragma once

#include "lang.h"

struct lang_c_compile_settings
{
    string prefix;
    bool use_default_types;
};

struct lang_c_dependency_table_key
{
    ast_node *parent;
    ast_node *child;
};

struct lang_c_dependency_table_value
{
    u32 depth;
};

bool operator==(lang_c_dependency_table_key a, lang_c_dependency_table_key b)
{
    return (a.parent == b.parent) && (a.child == b.child);
}

bool operator!=(lang_c_dependency_table_key a, lang_c_dependency_table_key b)
{
    return !(a == b);
}

#define TEMPLATE_HASH_TABLE_NAME  lang_c_dependency_table
#define TEMPLATE_HASH_TABLE_KEY   lang_c_dependency_table_key
#define TEMPLATE_HASH_TABLE_VALUE lang_c_dependency_table_value
#define TEMPLATE_HASH_TABLE_ADDITINAL_FIELDS \
    usize ast_node_count;
#include "template_hash_table.h"

#define TEMPLATE_HASH_TABLE_NAME     ast_node_index_table
#define TEMPLATE_HASH_TABLE_KEY      ast_node *
#define TEMPLATE_HASH_TABLE_KEY_ZERO null
#define TEMPLATE_HASH_TABLE_VALUE    u32
#include "template_hash_table.h"

u64 hash_of(ast_node_index_table *table, ast_node *key)
{
    return key->index + 1;
}

struct lang_c_buffer
{
    lang_parser *parser;
    lang_c_compile_settings settings;
    string_builder builder;
    u32 comment_depth;
    
    lang_c_dependency_table dependency_table;
    ast_node_buffer         sorted_dependencies;
    
    // cache table for single static assignments when calling print_statement
    ast_node_index_table statement_expression_to_local_map;
};

u64 hash_of(lang_c_dependency_table *table, lang_c_dependency_table_key key)
{
    auto parent_index = key.parent->index;
    usize child_index = 0;
    if (key.child)
        child_index = key.child->index;
    
    return parent_index * table->ast_node_count + child_index;
}

void free_dependencies(lang_c_buffer *buffer)
{
    free_table(&buffer->dependency_table);
    free_buffer(&buffer->sorted_dependencies);
}

#define add_dependencies_declaration ast_node * add_dependencies(lang_c_buffer *buffer, ast_node *node)
add_dependencies_declaration;

void print_dependency(lang_parser *parser, string_builder *builder, ast_node *child, ast_node *parent)
{
    print_name(parser, builder, child);
    print(builder, " depends on ");
    print_name(parser, builder, parent);
    print_newline(builder);
}

bool is_ancestor_of(lang_c_buffer *buffer, ast_node *unique_ancestor, ast_node *unique_decendant, u32 depth = 0)
{
    auto table = &buffer->dependency_table;
    
    lang_c_dependency_table_key key = { unique_ancestor, unique_decendant };    
    if (contains_key(table, key))
    {
        print_dependency(buffer->parser, &buffer->builder, unique_decendant, unique_ancestor);
        return true;
    }
    
    for (u32 i = 0; i < table->count; i++)
    {
        auto key = table->keys[i];
        if ((key.parent == unique_ancestor) && key.child && is_ancestor_of(buffer, key.child, unique_decendant, depth + 1))
        {
            print_dependency(buffer->parser, &buffer->builder, key.child, unique_ancestor);
            return true;
        }
    }
    
    return false;
}

void add_dependency(lang_c_buffer *buffer, ast_node *unique_child, ast_node *parent)
{
    auto table = &buffer->dependency_table;
    
    assert(unique_child == add_dependencies(buffer, unique_child));
    auto unique_parent = add_dependencies(buffer, parent);
    assert(!is_ancestor_of(buffer, unique_child, unique_parent));
    
    lang_c_dependency_table_key key = { unique_parent, unique_child };
    lang_c_dependency_table_value *value;
    insert(&value, table, key);
}

void add_dependency(lang_c_buffer *buffer, ast_node *unique_child, lang_complete_type parent_type)
{
    auto parent = parent_type.name_type.node;
    
    auto name_type = parent_type.name_type;
    if (is_node_type(name_type.node, alias_type))
    {
        local_node_type(alias_type, name_type.node);
        name_type = alias_type->type.name_type;
        name_type.indirection_count += parent_type.name_type.indirection_count;
        
        if ((is_node_type(name_type.node, compound_type) || is_node_type(name_type.node, union_type)) && name_type.indirection_count)
        {
            assert(unique_child == add_dependencies(buffer, unique_child));
            add_dependencies(buffer, parent);
            return;
        }
    }
    
    add_dependency(buffer, unique_child, parent);
}

void add_compound_or_union_dependencies(lang_c_buffer *buffer, ast_node *unique_child, ast_node *parent)
{
    assert(is_node_type(parent, compound_type) || is_node_type(parent, union_type));
    auto compound_or_union_type = (ast_compound_or_union_type *) parent;

    for (auto field = compound_or_union_type->first_field; field; field = (ast_variable *) field->node.next)
    {
        add_dependency(buffer, unique_child, field->type);
    }
}

ast_node * get_head_expression(ast_node *expression)
{
    auto head = expression;
    while (head)
    {
        switch (head->node_type)
        {
            cases_complete("%.*s", fnode_type_name(head)); return null; // prevent infinte loop in unhandled cases
            
            case ast_node_type_name_reference:
            {
                local_node_type(name_reference, head);
                head = name_reference->reference;
            } break;
            
            case ast_node_type_array_index:
            {
                local_node_type(array_index, head);
                head = array_index->array_expression;
            } break;
            
            case ast_node_type_field_dereference:
            {
                local_node_type(field_dereference, head);
                head = field_dereference->expression;
            } break;
            
            case ast_node_type_function_call:
            {
                local_node_type(function_call, head);
                head = function_call->expression;
            } break;
            
            case ast_node_type_dereference:
            case ast_node_type_constant:
            case ast_node_type_variable:
            case ast_node_type_function:
            case ast_node_type_number:
            case ast_node_type_string_literal:
            case ast_node_type_array_literal:
            case ast_node_type_compound_literal:
            case ast_node_type_unary_operator:
            case ast_node_type_binary_operator:
            case ast_node_type_get_type_info:
            case ast_node_type_type_byte_count:
            case ast_node_type_get_function_reference:
            {
                return head;
            } break;
        }
    }
    
    return null;
}

add_dependencies_declaration
{
    auto parser = buffer->parser;
    auto table = &buffer->dependency_table;
    
    auto unique_node = get_unique_node(parser, node);
    
    lang_c_dependency_table_key key = { unique_node, null };
    lang_c_dependency_table_value *value;
    if (!insert(&value, table, key))
        return unique_node;
    
    value->depth = 0;
    
    switch (unique_node->node_type)
    {
        cases_complete_message("%.*s", fnode_type_name(unique_node));
        
        case ast_node_type_number_type:
        {
            // nothing to do;
        } break;
        
        case ast_node_type_alias_type:
        {
            local_node_type(alias_type, unique_node);
            
            auto name_type = alias_type->type.name_type.node;
            if (is_node_type(name_type, enumeration_type))
            {
                local_node_type(enumeration_type, alias_type->type.name_type.node);
                
                add_dependency(buffer, unique_node, enumeration_type->item_type);
                
                for (auto item = enumeration_type->first_item; item; item = (ast_enumeration_item *) item->node.next)
                {
                    auto type = get_expression_type(parser, item->expression);
                    add_dependency(buffer, unique_node, type);
                }
            }
            else if (!is_node_type(name_type, compound_type) && !is_node_type(name_type, union_type))
            {
                add_dependency(buffer, unique_node, alias_type->type);
            }
            else
            {
                add_compound_or_union_dependencies(buffer, unique_node, name_type);
            }
        } break;
        
        case ast_node_type_compound_type:
        case ast_node_type_union_type:
        {
            add_compound_or_union_dependencies(buffer, unique_node, unique_node);
        } break;
        
        case ast_node_type_function_type:
        {
            local_node_type(function_type, unique_node);
            
            if (type_is_not_empty(function_type->input))
                add_compound_or_union_dependencies(buffer, unique_node, function_type->input.base_type.node);
                
            if (function_type_has_multiple_return_values(function_type))
                add_dependency(buffer, unique_node, function_type->output);
            else if (type_is_not_empty(function_type->output))
                add_compound_or_union_dependencies(buffer, unique_node, function_type->output.base_type.node);
        } break;
        
        case ast_node_type_enumeration_type:
        {
            local_node_type(enumeration_type, unique_node);
            add_dependency(buffer, unique_node, enumeration_type->item_type);
            
            for (auto item = enumeration_type->first_item; item; item = (ast_enumeration_item *) item->node.next)
            {
                auto type = get_expression_type(parser, item->expression);
                add_dependency(buffer, unique_node, type);
            }
        } break;
        
        case ast_node_type_array_type:
        {
            local_node_type(array_type, unique_node);
            if (array_type->item_count_expression)
                add_dependency(buffer, unique_node, array_type->item_type);
            else
                add_dependency(buffer, unique_node, get_indirect_type(parser, array_type->item_type));
                
        } break;
        
        case ast_node_type_function:
        {
            local_node_type(function, unique_node);
            local_node_type(function_type, function->type.base_type.node);
            
            if (type_is_not_empty(function_type->input))
                add_compound_or_union_dependencies(buffer, unique_node, function_type->input.base_type.node);
            
            if (function_type_has_multiple_return_values(function_type))
                add_dependency(buffer, unique_node, function_type->output);
            else if (type_is_not_empty(function_type->output))
                add_compound_or_union_dependencies(buffer, unique_node, function_type->output.base_type.node);
        } break;
        
        case ast_node_type_constant:
        {
            local_node_type(constant, unique_node);
            
            // since we don't have complete compile time constant evaluation, we depend on the expression
            {
                auto expression = constant->expression;
                local_buffer(queue, ast_queue);
                enqueue_one(&queue, &expression);
                
                ast_node *node;
                while (next(&node, &queue))
                {
                    switch (node->node_type)
                    {
                        case ast_node_type_name_reference:
                        {
                            local_node_type(name_reference, node);
                            
                            auto reference = name_reference->reference;
                            switch (reference->node_type)
                            {
                                cases_complete("%.*s", fnode_type_name(reference));
                                
                                case ast_node_type_constant:
                                case ast_node_type_variable:
                                case ast_node_type_function:
                                case ast_node_type_alias_type:
                                {
                                    add_dependency(buffer, unique_node, reference);
                                } break;
                                
                            }
                        } break;
                    }
                }
            }
            
            auto type = get_expression_type(parser, constant->expression);
            add_dependency(buffer, unique_node, type);
        } break;
        
        case ast_node_type_variable:
        {
            local_node_type(variable, unique_node);
            assert(variable->is_global);
            add_dependency(buffer, unique_node, variable->type);
        } break;
        
    }
    
    return unique_node;
}

void sort_declaration_dependencies(lang_c_buffer *buffer)
{
    auto parser = buffer->parser;
    auto dependency_table = &buffer->dependency_table;
    init(dependency_table, 1024);
    dependency_table->ast_node_count = parser->next_node_index;
    
    // collect
    {
        for (u32 i = 0; i < parser->required_nodes.count; i++)
        {
            auto key = parser->required_nodes.keys[i];
            if (!key)
                continue;
            
            add_dependencies(buffer, key);
        }
    }
    
    if (parser->error)
        return;
    
    // sort
    ast_node_buffer sorted_dependencies = {};
    
    {
        auto dependency_table = &buffer->dependency_table;
        // calculate depth per node
        u32 max_depth = 0;
        {
            bool requires_next_pass = true;
            while (requires_next_pass)
            {
                requires_next_pass = false;
                
                max_depth = 0;
                
                for (u32 i = 0; i < dependency_table->count; i++)
                {
                    auto key = dependency_table->keys[i];
                    if (!key.parent || !key.child)
                        continue;
                    
                    assert(key.parent != key.child);
                    assert(get_unique_node(parser, key.parent) == key.parent);
                    assert(get_unique_node(parser, key.child) == key.child);
                                        
                    lang_c_dependency_table_key parent_key = { key.parent, null };
                    lang_c_dependency_table_value *parent_value = get_value(dependency_table, parent_key);
                    assert(parent_value);
                                        
                    lang_c_dependency_table_key child_key = { key.child, null };
                    lang_c_dependency_table_value *child_value = get_value(dependency_table, child_key);
                    assert(child_value);
                    
                    auto new_depth = maximum(parent_value->depth + 1, child_value->depth);
                    
                    max_depth = maximum(new_depth, max_depth);
                    
                    requires_next_pass |= (new_depth != child_value->depth);
                    
                    child_value->depth = new_depth;
                }
            }
        }
        
        // add nodes by depth
        for (u32 depth = 0; depth <= max_depth; depth++)
        {
            for (u32 i = 0; i < dependency_table->count; i++)
            {
                auto key = dependency_table->keys[i];
                if (!key.parent || key.child)
                    continue;
                
                assert(get_unique_node(parser, key.parent) == key.parent);
                auto value = dependency_table->values[i];
                
                if (value.depth == depth)
                {
                    resize_buffer(&sorted_dependencies, sorted_dependencies.count + 1);
                    sorted_dependencies.base[sorted_dependencies.count - 1] = key.parent;
                }
            }
        }
        
    #if _DEBUG
        // test if sort is correct
        for (u32 i = 0; i < dependency_table->count; i++)
        {
            auto key = dependency_table->keys[i];
            if (!key.parent || !key.child)
                continue;
                
            u32 parent_index = -1;
            u32 child_index = -1;
            
            for (u32 i = 0; i < sorted_dependencies.count; i++)
            {
                if (key.parent == sorted_dependencies.base[i])
                {
                    assert(parent_index == -1);
                    parent_index = i;
                }
                
                if (key.child == sorted_dependencies.base[i])
                {
                    assert(child_index == -1);
                    child_index = i;
                }
            }
            
            assert(parent_index != -1);
            assert(child_index != -1);
            assert(child_index > parent_index);
        }
        
        // print all dependencies
        
        {
            string_builder builder = {};
            defer { free_buffer(&builder.memory.array); };
            for (u32 i = 0; i < dependency_table->count; i++)
            {
                auto key = dependency_table->keys[i];
                if (!key.parent || !key.child)
                    continue;
                
                print_dependency(parser, &builder, key.child, key.parent);
            }
            
            printf("dependencies:\n%.*s\n", fs(builder.memory.array));
        }
    #endif
    }
    
    buffer->sorted_dependencies = sorted_dependencies;
}


// since C/C++ don't support nested comments
void print_comment_begin(lang_c_buffer *buffer)
{
    if (!buffer->comment_depth)
        print(&buffer->builder, "/* ");
    
    buffer->comment_depth++;
}

void print_comment_end(lang_c_buffer *buffer)
{
    assert(buffer->comment_depth);
    buffer->comment_depth--;
    
    if (!buffer->comment_depth)
        print(&buffer->builder, " */ ");
}

bool print_next(ast_node **out_node, ast_queue *queue)
{
    if (!queue->count)
        return false;

    auto node = *queue->base[--queue->count].node_field;
    
    switch (node->node_type)
    {
        case ast_node_type_file:
        {
            local_node_type(file, node);
            
            if (file->first_statement)
                enqueue(queue, &file->first_statement);
        } break;
    }
    
    *out_node = node;
    
    return true;
}

#define print_expression_declaration void print_expression(lang_c_buffer *buffer, ast_node *node, ast_node_index_table *expression_to_local_map, bool is_inside_array_literal)
print_expression_declaration;

#define print_statements_declaration void print_statements(lang_c_buffer *buffer, ast_node *first_statement)
print_statements_declaration;

void print_type(lang_c_buffer *buffer, lang_complete_type type, string variable_name = {}, bool as_name = false);

void print_type(lang_c_buffer *buffer, lang_complete_type type, string variable_name, bool as_name)
{
    assert(!as_name || !variable_name.count);
    
    auto parser = buffer->parser;
    //auto graph = &buffer->parser->dependency_graph;
    auto builder = &buffer->builder;
    
    auto name_type = type.name_type;
    assert(name_type.node);
    name_type.node = get_unique_node(parser, name_type.node);
    
    switch (name_type.node->node_type)
    {
        cases_complete;
        
        case ast_node_type_function_type:
        {
            print(builder, "_function_type_%x", name_type.node->index);
        } break;
        
        case ast_node_type_enumeration_type:
        {
            print(builder, "_enumeration_%x", name_type.node->index);
        } break;
        
        case ast_node_type_alias_type:
        {
            local_node_type(alias_type, name_type.node);
            print(builder, "%.*s", fs(alias_type->name));
        } break;
        
        case ast_node_type_expression_reference_type:
        {
            local_node_type(expression_reference_type, name_type.node);
            
            print_comment_begin(buffer);
            print(builder, "type_of(");
            print_expression(buffer, expression_reference_type->expression, null, false);
            print(builder, ")");
            print_comment_end(buffer);
            
            print_type(buffer, expression_reference_type->type);
        } break;
        
        case ast_node_type_array_type:
        {
            local_node_type(array_type, name_type.node);
            
            if (array_type->item_count_expression)
            {
                print_type(buffer, array_type->item_type, {}, true);
                print(builder, "_array_type_%i", get_array_item_count(array_type));
            }
            else
            {
                print_type(buffer, array_type->item_type, {}, true);
                print(builder, "_array_type", name_type.node->index);
            }
        } break;
        
        case ast_node_type_compound_type:
        {
            print(builder, "_compound_type_%x", name_type.node->index);
        } break;
        
        case ast_node_type_union_type:
        {
            print(builder, "_union_type_%x", name_type.node->index);
        } break;
        
        case ast_node_type_number_type:
        {
            local_node_type(number_type, name_type.node);
            print(builder, "%.*s", fs(number_type->name));
        } break;
        
    }
    
    // some space for formating, since the * is considered part of the name, not the type in C
    if (!as_name && (variable_name.count || name_type.indirection_count))
        print(builder, " ");
        
    for (u32 i = 0; i < name_type.indirection_count; i++)
    {
        if (as_name)
            print(builder, "_ref");
        else
            print(builder, "*");
    }
    
    if (variable_name.count)
        print(builder, "%.*s", fs(variable_name));
}

void print_type(lang_c_buffer *buffer, ast_node *base_type, string variable_name = {}, bool as_name = false)
{
    lang_complete_type type = {};
    type.base_type.node = base_type;
    type.name_type = type.base_type;
    
    print_type(buffer, type, variable_name, as_name);
}



void print_array_literal(lang_c_buffer *buffer, ast_array_literal *array_literal, ast_node_index_table *expression_to_local_map)
{
    auto builder = &buffer->builder;
    
    auto array_type = array_literal->array_type;
    
    // print type so we can remove ambigious operands
    print_type(buffer, array_literal->type);
    
    // open two scopes since we wrap arrays into struct
    
    auto item_count = get_array_item_count(array_type);
    if (item_count <= 10)
        print(builder, "{ { ");
    else
    {
        print_scope_open(builder);
        print_scope_open(builder);
    }
    
    if (array_literal->first_argument)
    {
        print_expression(buffer, array_literal->first_argument->expression, expression_to_local_map, true);
        for (auto argument = (ast_argument *) array_literal->first_argument->node.next; argument; argument = (ast_argument *) argument->node.next)
        {
            if (item_count <= 10)
                print(builder, ", ");
            else
                print_line(builder, ",");
            
            print_expression(buffer, argument->expression, expression_to_local_map, true);
        }
        
        if (item_count > 10)
            pending_newline(builder);
    }
    
    if (item_count <= 10)
    {
        print(builder, " } }");
    }
    else
    {
        print_scope_close(builder);
        print_scope_close(builder, false);
    }
    
}

void print_compound_literal(lang_c_buffer *buffer, ast_compound_literal *compound_literal, ast_node_index_table *expression_to_local_map, bool is_inside_array_literal)
{
    auto builder = &buffer->builder;
    
    // print type so we can remove ambigious operands
    print_type(buffer, compound_literal->type);
    
    print_scope_open(builder, false);
    
    if (compound_literal->first_argument)
    {
        // print(builder, "%.*s: ", fs(compound_literal->first_field->name)); C could do this
        print(builder, " ");
        print_expression(buffer, compound_literal->first_argument->expression, expression_to_local_map, is_inside_array_literal);
        for (auto argument = (ast_argument *) compound_literal->first_argument->node.next; argument; argument = (ast_argument *) argument->node.next)
        {
            print(builder, ", ");
            // print(builder, "%.*s: ", fs(argument->name)); C could do this
            print_expression(buffer, argument->expression, expression_to_local_map, is_inside_array_literal);
        }
        
        //print_newline(builder);
        print(builder, " ");
    }

    print_scope_close(builder, false);
}

void print_declaration(lang_c_buffer *buffer, ast_variable *variable)
{
    auto builder = &buffer->builder;
    print_type(buffer, variable->type, variable->name);
}

usize get_string_c_count(string text)
{
    usize count = 0;
    while (text.count)
    {
        // skip escaped character
        if (text.base[0] == '\\' && text.count > 1)
        {
            text.base++;
            text.count--;
        }
        
        text.base++;
        text.count--;
        count++;
    }
    
    return count;
}

void print_type_info(lang_c_buffer *buffer, lang_complete_type type)
{
    auto builder = &buffer->builder;
    
    if (!type.base_type.node)
    {
        print(builder, "lang_type_info {}");
        return;
    }

    auto base_type = get_unique_type(buffer->parser, type).base_type.node;
    assert(get_unique_type(buffer->parser, to_type(buffer->parser, base_type)).base_type.node == base_type);
    
    auto type_index = base_type->type_index;
    
    // get type without indirectio or we allways get point byte count and alignment
    auto direct_type = type;
    direct_type.name_type.indirection_count = 0;
    direct_type.base_type.indirection_count = 0;
    auto count_and_alignment = get_type_byte_count_and_alignment(direct_type);
    
    string base_type_names[] = {
        s("empty"),
        s("number"),
        s("enumeration"),
        s("function"),
        s("compound"),
        s("union"),
        s("array"),
    };
    
    // cast const away
    print(builder, "lang_type_info { string { %llu, (u8 *) \"%.*s\" }, (u8 *) &lang_type_table.%.*ss.base[%u], lang_type_info_type_%.*s, %ullu, %u, %u }", type.name.count, fs(type.name), fnode_type_name(base_type), type_index, fs(base_type_names[base_type->node_type]), count_and_alignment.byte_count, type.base_type.indirection_count, count_and_alignment.byte_alignment);
}

void print_c_string(string_builder *builder, string text, bool is_raw)
{
    if (!is_raw)
    {
        print(builder, "%.*s", fs(text));
        return;
    }
    
    for (usize i = 0; i < text.count; i++)
    {
        switch (text.base[i])
        {
            case '\0':
            {
                print(builder, "\\0");
            } break;
            
            case '\\':
            {
                print(builder, "\\\\");
            } break;
            
            case '\r':
            {
                print(builder, "\\r");
            } break;
                
            case '\n':
            {
                print(builder, "\\n");
            } break;
            
            default:
            {
                if (text.base[i] < ' ')
                    print(builder, "\\x%x", text.base[i]);
                else
                    print(builder, "%c", text.base[i]);
            }
        }
    }
}

void print_number(lang_c_buffer *buffer, parsed_number value)
{
    auto builder = &buffer->builder;
    
    if (value.is_character)
    {
        assert(!value.is_float && !value.is_signed && !value.is_hex);
        
        print_comment_begin(buffer);
        print_raw(builder, "%c", (u8) value.u64_value);
        print_comment_end(buffer);
        
        print(builder, "%llu", value.u64_value);
    }
    else if (value.is_float)
    {
        if (value.bit_count_power_of_two == 5)
            print(builder, "%ff", value.f64_value);
        else
            print(builder, "%f", value.f64_value);
    }
    else if (value.is_signed)
    {
        if (value.is_hex)
        {
            if (value.s64_value < 0)
                print(builder, "-0x%llx", value.s64_value);
            else
                print(builder, "0x%llx", value.s64_value);
        }
        else
            print(builder, "%lli", value.s64_value);
            
        if (value.bit_count_power_of_two == 6)
            print(builder, "ll");
    }
    else
    {
        if (value.is_hex)
            print(builder, "0x%llx", value.u64_value);
        else
            print(builder, "%llu", value.u64_value);
            
        if (value.bit_count_power_of_two == 6)
            print(builder, "ull");
    }
}

void print_function_name(string_builder *builder, ast_function *function)
{
    if (function->do_export || (function->first_statement && (is_node_type(function->first_statement, intrinsic) || is_node_type(function->first_statement, external_binding))))
        print(builder, "%.*s", fs(function->name));
    else
        print(builder, "%.*s_%i", fs(function->name), function->node.index);
}

print_expression_declaration
{
    auto parser = buffer->parser;
    auto builder = &buffer->builder;
    
    if (expression_to_local_map)
    {
        u32 *index = get_value(expression_to_local_map, node);
        if (index)
        {
            print(builder, "__local_%u", *index);
            return;
        }
    }
    
    switch (node->node_type)
    {
        cases_complete_message("unhandled expression type %.*s", fnode_type_name(node));
        
        // nothing to do
        case ast_node_type_base_node:
        break;
        
        case ast_node_type_number:
        {
            local_node_type(number, node);
            print_number(buffer, number->value);
        } break;
        
        case ast_node_type_string_literal:
        {
            local_node_type(string_literal, node);
            print(builder, "string{ %llu, (u8 *) \"", get_string_c_count(string_literal->text));
            print_c_string(builder, string_literal->text, string_literal->is_raw);
            print(builder, "\" }");
        } break;
        
        case ast_node_type_array_literal:
        {
            local_node_type(array_literal, node);
            
            print_array_literal(buffer, array_literal, expression_to_local_map);
        } break;
        
        case ast_node_type_compound_literal:
        {
            local_node_type(compound_literal, node);
            print_compound_literal(buffer, compound_literal, expression_to_local_map, is_inside_array_literal);
        } break;
        
        case ast_node_type_name_reference:
        {
            local_node_type(name_reference, node);
            
            if (!name_reference->reference)
            {
                print_comment_begin(buffer);
                print(builder, "not resolved");
                print_comment_end(buffer);
            }
            
            if (is_node_type(name_reference->reference, function))
            {
                local_node_type(function, name_reference->reference);
                print_function_name(builder, function);
            }
            else
            {
                print(builder, "%.*s", fs(name_reference->name));
            }
        } break;
                    
        case ast_node_type_function_call:
        {
            local_node_type(function_call, node);

            print_expression(buffer, function_call->expression, expression_to_local_map, is_inside_array_literal);
            print(builder, "(");
            
            bool is_not_first = false;
            for (auto argument = function_call->first_argument; argument; argument = (ast_argument *) argument->node.next)
            {
                if (is_not_first)
                    print(builder, ", ");
                    
                print_expression(buffer, argument->expression, expression_to_local_map, is_inside_array_literal);
                is_not_first = true;
            }
            print(builder, ")");
        } break;
        
        case ast_node_type_dereference:
        {
            local_node_type(dereference, node);
            
            print(builder, "*");
            print_expression(buffer, dereference->expression, expression_to_local_map, is_inside_array_literal);
        } break;
        
        case ast_node_type_field_dereference:
        {
            local_node_type(field_dereference, node);
            
            assert(field_dereference->reference);
            
            auto type = get_expression_type(buffer->parser, field_dereference->expression).base_type;
            
            if (is_node_type(type.node, enumeration_type))
            {
                assert(!type.indirection_count);
                if (field_dereference->name == s("count"))
                {
                    local_node_type(enumeration_type, type.node);
                    
                    print_comment_begin(buffer);
                    
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal);
                    print(builder, "_%.*s", fs(field_dereference->name));
                    
                    print_comment_end(buffer);
                    
                    print(builder, " %i", enumeration_type->item_count);
                }
                else
                {
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal);
                    print(builder, "_%.*s", fs(field_dereference->name));
                }
            }
            else if (is_node_type(type.node, array_type) && ((ast_array_type *) type.node)->item_count_expression)
            {
                local_node_type(array_type, type.node);
                                
                if ((field_dereference->name == s("count")))
                {
                    print_comment_begin(buffer);
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal);
                    print(builder, ".");
                    print(builder, "%.*s", fs(field_dereference->name));
                    print_comment_end(buffer);

                    print_expression(buffer, array_type->item_count_expression, expression_to_local_map, is_inside_array_literal);
                }   
                else
                {
                    // cast (const type[count]) to (type *)                    
                    print(builder, "(");                    
                    print_type(buffer, get_indirect_type(parser, array_type->item_type));
                    print(builder, ") ");
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal);                    
                    print(builder, ".base");
                }                                                                
            }
            else
            {
                if (type.indirection_count == 1)
                {
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal);
                    print(builder, "->");
                    
                }
                else if (type.indirection_count == 0)
                {
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal);
                    print(builder, ".");
                }
                else
                {
                    print_comment_begin(buffer);
                    print(builder, "too many indirections %.*s", fs(field_dereference->name));
                    print_comment_end(buffer);
                }
            
                print(builder, "%.*s", fs(field_dereference->name));
            }
        } break;
        
        case ast_node_type_array_index:
        {
            local_node_type(array_index, node);
            
            auto type = get_expression_type(parser, array_index->array_expression);
            auto base_type = type.base_type.node;
            local_node_type(array_type, base_type);
            
            // auto derefence array pointers
            if (type.base_type.indirection_count)
            {
                print(builder, "(");
                
                for (u32 i = 0; i < type.base_type.indirection_count; i++)
                    print(builder, "*");
                
                print_expression(buffer, array_index->array_expression, expression_to_local_map, is_inside_array_literal);
                print(builder, ")");
            }
            else
            {
                print_expression(buffer, array_index->array_expression, expression_to_local_map, is_inside_array_literal);
            }
            
            print(builder, ".base[");
            print_expression(buffer, array_index->index_expression, expression_to_local_map, is_inside_array_literal);
            print(builder, "]");
        } break;
        
        case ast_node_type_unary_operator:
        {
            local_node_type(unary_operator, node);
        
            switch (unary_operator->operator_type)
            {
                case ast_unary_operator_type_cast:
                {
                    print(builder, "((");
                    print_type(buffer, unary_operator->type);
                    print(builder, ") ");
                    
                    if (unary_operator->type.name_type.indirection_count)
                    {
                        auto type = get_expression_type(parser, unary_operator->expression);
                     
                        if (!type.name_type.indirection_count && is_node_type(type.base_type.node, number_type))
                        {
                            auto usize_type = get_node_type(number_type, parser->base_alias_types[lang_base_alias_type_usize]->type.base_type.node);
                        
                            local_node_type(number_type, type.base_type.node);
                            if (number_type->bit_count_power_of_two < usize_type->bit_count_power_of_two)
                                print(builder, "(usize)");
                        }
                    }
                    
                    print_expression(buffer, unary_operator->expression, expression_to_local_map, is_inside_array_literal);
                    print(builder, ")");
                } break;
                
                default:
                {
                    if (unary_operator->function)
                    {
                        print_function_name(builder, unary_operator->function);
                        print(builder, "(", fs(ast_unary_operator_names[unary_operator->operator_type]));
                        print_expression(buffer, unary_operator->expression, expression_to_local_map, is_inside_array_literal);
                        print(builder, ")");
                    }
                    else
                    {
                        string c_symbols[] =
                        {
                            s("!"),
                            s("~"),
                            s("-"),
                            s("&"),
                        };
                        
                        assert(unary_operator->operator_type < carray_count(c_symbols));
                
                        // we don't have const, so we may need to cast const away when taking pointers to constants
                        if (unary_operator->operator_type == ast_unary_operator_type_take_reference)
                        {
                            // cast const away
                            auto head = get_head_expression(unary_operator->expression);
                            if (is_node_type(head, constant))
                            {
                                local_node_type(constant, head);
                                print(builder, "(");
                                print_type(buffer, unary_operator->type);
                                print(builder, ") ");
                            }
                        }
                
                        print(builder, "%.*s", fs(c_symbols[unary_operator->operator_type]));
                        print_expression(buffer, unary_operator->expression, expression_to_local_map, is_inside_array_literal);
                    }
                }
            }
        } break;
        
        case ast_node_type_get_function_reference:
        {
            local_node_type(get_function_reference, node);
            assert(get_function_reference->function);
            print_function_name(builder, get_function_reference->function);
        } break;
        
        case ast_node_type_get_type_info:
        {
            local_node_type(get_type_info, node);
            print_type_info(buffer, get_type_info->type);
        } break;
        
        case ast_node_type_type_byte_count:
        {
            local_node_type(type_byte_count, node);
            
            auto count_and_alignment = get_type_byte_count_and_alignment(type_byte_count->type);
            
            print_comment_begin(buffer);
            
            print(builder, "type_byte_count(");
            print_type(buffer, type_byte_count->type);
            print(builder, ")");
            
            print_comment_end(buffer);
            
            print(builder, "%llu", count_and_alignment.byte_count);
        } break;
        
        case ast_node_type_binary_operator:
        {
            local_node_type(binary_operator, node);
        
            if (binary_operator->function)
            {
                print_function_name(builder, binary_operator->function);
                print(builder, "(", fs(ast_binary_operator_names[binary_operator->operator_type]));
                print_expression(buffer, binary_operator->left, expression_to_local_map, is_inside_array_literal);
                print(builder, ", ");
                print_expression(buffer, binary_operator->left->next, expression_to_local_map, is_inside_array_literal);
                print(builder, ")");
            }
            else
            {
                string c_symbols[] =
                {
                    s("||"),
                    s("&&"),
                    s("!="),
                
                    s("=="),
                    s("!="),
                    
                    s("<"),
                    s("<="),
                    s(">"),
                    s(">="),
                    
                    s("|"),
                    s("&"),
                    s("^"),
                    s("<<"),
                    s(">>"),
                    
                    s("+"),
                    s("-"),
                    s("*"),
                    s("/"),
                    s("%"),
                };
                
                assert(binary_operator->operator_type < carray_count(c_symbols));
                
                print(builder, "(");
                print_expression(buffer, binary_operator->left, expression_to_local_map, is_inside_array_literal);
                print(builder, " %.*s ", fs(c_symbols[binary_operator->operator_type]));
                print_expression(buffer, binary_operator->left->next, expression_to_local_map, is_inside_array_literal);
                print(builder, ")");
            }
        } break;
    }
}

void print_constant_declaration(lang_c_buffer *buffer, ast_constant *constant, ast_node_index_table *expression_to_local_map)
{
    auto type = get_expression_type(buffer->parser, constant->expression);
    
    auto builder = &buffer->builder;
    
    print(builder, "const ");
    print_type(buffer, type, constant->name);
    
    print(builder, " = ");
    print_expression(buffer, constant->expression, expression_to_local_map, true);
    
    print_line(builder, ";");
}

void print_variable_statement(lang_c_buffer *buffer, ast_variable *variable, ast_node_index_table *expression_to_local_map)
{
    auto builder = &buffer->builder;
    
    print_declaration(buffer, variable);
    
    if (variable->default_expression)
    {
        print(builder, " = ");
        print_expression(buffer, variable->default_expression, expression_to_local_map, true);
    }
    else
    {
        if (variable->type.base_type.indirection_count || is_node_type(variable->type.base_type.node, function_type))
            print(builder, " = null");
        else if (is_node_type(variable->type.base_type.node, number_type))
            print(builder, " = 0");
        else
            print(builder, " = {}");
    }
    
    print(builder, ";");
}

struct single_static_assignments
{
    u32 index, count;
};

void print_scope_label(string_builder *builder, ast_scope *scope)
{
    if (scope->label.count)
        print(builder, "%.*s", fs(scope->label));
    else
        print(builder, "_scope_%i", scope->node.index);
}

void print_scope_statement(lang_c_buffer *buffer, ast_scope *scope, bool add_new_line = true)
{
    auto builder = &buffer->builder;
    
    print_scope_open(builder);
    
    if (scope->first_statement)
        print_statements(buffer, scope->first_statement);
    
    if (scope->requires_begin_label)
    {
        print_newline(builder);
        print_newline(builder);
        print_scope_label(builder, scope);
        print_line(builder, "_begin:;");
    }
    
    print_scope_close(builder, add_new_line && !scope->requires_end_label);
    if (scope->requires_end_label)
    {
        print(builder, " ");
        print_scope_label(builder, scope);

        if (add_new_line)
            print_line(builder, "_end:;");
        else
            print(builder, "_end:;");
    }
    
    if (add_new_line)
        pending_newline(builder);
}

void print_condition_expression(lang_c_buffer *buffer, ast_node *condition, ast_node_index_table *expression_to_local_map)
{
    auto builder = &buffer->builder;
    
    bool requires_parentheses = get_value(expression_to_local_map, condition) != null;    
    if (!requires_parentheses)
    {
        if (is_node_type(condition, binary_operator))
        {
            local_node_type(binary_operator, condition);
            requires_parentheses = binary_operator->function;
        }
        else
        {
            requires_parentheses = true;
        }
    }
    
    if (requires_parentheses)
        print(builder, "(");
        
    print_expression(buffer, condition, expression_to_local_map, false);
    
    if (requires_parentheses)
        print(builder, ")");
}

void print_statement(lang_c_buffer *buffer, ast_node *node, single_static_assignments *local_assignments, bool allow_globals)
{
    bool add_local_array_literals = true;
    switch (node->node_type)
    {
        // skip global declarations
        case ast_node_type_enumeration_type:
        case ast_node_type_alias_type:
        case ast_node_type_function:
        case ast_node_type_number_type:
        case ast_node_type_function_type:
        case ast_node_type_compound_type:
        return;
        
        case ast_node_type_variable:
        {
            local_node_type(variable, node);
            if (!allow_globals && variable->is_global)
                return;
            
            add_local_array_literals = false;
        } break;
        
        case ast_node_type_constant:
        {
            if (!allow_globals && is_node_type(node->parent, file))
                return;
        
            add_local_array_literals = false;
        } break;
    }
    
    auto builder = &buffer->builder;
    
    // print comments and spaces
    {
        auto comment = buffer->parser->node_comments.base[node->index];
        auto lines = comment;
        
        while (lines.count)
        {
            auto line = skip_until_set_or_all(&lines, s("\r\n"));
            bool ok = try_skip(&lines, s("\r"));
            try_skip(&lines, s("\n"));
            if (!ok)
                try_skip(&lines, s("\r"));
                
            try_skip_set(&lines, s(" \t"));
            
            skip_white(&line);
            
            if (line.count)
                print_line(builder, "// %.*s", fs(line));
            else
                print_newline(builder);
        }
    }
    
    auto local_variable_index = local_assignments->index;
    local_assignments->index = local_assignments->count;
    defer { local_assignments->index = local_variable_index; };
    
    auto expression_to_local_map = &buffer->statement_expression_to_local_map;
    if (!expression_to_local_map->count)
        init(expression_to_local_map, 1024);
    else
        clear(expression_to_local_map);
    
    {
        local_buffer(nodes, ast_node_buffer);
    
        local_buffer(queue, ast_queue);
        enqueue_one(&queue, &node);
        
        ast_node *it;
        while (next(&it, &queue))
        {
            assert(local_assignments->index <= local_assignments->count);
        
            switch (it->node_type)
            {
                // don't go into sub scopes
                case ast_node_type_scope:
                case ast_node_type_branch_switch_case:
                {
                    skip_children(&queue, it);
                } break;
                
                case ast_node_type_branch:
                {
                    local_node_type(branch, it);
                    skip_children(&queue, it);
                    
                    enqueue(&queue, it, &branch->condition);
                } break;
                
                case ast_node_type_loop_with_counter:
                {
                    local_node_type(loop_with_counter, it);
                    skip_children(&queue, it);
                    
                    enqueue(&queue, it, &loop_with_counter->end_condition);
                    enqueue(&queue, it, &loop_with_counter->counter_statement);
                } break;
            
                case ast_node_type_loop:
                {
                    local_node_type(loop, it);
                    skip_children(&queue, it);
                    
                    enqueue(&queue, it, &loop->condition);
                } break;
            
                case ast_node_type_branch_switch:
                {
                    local_node_type(branch_switch, it);
                    skip_children(&queue, it);
                    
                    enqueue(&queue, it, &branch_switch->condition);
                } break;
                
                case ast_node_type_array_literal:
                {
                    if (!add_local_array_literals)
                        break;
                    
                    resize_buffer(&nodes, nodes.count + 1);
                    nodes.base[nodes.count - 1] = it;
                } break;

                case ast_node_type_get_type_info:
                {                                        
                    resize_buffer(&nodes, nodes.count + 1);
                    nodes.base[nodes.count - 1] = it;
                } break;
                            
                case ast_node_type_compound_literal:
                {
                    local_node_type(compound_literal, it);
                    
                    if (!compound_literal->first_argument)
                        break;
                
                    // copy typed_values on the stack, so we can take a reference to them
                    auto name_type = compound_literal->type.name_type.node;
                    if (name_type == get_type(buffer->parser, lang_base_type_lang_typed_value).name_type.node)
                    {
                        ast_node *expression = null;
                        for (auto argument = compound_literal->first_argument; argument; argument = (ast_argument *) argument->node.next)
                        {
                            if (argument->name == s("value"))
                            {
                                auto cast = get_node_type(unary_operator, argument->expression);
                                if (cast->operator_type == ast_unary_operator_type_cast)
                                {
                                    if (is_node_type(cast->expression, unary_operator))
                                    {
                                        auto take_reference = get_node_type(unary_operator, cast->expression);
                                        if (take_reference->operator_type == ast_unary_operator_type_take_reference)
                                        {
                                            if (!is_assignable(take_reference->expression))
                                                expression = take_reference->expression;
                                        }
                                    }
                                }
                                
                                break;
                            }
                        }
                        
                        if (expression)
                        {
                            resize_buffer(&nodes, nodes.count + 1);
                            nodes.base[nodes.count - 1] = expression;
                        }
                    }
                    else if ((name_type == get_type(buffer->parser, lang_base_type_lang_type_info).name_type.node) || (name_type == get_type(buffer->parser, lang_base_type_lang_code_location).name_type.node))
                    {
                        resize_buffer(&nodes, nodes.count + 1);
                        nodes.base[nodes.count - 1] = it;
                    }
                } break;
            }
        }
        
        local_assignments->count += nodes.count;

        bool is_first = true;
        
        for (u32 i = 0; i < nodes.count; i++)
        {
            auto it = nodes.base[nodes.count - 1 - i];
        
            auto index = local_assignments->count - i - 1;
            maybe_print_newline(builder);
            
            switch (it->node_type)
            {
                #if 0
                case ast_node_type_array_literal:
                {
                    local_node_type(array_literal, it);
                    
                    print_type(buffer, array_literal->type);
                    print(builder, " __local_%u = ", index);
                    
                    local_assignments->index = index;
                    print_array_literal(buffer, array_literal, expression_to_local_map);
                    print_line(builder, ";");
                    
                    u32 *value;
                    bool is_new = hash_table_insert(&value, expression_to_local_map, it);
                    assert(is_new);
                    *value = index;
                } break;                                
                            
                case ast_node_type_compound_literal:
                {
                    local_node_type(compound_literal, it);
                                        
                
                    print_type(buffer, compound_literal->type);
                    print(builder, " __local_%u = ", index);
                    
                    local_assignments->index = index;
                    print_compound_literal(buffer, compound_literal, expression_to_local_map, false);                                                    
                    print_line(builder, ";");
                    
                    u32 *value;
                    bool is_new = hash_table_insert(&value, expression_to_local_map, it);
                    assert(is_new);
                    *value = index;                    

                    #if 0
                    
                    // so we can initialize fields by name 
                    for (auto argument = compound_literal->first_argument; argument; argument = (ast_argument *) argument->node.next)
                    {
                        print(builder, " __local_%u.%.*s = ", index, fs(argument->name));
                        print_expression(buffer, argument->expression, expression_to_local_map, false);
                        print_line(builder, ";");
                    }
                    #endif
                    
                } break;            
                #endif
            
                default:
                {
                    if (is_first)
                    {
                        print_newline(builder);
                        is_first = false;
                    }

                    auto expression = it;
                    auto type = get_expression_type(buffer->parser, expression);
                    print_type(buffer, type);
                    print(builder, " __local_%u = ", index);
                    
                    local_assignments->index = index;
                    print_expression(buffer, expression, expression_to_local_map, false);
                    print_line(builder, ";");
                    
                    u32 *value;
                    bool is_new = insert(&value, expression_to_local_map, it);
                    assert(is_new);
                    *value = index;
                } break;
            }
        }
        
        local_assignments->index = local_assignments->count - nodes.count;

        // add some space for better readability
        if (nodes.count)
            print_newline(builder);
    }    

    switch (node->node_type)
    {
        case ast_node_type_scope:
        {
            local_node_type(scope, node);
            
            maybe_print_blank_line(builder);
            print_scope_statement(buffer, scope);
        } break;
        
        case ast_node_type_constant:
        {
            local_node_type(constant, node);
            print_constant_declaration(buffer, constant, expression_to_local_map);
        } break;

        case ast_node_type_variable:
        {
            local_node_type(variable, node);
            
            print_variable_statement(buffer, variable, expression_to_local_map);
            print_newline(builder);
        } break;
        
        case ast_node_type_assignment:
        {
            local_node_type(assignment, node);
            
            print_expression(buffer, assignment->left, expression_to_local_map, false);
            print(builder, " = ");
            print_expression(buffer, assignment->right, expression_to_local_map, false);
            print_line(builder, ";");
        } break;

        case ast_node_type_branch:
        {
            local_node_type(branch, node);
        
            maybe_print_blank_line(builder);
            
            if (branch->scope.requires_begin_label || branch->scope.requires_end_label)
            {
                print(builder, "// label ");
                print_scope_label(builder, &branch->scope);
                print_newline(builder);
            }
            
            print(builder, "if ");
            print_condition_expression(buffer, branch->condition, expression_to_local_map);
            
            print_scope_open(builder);
            
            if (branch->scope.first_statement)
                print_statements(buffer, branch->scope.first_statement);
                
            print_scope_close(builder, branch->false_scope || !branch->scope.requires_end_label);
            
            if (branch->false_scope)
            {
                print(builder, "else");
                print_scope_open(builder);
                print_statements(buffer, branch->false_scope->first_statement);
                print_scope_close(builder, !branch->scope.requires_end_label);
            }
            
            if (branch->scope.requires_end_label)
            {
                print(builder, " ");
                print_scope_label(builder, &branch->scope);
                print_line(builder, "_end:;");
            }
            
            pending_newline(builder);
        } break;
        
        case ast_node_type_loop:
        {
            local_node_type(loop, node);
        
            maybe_print_blank_line(builder);
            
            if (loop->scope.requires_begin_label || loop->scope.requires_end_label)
            {
                print(builder, "// label ");
                print_scope_label(builder, &loop->scope);
                print_newline(builder);
            }
            
            print(builder, "while ");
            print_condition_expression(buffer, loop->condition, expression_to_local_map);
            
            print_scope_statement(buffer, &loop->scope);
        } break;
        
        case ast_node_type_loop_with_counter:
        {
            local_node_type(loop_with_counter, node);
        
            maybe_print_blank_line(builder);
            
            if (loop_with_counter->scope.requires_begin_label || loop_with_counter->scope.requires_end_label)
            {
                print(builder, "// label ");
                print_scope_label(builder, &loop_with_counter->scope);
                print_newline(builder);
            }
            
            print(builder, "for (");
            
            if (is_node_type(loop_with_counter->counter_statement, variable))
            {
                local_node_type(variable, loop_with_counter->counter_statement);
                print_variable_statement(buffer, variable, expression_to_local_map);
            }
            else
            {
                print_expression(buffer, loop_with_counter->counter_statement, expression_to_local_map, false);
                print(builder, ";");
            }
            
            string counter_name = get_name(loop_with_counter->counter_statement);
            assert(counter_name.count);
            
            print(builder, " %.*s < ", fs(counter_name));
            print_expression(buffer, loop_with_counter->end_condition, expression_to_local_map, false);
            print(builder, "; %.*s++)", fs(counter_name));
            
            print_scope_statement(buffer, &loop_with_counter->scope);
            
        } break;
        
        case ast_node_type_branch_switch:
        {
            local_node_type(branch_switch, node);
        
            maybe_print_blank_line(builder);
            
            print(builder, "switch (");
            print_expression(buffer, branch_switch->condition, expression_to_local_map, false);
            print(builder, ")");
            
            print_scope_open(builder);
            
            for (auto branch_case = branch_switch->first_case; branch_case; branch_case = (ast_branch_switch_case *) branch_case->node.next)
            {
                for (auto expression = branch_case->first_expression; expression; expression = expression->next)
                {
                    print(builder, "case ");
                    print_expression(buffer, expression, expression_to_local_map, false);
                    print_line(builder, ":");
                }
                
                print_scope_statement(buffer, &branch_case->scope, false);
                print_line(builder, " break;");
                
                if (branch_switch->default_case_scope || branch_case->node.next)
                    print_newline(builder);
            }
            
            if (branch_switch->default_case_scope)
            {
                print(builder, "default:");
                print_scope_statement(buffer, branch_switch->default_case_scope);
            }
                
            print_scope_close(builder);
            
            pending_newline(builder);
        } break;
        
        case ast_node_type_scope_control:
        {
            local_node_type(scope_control, node);
            
            maybe_print_blank_line(builder);
            
            auto name = ast_scope_control_names[scope_control->is_continue];
                        
            auto requires_goto = scope_control_requires_label(scope_control);            
            
            if (scope_control->label.count || requires_goto)
            {
                print_comment_begin(buffer);
                print(builder, "%.*s ", fs(name));
                print_scope_label(builder, scope_control->scope);
                print_comment_end(buffer);
            }
            
            if (!requires_goto)
                print(builder, "%.*s;", fs(name));
            else
            {
                print(builder, "goto ");
                print_scope_label(builder, scope_control->scope);
                if (scope_control->is_continue)
                    print_line(builder, "_begin;");
                else
                    print_line(builder, "_end;");
            }
        } break;
        
        case ast_node_type_function_return:
        {
            local_node_type(function_return, node);
            
            maybe_print_blank_line(builder);
            
            if (function_return->first_expression)
            {
                // TODO: specify result type depending on the current function
                if (function_return->first_expression->next)
                    print(builder, "return { ");
                else
                    print(builder, "return ");
            }
            else
            {
                print(builder, "return");
            }
            
            for (auto expression = function_return->first_expression; expression; expression = expression->next)
            {
                print_expression(buffer, expression, expression_to_local_map, false);
                
                if (expression->next)
                    print(builder, ", ");
            }
            
            if (function_return->first_expression && function_return->first_expression->next)
                print(builder, " }");
            
            print(builder, ";");
        } break;
        
        // try expressions
        default:
        {
            print_expression(buffer, node, expression_to_local_map, false);
            print_line(builder, ";");
        } break;
    }
}

print_statements_declaration
{
    auto builder = &buffer->builder;

    single_static_assignments local_assignments = {};

    local_buffer(queue, ast_queue);
    
    enqueue(&queue, &first_statement);
    
    ast_node *node;
    while (print_next(&node, &queue))
    {
        //print_buffer(buffer, "#line %i",
        
        print_statement(buffer, node, &local_assignments, false);
    }
}

string lang_c_base_type_names[] =
{
    s("NULL"),
    s("char *"),
    
    s("unsigned char"),
    s("unsigned short"),
    s("unsigned int"),
    s("unsigned long long"),
    
    s("signed char"),
    s("signed short"),
    s("signed int"),
    s("signed long long"),
    
    s("float"),
    s("double"),
};

enum lang_c_base_type
{
    lang_c_base_type_null,
    lang_c_base_type_cstring,
    
    lang_c_base_type_u8,
    lang_c_base_type_u16,
    lang_c_base_type_u32,
    lang_c_base_type_u64,
    lang_c_base_type_usize,
    
    lang_c_base_type_s8,
    lang_c_base_type_s16,
    lang_c_base_type_s32,
    lang_c_base_type_s64,
    lang_c_base_type_ssize,
    
    lang_c_base_type_f32,
    lang_c_base_type_f64,
};

u8 _lang_c_base_type_name_buffer[2048];

string write_va(string *memory, cstring format, va_list va_arguments)
{
    usize count = _vsprintf_p((char *) memory->base, memory->count, format, va_arguments);
    
    string result = { count, memory->base };
    advance(memory, count);
    
    return result;
}

string write(string *memory, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);
    
    auto result = write_va(memory, format, va_arguments);
    
    va_end(va_arguments);
    
    return result;
}

bool is_function_return_type_compound(ast_function_type *function_type)
{
    if (!function_type->output.name_type.node)
        return false;
        
    local_node_type(compound_type, function_type->output.name_type.node);

    return (compound_type->first_field && compound_type->first_field->node.next);
}

void print_function_return_type(lang_c_buffer *buffer, ast_function_type *function_type)
{
    auto builder = &buffer->builder;
    
    auto output = function_type->output;
    if (type_is_not_empty(output))
    {
        local_node_type(compound_type, output.base_type.node);
    
        if (is_function_return_type_compound(function_type))
        {
            print_type(buffer, output);
        }
        else
        {
            auto variable = compound_type->first_field;
            print_type(buffer, variable->type);
        }
    }
    else
    {
        print(builder, "void");
    }
}

void print_function_type(lang_c_buffer *buffer, ast_function_type *function_type, string name, ast_function *function)
{    
    auto builder = &buffer->builder;

    print_function_return_type(buffer, function_type);
    
    if (function)
    {
        if (function_type->calling_convention.count)
            print(builder, " %.*s", fs(function_type->calling_convention));
        
        print(builder, " ");
        print_function_name(builder, function);
        print(builder, "(");
    }
    else
    {
        print(builder, " (");
        
        if (function_type->calling_convention.count)
            print(builder, "%.*s ", fs(function_type->calling_convention));
        
        print(builder, "*%.*s)(", fs(name));
    }
    
    bool is_not_first = false;
    
    if (type_is_not_empty(function_type->input))
    {
        local_node_type(compound_type, function_type->input.base_type.node);
        
        for (auto argument = compound_type->first_field; argument; argument = (ast_variable *) argument->node.next)
        {
            if (is_not_first)
                print(builder, ", ");
                    
            print_declaration(buffer, argument);
                
            is_not_first = true;
        }
    }
    
    print(builder, ")");
}

void print_type_declaration(lang_c_buffer *buffer, lang_complete_type type, string name = {})
{
    auto builder = &buffer->builder;
    auto parser = buffer->parser;
    auto name_type = type.name_type.node;
    
    name_type = get_unique_node(parser, name_type);
    
    if (!name_type || type.name_type.indirection_count || is_node_type(name_type, number_type))
    {
        print(builder, "typedef ");
        print_type(buffer, type, name);
                
        print_line(builder, ";");
        
        return;
    } 
        
    switch (name_type->node_type)
    {
        default:
        {
            print(builder, "typedef ");
            print_type(buffer, type, name);
                    
            print_line(builder, ";");
        } break;
        
        case ast_node_type_function_type:
        {
            local_node_type(function_type, name_type);
            
            print(builder, "typedef ");
            print_function_type(buffer, function_type, name, null);
            print_line(builder, ";");
        } break;
        
        case ast_node_type_compound_type:
        case ast_node_type_union_type:
        {
            auto compound_or_union_type = (ast_compound_type *) name_type;
            
            if (name_type->node_type == ast_node_type_union_type)
                print(builder, "union ");
            else
                print(builder, "struct ");
                
            if (name.count)
                print(builder, "%.*s", fs(name));
            else
            {
                print_type(buffer, type);
            }
                
            print_scope_open(builder);
        
            for (auto field = compound_or_union_type->first_field; field; field = (ast_variable *) field->node.next)
            {
                print_declaration(buffer, field);
                print_line(builder, ";");
            }
            
            print_scope_close(builder, false);
            print_line(builder, ";");
        } break;
        
        case ast_node_type_array_type:
        {
            local_node_type(array_type, name_type);
            
            print_line(builder, "typedef struct");
            print_scope_open(builder);
            
            if (array_type->item_count_expression)
            {
                auto item_count = get_array_item_count(array_type);
                print_type(buffer, array_type->item_type, s("base["));
                print_line(builder, "%llu];", item_count);
            }
            else
            {
                print_line(builder, "usize count;");
            
                print_type(buffer, array_type->item_type, s("*base"));
                print_line(builder, ";");
            }
            
            print_scope_close(builder, false);
            if (name.count)
                print_line(builder, " %.*s;", fs(name));
            else
            {
                print(builder, " ");
                print_type(buffer, type);
                print_line(builder, ";");
            }
        } break;
        
        case ast_node_type_enumeration_type:
        {
            local_node_type(enumeration_type, name_type);
            
            print(builder, "typedef ");
            print_type(buffer, enumeration_type->item_type, name);
            print_line(builder, ";");
            
            auto base_type = enumeration_type->item_type.base_type.node;
            while (is_node_type(base_type, enumeration_type))
            {
                local_node_type(enumeration_type, base_type);
                base_type = enumeration_type->item_type.base_type.node;
            }

            local_node_type(number_type, base_type);
            
            ast_enumeration_item *last_item_with_expression = null;            

            while (enumeration_type)            
            {
                for (auto item = enumeration_type->first_item; item; item = (ast_enumeration_item *) item->node.next)
                {
                    print(builder, "const %.*s %.*s_%.*s = ", fs(name), fs(name), fs(item->name));
                    
                    assert(item->expression);
                    
                    if (!is_node_type(item->expression, number))
                    {
                        print_comment_begin(buffer);
                        print_expression(buffer, item->expression, null, false);
                        print_comment_end(buffer);
                    }
                    
                    parsed_number number = {};
                    number.is_signed = number_type->is_signed;
                    number.u64_value = get_enumeration_item_value(item);
                    number.bit_count_power_of_two = number_type->bit_count_power_of_two;// get_bit_count_power_of_two(number.u64_value);
                    

                    print_number(buffer, number);
                    print_line(builder, ";");
                }

                auto base_type = enumeration_type->item_type.base_type.node;
                if (!is_node_type(base_type, enumeration_type))
                    break;
                
                enumeration_type = get_node_type(enumeration_type, base_type);
            }
        } break;
    }
}

lang_c_buffer compile(lang_parser *parser, lang_c_compile_settings settings = {})
{
    lang_c_buffer buffer = {};
    buffer.settings = settings;
    buffer.parser = parser;

    if (!buffer.settings.use_default_types)
    {
    
    }

    auto builder = &buffer.builder;

    print_newline(builder);
    print_line(builder, "// generated with lang compiler");
    
    string name_buffer = { carray_count(_lang_c_base_type_name_buffer), _lang_c_base_type_name_buffer };
    
    if (!buffer.settings.use_default_types)
    {
        //lang_c_base_type_names[lang_c_base_type_null]    = write(&name_buffer, "%.*snull", fs(buffer.settings.prefix));
        //lang_c_base_type_names[lang_c_base_type_cstring] = write(&name_buffer, "%.*scstring", fs(buffer.settings.prefix));
    
        print_newline(builder);
    
        for (u32 i = 0; i < 4; i++)
        {
            u32 bit_count = (8 << i);
            
            //lang_c_base_type_names[lang_c_base_type_u8 + i] = write(&name_buffer, "%.*su%i", fs(buffer.settings.prefix), bit_count);
            //lang_c_base_type_names[lang_c_base_type_s8 + i] = write(&name_buffer, "%.*ss%i", fs(buffer.settings.prefix), bit_count);
            
            //print_line(builder, "typedef unsigned __int%i %.*su%i;", bit_count, fs(buffer.settings.prefix), bit_count);
            //print_line(builder, "typedef   signed __int%i %.*ss%i;", bit_count, fs(buffer.settings.prefix), bit_count);
            
            print_line(builder, "typedef %.*s %.*su%i;", fs(lang_c_base_type_names[2 + i]), fs(buffer.settings.prefix), bit_count);
            print_line(builder, "typedef %.*s %.*ss%i;", fs(lang_c_base_type_names[6 + i]), fs(buffer.settings.prefix), bit_count);
        }
        
        //lang_c_base_type_names[lang_c_base_type_usize] = write(&name_buffer, "%.*susize", fs(buffer.settings.prefix));
        //lang_c_base_type_names[lang_c_base_type_ssize] = write(&name_buffer, "%.*sssize", fs(buffer.settings.prefix));
        
        print_newline(builder);
        print_line(builder, "typedef %.*su64 %.*susize;", fs(buffer.settings.prefix), fs(buffer.settings.prefix));
        print_line(builder, "typedef %.*ss64 %.*sssize;", fs(buffer.settings.prefix), fs(buffer.settings.prefix));
        
        //lang_c_base_type_names[lang_c_base_type_f32] = write(&name_buffer, "%.*sf32", fs(buffer.settings.prefix));
        //lang_c_base_type_names[lang_c_base_type_f64] = write(&name_buffer, "%.*sf64", fs(buffer.settings.prefix));
        print_newline(builder);
        print_line(builder, "typedef float  %.*sf32;", fs(buffer.settings.prefix));
        print_line(builder, "typedef double %.*sf64;", fs(buffer.settings.prefix));
        
        // since char and unsgined char and signed char are not the same according to C ...
        print_newline(builder);
        print_line(builder, "typedef char *%.*scstring;", fs(buffer.settings.prefix));
        
        print_newline(builder);
        print_line(builder, "#define %.*snull 0", fs(buffer.settings.prefix));
        
        print_newline(builder);
        print_line(builder, "#if defined _WIN32");
        print_line(builder, "#define LANG_LIB_IMPORT __declspec(dllimport)");
        print_line(builder, "#define LANG_LIB_EXPORT __declspec(dllexport)");
        print_line(builder, "#else ");
        print_line(builder, "#define LANG_LIB_IMPORT");
        print_line(builder, "#define LANG_LIB_EXPORT");
        print_line(builder, "#endif");
    }
    
    auto root = get_base_node(parser->file_list.first);

    // collect and print all intrinsics
    {
        ast_list_entry *first_intrinsic = null;
        auto intrinsic_tail_next = &first_intrinsic;
    
        maybe_print_blank_line(builder);
        
        for_bucket_item(bucket, index, parser->function_buckets)
        {
            auto function = &bucket->base[index];

            if (!is_required(parser, get_base_node(function)))
                continue;
            
            if (function->first_statement && (function->first_statement->node_type == ast_node_type_intrinsic))
            {
                local_node_type(intrinsic, function->first_statement);
                string header = intrinsic->header;
            
                bool found = false;
                for (auto it = first_intrinsic; it; it = it->next)
                {
                    local_node_type(intrinsic, it->node);
                    
                    if (header == intrinsic->header)
                    {
                        found = true;
                        break;
                    }
                }
                
                if (!found)
                {
                    auto new_entry = new ast_list_entry;
                    *new_entry = {};
                    new_entry->node  = get_base_node(intrinsic);
                    
                    *intrinsic_tail_next = new_entry;
                    intrinsic_tail_next = &new_entry->next;
                    
                    if (intrinsic->header.count)
                        print_line(builder, "#include <%.*s>", fs(intrinsic->header));
                }
            }
        }
    }

    // collect and print all external bindings
    {
        ast_list_entry *first_external_binding = null;
        auto external_binding_tail_next = &first_external_binding;
        
        for_bucket_item(bucket, index, parser->function_buckets)
        {
            auto function = &bucket->base[index];
            
            if (!is_required(parser, get_base_node(function)))
                continue;

            if (function->first_statement && (function->first_statement->node_type == ast_node_type_external_binding))
            {
                local_node_type(external_binding, function->first_statement);
                string library_name = external_binding->library_name;
            
                bool found = false;
                for (auto it = first_external_binding; it; it = it->next)
                {
                    local_node_type(external_binding, it->node);
                    
                    if (library_name == external_binding->library_name)
                    {
                        found = true;
                        break;
                    }
                }
                
                if (!found)
                {
                    auto new_entry = new ast_list_entry;
                    *new_entry = {};
                    new_entry->node  = get_base_node(external_binding);
                    
                    *external_binding_tail_next = new_entry;
                    external_binding_tail_next = &new_entry->next;
                }
            }
        }
        
        maybe_print_blank_line(builder);
        print_newline(builder);
        print_line(builder, "#if defined _WIN32");
        
        for (auto it = first_external_binding; it; it = it->next)
        {
            local_node_type(external_binding, it->node);
            print_line(builder, "#pragma comment(lib, \"%.*s\")", fs(external_binding->library_name));
        }
        
        print_line(builder, "#endif");
    }
    
    lang_require_call_return_value(sort_declaration_dependencies(&buffer), buffer);
    //printf("pair_table used count: %.2f %llu / %llu\n", buffer.graph.pair_table.used_count * 100.0f / (f32) buffer.graph.pair_table.count, buffer.graph.pair_table.used_count, buffer.graph.pair_table.count);
    
    auto sorted_dependencies = buffer.sorted_dependencies;
    defer { free_dependencies(&buffer); };
    
    // declare typedefs, structs and functions in order of dependency
    {
        string_builder print_builder = {};
        defer { free_buffer(&print_builder.memory); };
        
        // forward declare unions and structs
        {
            print_newline(builder);
            
            for (u32 i = 0; i < sorted_dependencies.count; i++)
            {
                auto node = sorted_dependencies.base[i];
                
                switch (node->node_type)
                {
                    case ast_node_type_alias_type:
                    {
                        local_node_type(alias_type, node);
                            
                        auto type = to_type(parser, node);
                        if (is_node_type(alias_type->type.name_type.node, compound_type) || is_node_type(alias_type->type.name_type.node, union_type))
                        {
                            if (is_node_type(alias_type->type.name_type.node, compound_type))
                                print(builder, "typedef struct ");
                            else
                                print(builder, "typedef union ");
                            
                            print_type(&buffer, type);
                            print(builder, " ");
                            print_type(&buffer, type);
                            print_line(builder, ";");
                        }
                        else
                        {
                        }
                    } break;
                
                    case ast_node_type_compound_type:
                    case ast_node_type_union_type:
                    {
                        auto compound_or_union_type = (ast_compound_or_union_type *) node;
                        
                        auto type = to_type(parser, node);
                        
                        if (node->node_type == ast_node_type_compound_type)
                            print(builder, "typedef struct ");
                        else
                            print(builder, "typedef union ");
                            
                        print_type(&buffer, type);
                        print(builder, " ");
                        print_type(&buffer, type);
                        print_line(builder, ";");
                    } break;
                }
            }
        }
        
        u32 previous_type = -1;
        for (u32 i = 0; i < sorted_dependencies.count; i++)
        {
            auto node = sorted_dependencies.base[i];
            
            // filter some declarations that would clash with C
            {
                bool do_skip = false;
                
                string skip_list[] =
                {
                    lang_base_type_names[lang_base_type_cstring],
                    lang_base_constant_names[lang_base_constant_null],
                    lang_base_constant_names[lang_base_constant_false],
                    lang_base_constant_names[lang_base_constant_true],
                };
                
                auto node_name = get_name(node);
                for (u32 i = 0; i < carray_count(skip_list); i++)
                {
                    if (node_name == skip_list[i])
                    {
                        do_skip = true;
                        break;
                    }
                }
                
                if (do_skip)
                    continue;
            }
            
            builder->pending_newline = (previous_type != node->node_type);
            
            switch (node->node_type)
            {
                cases_complete_message("%.*s", fs(ast_node_type_names[node->node_type]));
                                
                case ast_node_type_module:
                case ast_node_type_number_type:
                 // assumed to be part of type alias
                case ast_node_type_enumeration_type:
                case ast_node_type_function_type:
                break;
                
                case ast_node_type_variable:
                {
                    local_node_type(variable, node);
                    assert(variable->is_global);
                    
                    single_static_assignments local_assingments = {};
                    print_statement(&buffer, node, &local_assingments, true);
                    assert(local_assingments.count == 0);
                } break;
                
                case ast_node_type_constant:
                {
                    local_node_type(constant, node);
                
                    assert(is_node_type(constant->node.parent, file));
                
                    if (constant->node.parent == get_base_node(parser->lang_file))
                        continue;
                
                    single_static_assignments local_assingments = {};
                    print_statement(&buffer, node, &local_assingments, true);
                    assert(local_assingments.count == 0);
                } break;
                
                case ast_node_type_compound_type:
                case ast_node_type_union_type:
                {
                    auto compound_or_union_type = (ast_compound_or_union_type *) node;
                    
                    if (is_node_type(compound_or_union_type->node.parent, alias_type))
                        continue;
                    
                    print_type_declaration(&buffer, to_type(parser, get_base_node(compound_or_union_type)));
                    
                    // force newline
                    previous_type = -1;
                    continue;
                } break;
            
                case ast_node_type_array_type:
                {
                    auto type = to_type(parser, node);
                    print_type_declaration(&buffer, type);
                    
                    // force newline
                    previous_type = -1;
                    continue;
                } break;
                
                case ast_node_type_alias_type:
                {
                    local_node_type(alias_type, node);
                    
                    if (is_node_type(alias_type->type.base_type.node, array_type))
                    {
                        print(builder, "typedef ");
                        print_type(&buffer, alias_type->type, alias_type->name);
                        print_line(builder, ";");
                    }
                    else
                    {                        
                        print_type_declaration(&buffer, alias_type->type, alias_type->name);
                    }
                    
                    if (is_node_type(alias_type->type.base_type.node, array_type) || is_node_type(alias_type->type.base_type.node, compound_type) || is_node_type(alias_type->type.base_type.node, enumeration_type))
                    {
                        // force newline
                        previous_type = -1;
                        continue;
                    }
                } break;
                
                case ast_node_type_function:
                {
                    local_node_type(function, node);
                    
                    local_node_type(function_type, function->type.base_type.node);
          
                    if (function->first_statement)
                    {
                        if (is_node_type(function->first_statement, external_binding))
                        {
                            local_node_type(external_binding, function->first_statement);
                            
                            print(builder, "extern \"C\" ");
                            
                            if (external_binding->is_dll)
                                print(builder, "LANG_LIB_IMPORT ");
                        }
                        else if (is_node_type(function->first_statement, intrinsic))
                        {
                            // nothing to print
                            continue;
                        }
                    }
                    
                    if (function->do_export)
                        print(builder, "extern \"C\" LANG_LIB_EXPORT ");
                    
                    print_function_type(&buffer, function_type, function->name, function);
                    
                    print_line(builder, ";");
                } break;                
            }
            
            // only if node was not skipped
            previous_type = node->node_type;
        }
    }
    
    // declare type table
    {
        auto unique_types = &parser->unique_types;
    
        auto type_table = parser->base_constants[lang_base_constant_lang_type_table];
        auto type = get_expression_type(parser, type_table->expression);
        local_node_type(compound_type, type.base_type.node);
        
        u32 global_variable_count = 0;
        
        print(builder, "const struct");
        print_scope_open(builder);
        for (auto field = compound_type->first_field; field; field = (ast_variable *) field->node.next)
        {
            local_node_type(array_type, field->type.base_type.node);
            print(builder, "struct { ");
            print_type(&buffer, array_type->item_type);
            print_line(builder, " base[%u]; } %.*s;", maximum(1llu, get_array_item_count(array_type)), fs(field->name));
        }
        
        
        #if 0
        
        print_line(builder, "struct { lang_type_info_enumeration      base[%u]; } enumeration_types;", maximum(1llu, parser->enumeration_type_buckets.item_count));
        print_line(builder, "struct { lang_type_info_enumeration_item base[%u]; } enumeration_items;", maximum(1u, enumeration_item_count));
        print_line(builder, "struct { lang_type_info_array            base[%u]; } array_types;", maximum(1llu, unique_types->unique_array_type_buckets.item_count));
        print_line(builder, "struct { lang_type_info_compound         base[%u]; } compound_types;", maximum(1u, compound_count));
        print_line(builder, "struct { lang_type_info_compound_field   base[%u]; } compound_fields;", maximum(1u, compound_field_count));
        print_line(builder, "struct { lang_type_info_union            base[%u]; } union_types;", maximum(1u, union_count));
        print_line(builder, "struct { lang_type_info_union_field      base[%u]; } union_fields;", maximum(1u, union_field_count));
        print_line(builder, "struct { lang_type_info_function         base[%u]; } function_types;",  maximum(1llu, unique_types->unique_function_type_buckets.item_count));
        #endif
        
        print_scope_close(builder, false);
        
        print_line(builder, " lang_type_table =");
        
        print_scope_open(builder);
        
        string bool_names[] =
        {
            s("false"),
            s("true"),
        };
        
        auto field = compound_type->first_field;

        // number types
        {
            assert(field->name == s("number_types"));
            local_node_type(array_type, field->type.base_type.node);
            assert(get_array_item_count(array_type) == parser->number_type_buckets.item_count)
            field = (ast_variable *) field->node.next;

            print_scope_open(builder);
            for_bucket_item(bucket, index, parser->number_type_buckets)
            {
                auto number_type = &bucket->base[index];
                print_line(builder, "lang_type_info_number { lang_type_info_number_type_%.*s, %u, %.*s, %.*s },", fs(number_type->name), 1 << (number_type->bit_count_power_of_two - 3), fs(bool_names[number_type->is_float]), fs(bool_names[number_type->is_signed]));
            }
            print_scope_close(builder, false);
            print_line(builder, ",");
        }
        
        // enumeration types
        {
            assert(field->name == s("enumeration_types"));
            local_node_type(array_type, field->type.base_type.node);
            assert(get_array_item_count(array_type) == parser->enumeration_type_buckets.item_count)
            field = (ast_variable *) field->node.next;

            u32 enumeration_item_offset = 0;
            print_scope_open(builder);
            for_bucket_item(bucket, index, parser->enumeration_type_buckets)
            {
                auto enumeration_type = &bucket->base[index];
                print(builder, "lang_type_info_enumeration { ");
                print_type_info(&buffer, enumeration_type->item_type);
                print_line(builder, ", { %u, (lang_type_info_enumeration_item *) &lang_type_table.enumeration_item_types.base[%u] } },", enumeration_type->item_count, enumeration_item_offset);
                enumeration_item_offset += enumeration_type->item_count;
            }            
            print_scope_close(builder, false);
            print_line(builder, ",");
        }
        
        // enumeration items
        {
            assert(field->name == s("enumeration_item_types"));
            local_node_type(array_type, field->type.base_type.node);            
            field = (ast_variable *) field->node.next;

            print_scope_open(builder);
            u32 enumeration_item_count = 0;
            for_bucket_item(bucket, index, parser->enumeration_type_buckets)
            {
                auto enumeration_type = &bucket->base[index];
                
                local_buffer(nodes, ast_node_buffer);
                
                // add all inherited enumeration type items first
                {
                    auto it = enumeration_type;
                    while (it)
                    {
                        resize_buffer(&nodes, nodes.count + 1);
                        nodes.base[nodes.count - 1] = get_base_node(it);
                        
                        auto base = it->item_type.base_type.node;
                        if (!is_node_type(base, enumeration_type))
                            break;
                            
                        it = (ast_enumeration_type *) base;
                    }
                }
                
                u32 item_count = 0;
                
                for (u32 i = 0; i < nodes.count; i++)
                {
                    u32 reverse_i = nodes.count - 1 - i;
                    local_node_type(enumeration_type, nodes.base[reverse_i]);
                
                    for (auto item = enumeration_type->first_item; item; item = (ast_enumeration_item *) item->node.next)
                    {
                        print_line(builder, "lang_type_info_enumeration_item { { %llu, (u8 *) \"%.*s\" }, %llu },", item->name.count, fs(item->name), get_enumeration_item_value(item));
                        item_count++;
                    }
                }
                
                assert(item_count == enumeration_type->item_count);
                enumeration_item_count += item_count;
            }
            print_scope_close(builder, false);
            print_line(builder, ",");

            assert(get_array_item_count(array_type) == enumeration_item_count);
        }
        
        // array types
        {
            assert(field->name == s("array_types"));
            local_node_type(array_type, field->type.base_type.node);
            assert(get_array_item_count(array_type) == unique_types->unique_array_type_buckets.item_count)
            field = (ast_variable *) field->node.next;

            print_scope_open(builder);
            for_bucket_item(bucket, index, unique_types->unique_array_type_buckets)
            {
                auto array_type = &bucket->base[index];
                
                print(builder, "lang_type_info_array { ");
                print_type_info(&buffer, array_type->item_type);
                
                usize item_count = 0;
                if (array_type->item_count_expression)
                    item_count = get_array_item_count(array_type);
                
                print_line(builder, ", %llu, %llu },", item_count, item_count * get_type_byte_count_and_alignment(array_type->item_type).byte_count);
            }
            print_scope_close(builder, false);
            print_line(builder, ",");
        }
        
        // compound types
        {            
            assert(field->name == s("compound_types"));
            local_node_type(array_type, field->type.base_type.node);
            assert(get_array_item_count(array_type) == unique_types->unique_compound_type_buckets.item_count)
            field = (ast_variable *) field->node.next;
            
            u32 field_count = 0;
            print_scope_open(builder);
            for_bucket_item(bucket, index, unique_types->unique_compound_type_buckets)
            {
                auto compound_type = &bucket->base[index];
                
                // update byte count and alignment
                get_type_byte_count_and_alignment(to_type(parser, get_base_node(compound_type)));
                
                print_line(builder, "lang_type_info_compound { { %u, (lang_type_info_compound_field *) &lang_type_table.compound_field_types.base[%u] }, %u, %u },", compound_type->field_count, field_count, compound_type->byte_count, compound_type->byte_alignment);
                field_count += compound_type->field_count;
            }            
            print_scope_close(builder, false);
            print_line(builder, ",");
            
            // compound fields
            {
                assert(field->name == s("compound_field_types"));
                local_node_type(array_type, field->type.base_type.node);
                assert(get_array_item_count(array_type) == field_count);
                field = (ast_variable *) field->node.next;
                
                print_scope_open(builder);
                for_bucket_item(bucket, index, unique_types->unique_compound_type_buckets)
                {
                    auto compound_type = &bucket->base[index];
                    
                    for (auto field = compound_type->first_field; field; field = (ast_variable *) field->node.next)
                    {
                        print(builder, "lang_type_info_compound_field { ");
                        print_type_info(&buffer, field->type);
                    
                        print_line(builder, ", { %llu, (u8 *) \"%.*s\" }, %u },", field->name.count, fs(field->name), field->field_byte_offset);
                    }
                }
                print_scope_close(builder, false);
                print_line(builder, ",");
            }   
        }
        
        // union types
        {
            assert(field->name == s("union_types"));
            local_node_type(array_type, field->type.base_type.node);
            assert(get_array_item_count(array_type) == unique_types->unique_union_type_buckets.item_count)
            field = (ast_variable *) field->node.next;
            
            u32 field_count = 0;
            print_scope_open(builder);
            for_bucket_item(bucket, index, unique_types->unique_union_type_buckets)
            {
                auto union_type = &bucket->base[index];
                
                // update byte count and alignment
                get_type_byte_count_and_alignment(to_type(parser, get_base_node(union_type)));
                
                print_line(builder, "lang_type_info_union { { %u, (lang_type_info_union_field *) &lang_type_table.union_field_types.base[%u] }, %u, %u },", union_type->field_count, field_count, union_type->byte_count, union_type->byte_alignment);
                
                field_count += union_type->field_count;
            }            
            print_scope_close(builder, false);
            print_line(builder, ",");
            
            // union fields            
            {
                assert(field->name == s("union_field_types"));
                local_node_type(array_type, field->type.base_type.node);
                assert(get_array_item_count(array_type) == field_count);
                field = (ast_variable *) field->node.next;

                print_scope_open(builder);
                for_bucket_item(bucket, index, unique_types->unique_union_type_buckets)
                {
                    auto union_type = &bucket->base[index];
                    
                    for (auto field = union_type->first_field; field; field = (ast_variable *) field->node.next)
                    {
                        print(builder, "lang_type_info_union_field { ");
                        print_type_info(&buffer, field->type);
                    
                        print_line(builder, ", { %llu, (u8 *) \"%.*s\" } },", field->name.count, fs(field->name));
                    }
                }
                print_scope_close(builder, false);
                print_line(builder, ",");
            }
        }
        
        // function types
        {
            assert(field->name == s("function_types"));
            local_node_type(array_type, field->type.base_type.node);
            assert(get_array_item_count(array_type) == unique_types->unique_function_type_buckets.item_count)
            field = (ast_variable *) field->node.next;

            print_scope_open(builder);
            for_bucket_item(bucket, index, unique_types->unique_function_type_buckets)
            {
                auto function_type = &bucket->base[index];
                
                print(builder, "lang_type_info_function { ");
                
                if (function_type->input.base_type.node)
                {
                    auto base_type = function_type->input.base_type.node;
                    print(builder, "(lang_type_info_compound *) &lang_type_table.compound_types.base[%u], ", base_type->type_index);
                }
                else
                    print(builder, "null, ");
                    
                if (type_is_not_empty(function_type->output))
                {
                    auto base_type = function_type->output.base_type.node;
                    print_line(builder, "(lang_type_info_compound *) &lang_type_table.compound_types.base[%u] },", base_type->type_index);
                }
                else
                    print_line(builder, "null },");
            }
            print_scope_close(builder, false);
            print_line(builder, ",");
        }
        
        print_scope_close(builder, false);
        print_line(builder, ";");
        
        print_newline(builder);
    }
    
    // declare global variable table
    {
        maybe_print_blank_line(builder);
        
        auto global_variables = parser->base_constants[lang_base_constant_lang_global_variables];
        auto type = get_expression_type(parser, global_variables->expression);
        local_node_type(array_type, type.base_type.node);
        auto global_variable_count = get_array_item_count(array_type);
        
        if (!global_variable_count)
            global_variable_count = 1;
            
        print(builder, "const struct { lang_variable_info base[%u]; } lang_global_variables = ", global_variable_count);
        print_scope_open(builder);
        print_scope_open(builder);
            
        for_bucket_item(bucket, index, parser->variable_buckets)
        {
            auto variable = &bucket->base[index];
            
            if (!is_required(parser, get_base_node(variable)))
                continue;
            
            if (!variable->is_global)
                continue;
            
            print(builder, "{ ");
            print_type_info(&buffer, variable->type);
            print_line(builder, ", { %llu, (u8 *) \"%.*s\" }, (u8 *) &%.*s },", variable->name.count, fs(variable->name), fs(variable->name));
        }
        
        print_scope_close(builder);
        print_scope_close(builder, false);
        print_line(builder, ";");
        
        print_newline(builder);
    }
    
    // declare all functions
    for_bucket_item(bucket, index, parser->function_buckets)
    {
        auto function = &bucket->base[index];
        
        if (!is_required(parser, get_base_node(function)))
            continue;
                
        if (function->first_statement && (is_node_type(function->first_statement, external_binding) || is_node_type(function->first_statement, intrinsic)))
            continue;
    
        local_node_type(function_type, function->type.base_type.node);
        
        maybe_print_blank_line(builder);
        
        print_function_type(&buffer, function_type, function->name, function);
        
        print_scope_open(builder);

        if (function->first_statement)
            print_statements(&buffer, function->first_statement);

        print_scope_close(builder);
    }

    // declare main
    {
        maybe_print_blank_line(builder);
        
        print_line(builder, "#if defined _WIN32");
        print_line(builder, "s32 WinMain(u8 *hInstance, u8 *hPrevInstance, cstring lpCmdLine, s32 nShowCmd)", fs(lang_c_base_type_names[lang_c_base_type_s32]), fs(lang_c_base_type_names[lang_c_base_type_cstring]));
        print_line(builder, "#else");
        print_line(builder, "s32 main(s32 _command_argument_count, cstring *_command_arguments)", fs(lang_c_base_type_names[lang_c_base_type_s32]), fs(lang_c_base_type_names[lang_c_base_type_cstring]));
        print_line(builder, "#endif");
        
        print_scope_open(builder);
    
        for (auto file = parser->file_list.first; file; file = (ast_file *) file->node.next)
        {
            maybe_print_blank_line(builder);
            print_line(builder, "// file: %.*s", fs(file->path));
            //print_line(builder, "#line 1 \"%.*s\"", fs(file->path));
            print_newline(builder);
    
            if (file->first_statement)
                print_statements(&buffer, file->first_statement);
        }
        
        print_scope_close(builder);
    }
    
    return buffer;
}

void clear(lang_c_buffer *buffer)
{
    free_buffer(&buffer->builder.memory);
}