
#pragma once

#include "platform.h"

bool try_skip(string *iterator, string pattern)
{
    if (iterator->count < pattern.count)
        return false;
    
    string test = *iterator;
    test.count = pattern.count;
    
    if (test == pattern)
    {
        advance(iterator, pattern.count);
        
        return true;
    }
    else
    {
        return false;
    }
}

void skip(string *iterator, string pattern)
{
    bool ok = try_skip(iterator, pattern);
    assert(ok);
}

bool contains(string set, u32 code)
{
    for (usize i = 0; i < set.count; i++)
    {
        if (code == set.base[i])
            return true;
    }        
    
    return false;
}

bool try_skip_set(string *iterator, string set)
{
    usize count = 0;    
    while (count < iterator->count)
    {
        u8 head = iterator->base[count];
        
        if (!contains(set, head))
            break;

        count++;
    }
    
    advance(iterator, count);
    
    return (count > 0);
}

void skip_set(string *iterator, string set)
{
    bool ok = try_skip_set(iterator, set);
    assert(ok);
}


bool try_skip_until_set(string *result, string *iterator, string set, bool do_skip_set = false)
{
    usize count = 0;    
    while (count < iterator->count)
    {
        u8 head = iterator->base[count];
        
        if (contains(set, head))
        {
            *result = skip(iterator, count);
            
            if (do_skip_set)
                skip_set(iterator, set);
                
            return true;
        }

        count++;
    }
    
    return false;
}

bool try_skip_until_set(string *iterator, string set, bool do_skip_set = false)
{
    string ignored;
    return try_skip_until_set(&ignored, iterator, set, do_skip_set);
}

string skip_until_set(string *iterator, string set, bool do_skip_set = false)
{
    string result;
    bool ok = try_skip_until_set(&result, iterator, set, do_skip_set);
    assert(ok);
    
    return result;
}

string skip_until_set_or_all(string *iterator, string set, bool do_skip_set = false)
{
    string result;
    if (!try_skip_until_set(&result, iterator, set, do_skip_set))
        return skip(iterator, iterator->count);
    else
        return result;
}

bool try_skip_until(string *result, string *iterator, string pattern, bool do_skip_pattern = true)
{
    auto backup = *iterator;
    result->base = iterator->base;
    
    while (iterator->count)
    {
        auto unskipped = *iterator;
        if (try_skip(iterator, pattern))
        {
            if (!do_skip_pattern)
                *iterator = unskipped;
            
            result->count = (usize) (unskipped.base - result->base);
            return true;
        }
        
        advance(iterator);
    }
    
    *iterator = backup;
    return false;
}

bool try_skip_until(string *iterator, string pattern, bool do_skip_pattern = true)
{
    string ignored;
    return try_skip_until(&ignored, iterator, pattern, do_skip_pattern);
}

string skip_until_or_all(string *iterator, string pattern, bool do_skip_set = true)
{
    string result;
    if (!try_skip_until(&result, iterator, pattern, do_skip_set))
        return skip(iterator, iterator->count);
    else
        return result;
}

bool skip_white(string *iterator)
{
    return try_skip_set(iterator, s(" \t\n\r"));
}

bool is_digit(u32 code)
{
    return (code - '0') <= 9;
}

bool is_letter(u8 code)
{
    return ('a' <= code && code <= 'z') || ('A' <= code && code <= 'Z') || (code == '_');
}

string skip_name(string *iterator)
{
    if (!iterator->count || !is_letter(iterator->base[0]))
        return {};
    
    usize count = 1;
    while (count < iterator->count)
    {
        u8 head = iterator->base[count];
        if (!is_letter(head) && !is_digit(head))
            break;
        
        count++;
    }
    
    string result = skip(iterator, count);
    skip_white(iterator);
    
    return result;
}

bool starts_with(string text, string prefix)
{
    if (text.count < prefix.count)
        return false;
    
    text.count = prefix.count;
    return (text == prefix);
}

string print_va(string *output, memory_arena *memory, bool zero_terminated, cstring format, va_list va_arguments)
{
    if (output->count && zero_terminated)
        output->count--;
    
    auto offset = output->count;
    usize count = _vscprintf_p(format, va_arguments);
    
    reallocate_array(memory, output, output->count + count + 1);
    _vsprintf_p((char *) output->base + offset, count + 1, format, va_arguments);
    
    if (!zero_terminated)
        reallocate_array(memory, output, output->count - 1);
    
    return { count, output->base + offset };
}

string print_zero_terminated(string *output, memory_arena *memory, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);
    
    auto zero_terminated = true;
    auto text = print_va(output, memory, zero_terminated, format, va_arguments);
    
    va_end(va_arguments);
    
    return text;
}

string print(memory_arena *memory, string *output, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);
    
    bool zero_terminated = false;
    auto text = print_va(output, memory, zero_terminated, format, va_arguments);
    
    va_end(va_arguments);
    
    return text;
}

string print_zero_terminated(memory_arena *memory, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);
    
    auto zero_terminated = true;
    string text = {};
    print_va(&text, memory, zero_terminated, format, va_arguments);
    
    va_end(va_arguments);
    
    return text;
}

string print(memory_arena *memory, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);
    
    bool zero_terminated = false;
    string text = {};
    print_va(&text, memory, zero_terminated, format, va_arguments);
    
    va_end(va_arguments);
    
    return text;
}

struct string_builder
{
    u8_buffer memory;
    
    u32 indent;
    bool previous_was_newline;
    bool previous_was_blank_line;
    bool previous_was_scope_open;
    bool previous_was_scope_close;
    bool pending_newline;
};

void clear(string_builder *builder)
{
    auto memory = builder->memory;
    *builder = {};
    
    resize_buffer(&memory, 0);
    builder->memory = memory;
}

string print_raw_va(string_builder *builder, cstring format, va_list va_arguments)
{
    usize count = _vscprintf_p(format, va_arguments) + 1;

    auto offset = builder->memory.count;
    resize_buffer(&builder->memory, builder->memory.count + count);

    _vsprintf_p((char *) builder->memory.base + offset, count, format, va_arguments);
    resize_buffer(&builder->memory, builder->memory.count - 1); // without \0 terminal character
    
    builder->previous_was_newline    = false;
    builder->previous_was_blank_line = false;
    
    return { count - 1, builder->memory.base + offset };
}

string print_raw(string_builder *builder, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);
    
    auto result = print_raw_va(builder, format, va_arguments);
    
    va_end(va_arguments);
    
    return result;
}

void print_newline(string_builder *builder)
{
    print_raw(builder, "\r\n");
    builder->previous_was_blank_line = builder->previous_was_newline;
    builder->previous_was_newline = true;
    builder->pending_newline = false;
}

string print_va(string_builder *builder, cstring format, va_list va_arguments)
{
    if (builder->pending_newline)
        print_newline(builder);

    if (builder->previous_was_newline && builder->indent)
        print_raw(builder, "%*c", builder->indent * 4 - 1, ' ');

    auto debug_offset = builder->memory.count;
    auto result = print_raw_va(builder, format, va_arguments);
    
    // make sure no newline in format
    for (u32 i = debug_offset; i < builder->memory.count; i++)
    {
        u8 head = builder->memory.base[i];
        assert((head != '\r') && (head != '\n'));
    }
    
    builder->previous_was_newline    = false;
    builder->previous_was_blank_line = false;
    builder->previous_was_scope_open = false;
    builder->previous_was_scope_close = false;
    
    return result;
}

string print(string_builder *builder, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);
    
    auto result = print_va(builder, format, va_arguments);
    
    va_end(va_arguments);
    
    return result;
}

void print_line(string_builder *builder, cstring format, ...)
{
    va_list va_arguments;
    va_start(va_arguments, format);
    
    print_va(builder, format, va_arguments);
    
    va_end(va_arguments);
    
    print_newline(builder);
}

void print_scope_open(string_builder *builder, bool with_newline = true, cstring symbol = "{")
{
    if (with_newline && !builder->previous_was_newline)
        print_newline(builder);
    
    print(builder, symbol);
    builder->indent++;
    
    if (with_newline)
        print_newline(builder);
    
    builder->previous_was_scope_open = true;
}

void maybe_print_newline(string_builder *builder)
{
    if (!builder->previous_was_scope_open && !builder->previous_was_newline)
        print_newline(builder);
}

void maybe_print_blank_line(string_builder *builder)
{
    if (!builder->previous_was_scope_open && !builder->previous_was_blank_line)
        print_newline(builder);
}

void pending_newline(string_builder *builder)
{
    builder->pending_newline = true;
}

void print_scope_close(string_builder *builder, bool with_newline = true, cstring symbol = "}")
{
    assert(builder->indent);
    
    --builder->indent;
    
    if (with_newline)
        maybe_print_newline(builder);
        
    print(builder, symbol);
    
    if (with_newline)
        print_newline(builder);
        
    builder->previous_was_scope_close = true;
}

string cstring_to_string(cstring text)
{
    usize count = 0;
    while (text[count])
        count++;
        
    return { count, (u8 *) text };
}

string get_absolute_path(memory_arena *memory, string working_directory, string relative_path)
{
    string full_path;
    
    if (working_directory.count && (relative_path.count >= 2) && (relative_path.base[1] != ':'))
        full_path = print(memory, "%.*s/%.*s", fs(working_directory), fs(relative_path));
    else
        full_path = relative_path;
        
    string iterator = full_path;
    
    string absolute_path = {};
    while (iterator.count)
    {
        string directory;
        if (!try_skip_until_set(&directory, &iterator, s("/"), false))
        {
            print(memory, &absolute_path,"%.*s", fs(iterator));
            break;
        }
        
        skip(&iterator, s("/"));
        
        if (directory == s(".."))
        {
            assert(absolute_path.count && absolute_path.base[absolute_path.count - 1] == '/');
            --absolute_path.count;
            
            while (absolute_path.count && absolute_path.base[absolute_path.count - 1] != '/')
                --absolute_path.count;
                
            reallocate_array(memory, &absolute_path, absolute_path.count);
        }
        else if (directory == s("."))
        {
            assert(!iterator.count);
            break;
        }
        else
        {
            print(memory, &absolute_path, "%.*s/", fs(directory));
        }
    }
    
    return absolute_path;
}

string get_absolute_path(string_builder *builder, string working_directory, string relative_path)
{
    string full_path;
    
    // allocate maximum possible size, to prevent pointer invalidation on resize
    auto max_count = (working_directory.count + relative_path.count + 1) * 2;
    resize_buffer(&builder->memory, builder->memory.count + max_count);
    resize_buffer(&builder->memory, builder->memory.count - max_count);
    
    if (working_directory.count && (relative_path.count >= 2) && (relative_path.base[1] != ':'))
        full_path = print(builder, "%.*s/%.*s", fs(working_directory), fs(relative_path));
    else
        full_path = relative_path;
        
    string iterator = full_path;
    
    auto absolute_path_offset = builder->memory.count;
    while (iterator.count)
    {
        string directory;
        if (!try_skip_until_set(&directory, &iterator, s("/"), false))
        {
            print(builder, "%.*s", fs(iterator));
            break;
        }
        
        skip(&iterator, s("/"));
        
        if (directory == s(".."))
        {
            assert((absolute_path_offset < builder->memory.count) && builder->memory.base[builder->memory.count - 1] == '/');
            builder->memory.count--;
            
            while ((absolute_path_offset < builder->memory.count) && builder->memory.base[builder->memory.count - 1] != '/')
                builder->memory.count--;
        }
        else if (directory == s("."))
        {
            assert(!iterator.count);
            break;
        }
        else
        {
            print(builder, "%.*s/", fs(directory));
        }
    }
    
    return { builder->memory.count - absolute_path_offset, builder->memory.base + absolute_path_offset };
}
