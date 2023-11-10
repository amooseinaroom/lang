    
#pragma once

#include <string.h>

#include "basic.h"

struct platform_character
{
    u32 code;
    bool is_character;
    bool shift_is_active;
    bool control_is_active;
    bool alt_is_active;
};

union platform_button
{
    struct
    {
        u8 is_active             : 1;
        u8 half_transition_count : 7;
    };
    
    struct
    {
        u8 _ignored            : 7;
        u8 transition_overflow : 1;
    };
    
    u8 value;
};

struct platform_window_position
{
    s32 x, y;
    s32 width, height;
    bool maximized;
};

struct platform_window_size
{
    s32 width, height;
};

struct platform_file_info
{
    u64 byte_count;
    u64 write_timestamp;
    bool ok, is_directory;
};

struct platform_found_file
{
    string absolute_path;
    string relative_path;
    bool   is_directory;
};

struct platform_file_search_iterator_base
{
    string relative_path_prefix;
    
    // only valid if platform_file_search_next returned true
    platform_found_file found_file;
};

struct platform_file_search_iterator;
struct platform_window;
struct platform_api;

struct platform_api_base
{
    string working_directory;
    
    platform_button keys[256];
    
    platform_character characters[32];
    u32 character_count;
    
    u64 ticks_per_second;
    u64 last_time_ticks;
    f32 delta_seconds;
};

struct memory_arena
{
    u8_buffer buffer;
    
#if defined _DEBUG
    usize debug_max_count;
#endif
};

#define platform_init_declaration                    void platform_init(platform_api *platform)
#define platform_get_realtime_ticks_declaration      u64 platform_get_realtime_ticks(platform_api *platform)
#define platform_update_delta_seconds_declaration    void platform_update_delta_seconds(platform_api *platform)
#define platform_get_working_directory_declaration   string platform_get_working_directory(memory_arena *memory)
#define platform_handle_messages_declaration         bool platform_handle_messages(platform_api *platform)
#define platform_window_get_position_declaration     platform_window_position platform_window_get_position(platform_api *platform, platform_window *window)
#define platform_window_init_declaration             void platform_window_init(platform_window *window, platform_api *platform, cstring title, s32 width, s32 height, bool maximized, bool use_xy, s32 x, s32 y)
#define platform_window_get_size_declaration         platform_window_size platform_window_get_size(platform_api *platform, platform_window *window)
#define platform_get_file_info_declaration           platform_file_info platform_get_file_info(cstring file_path)
#define platform_file_search_begin_declaration       platform_file_search_iterator platform_file_search_begin(platform_api *platform, string relative_path_pattern, memory_arena *tmemory)
#define platform_file_search_end_declaration         void platform_file_search_end(platform_api *platform, platform_file_search_iterator *iterator, memory_arena *tmemory)
#define platform_file_search_next_declaration        bool platform_file_search_next(platform_api *platform, platform_file_search_iterator *iterator, memory_arena *tmemory)
#define platform_read_embedded_file_declaration      u8_array platform_read_embedded_file(cstring filename)
#define platform_allocate_bytes_location_declaration u8_array platform_allocate_bytes_location(usize byte_count, call_location_argument)
#define platform_free_bytes_location_declaration     void platform_free_bytes_location(u8 *base, call_location_argument)
#define platform_read_entire_file_declaration        bool platform_read_entire_file(u8_array memory, cstring file_path)
#define platform_write_entire_file_declaration       bool platform_write_entire_file(cstring file_path, u8_array memory)

platform_init_declaration;
platform_get_realtime_ticks_declaration;
platform_update_delta_seconds_declaration;
platform_get_working_directory_declaration;
platform_handle_messages_declaration;
platform_window_get_position_declaration;
void platform_window_init(platform_window *window, platform_api *platform, cstring title, s32 width, s32 height, bool maximized = false, bool use_xy = false, s32 x = 0, s32 y = 0);
platform_window_get_size_declaration;
platform_get_file_info_declaration;
platform_file_search_begin_declaration;
platform_file_search_end_declaration;
platform_file_search_next_declaration;
platform_read_embedded_file_declaration;
platform_allocate_bytes_location_declaration;
platform_free_bytes_location_declaration;
platform_read_entire_file_declaration;
platform_write_entire_file_declaration;

#define platform_allocate_bytes(byte_count) platform_allocate_bytes_location(byte_count, get_call_location())
#define platform_free_bytes(base)           platform_free_bytes_location(base, get_call_location())

void platform_button_update(platform_button *button, bool is_active)
{
    auto transition_overflow = button->transition_overflow;
    
    button->is_active = is_active;
    button->half_transition_count++;
    button->transition_overflow = button->transition_overflow | transition_overflow;
}

#define resize_buffer(buffer, new_count) resize_base_buffer((base_buffer *) (buffer), new_count, sizeof(*(buffer)->base), get_call_location())
#define free_buffer(buffer)              free_base_buffer((base_buffer *) (buffer), get_call_location())

#define copy_array(dest, source) copy_base_array((base_array *) (dest), (base_array) { (source).base, (source).count }, sizeof((source).base[0]))

void copy_base_array(base_array *destination, base_array source, u32 item_byte_count)
{
    *destination = {};
    destination->count = source.count;
    destination->base = platform_allocate_bytes(item_byte_count * source.count).base;
    memcpy(destination->base, source.base, item_byte_count * source.count);
}

void resize_base_buffer(base_buffer *buffer, usize new_count, u32 item_byte_count, call_location_argument)
{
    if (new_count >= buffer->capacity)
    {
        buffer->capacity = maximum(maximum(buffer->capacity, new_count) * 2, 32llu);
        
        auto new_base = platform_allocate_bytes_location(item_byte_count * buffer->capacity, call_location).base;
        
        if (buffer->base)
            memcpy(new_base, buffer->base, item_byte_count * buffer->count);
            
        platform_free_bytes_location(buffer->base, call_location);
    
        buffer->base = new_base;
    }
    
    buffer->count = new_count;
}

void free_base_buffer(base_buffer *buffer, call_location_argument)
{
    platform_free_bytes_location(buffer->base, call_location);
    *buffer = {};
}

#define allocate_items(memory, type, count) ( (type *) allocate_bytes(memory, sizeof(type) * (count), alignof(type)) )
#define allocate_item(memory, type)         allocate_items(memory, type, 1)
//#define reallocate_items(memory, type, base, count) ( (type *) reallocate_bytes(memory, (u8 *) &(base), sizeof(type) * (count), alignof(type)) )

#define allocate_array(memory, type, count)    { (usize) (count), allocate_items(memory, type, count) }
#define reallocate_array(memory, array, count) reallocate_base_array(memory, (base_array *) (array), count, sizeof(*(array)->base), alignof(decltype(*(array)->base)))
#define free_array(memory, array) free_bytes(memory, (u8 *) (array)->base)

u8 * allocate_bytes(memory_arena *memory, usize byte_count, u32 byte_alignment)
{
    if (!byte_count)
        return null;

    usize alignment_mask = byte_alignment - 1;
    assert((alignment_mask & byte_alignment) == 0, "alignment must be power of 2");
    
    usize buffer_count = (memory->buffer.count + alignment_mask) & ~alignment_mask;
    assert(buffer_count + byte_count <= memory->buffer.capacity);
    
    auto base = memory->buffer.base + buffer_count;
    memory->buffer.count = buffer_count + byte_count;
    
#if _DEBUG
    memory->debug_max_count = maximum(memory->debug_max_count, memory->buffer.count);
#endif
    
    return base;
}

void free_bytes(memory_arena *memory, u8 *base)
{
    if (!base)
        return;
        
    usize count = (usize) (base - memory->buffer.base);
    assert(count <= memory->buffer.count);
    
    memory->buffer.count = count;
}

u8 * reallocate_bytes(memory_arena *memory, u8 **base, usize byte_count, u32 byte_alignment)
{
    free_bytes(memory, *base);
    auto new_base = allocate_bytes(memory, byte_count, byte_alignment);
    
    assert(!*base || !new_base || (*base == new_base));
    *base = new_base;
    
    return new_base;
}

void reallocate_base_array(memory_arena *memory, base_array *array, usize count, usize item_byte_count, u32 item_byte_alignment)
{
    reallocate_bytes(memory, &array->base, item_byte_count * count, item_byte_alignment);
    array->count = count;
}

void clear(memory_arena *memory)
{
    memory->buffer.count = 0;
}

bool platform_allocate_and_read_entire_file(u8_array *out_data, cstring file_path)
{
    auto file_info = platform_get_file_info(file_path);
    if (!file_info.ok || file_info.is_directory)
        return false;
    
    u8_array data = platform_allocate_bytes(file_info.byte_count);
    data.count = file_info.byte_count; // since allocate will allocate more if it can (allocates multiple pages)
    platform_read_entire_file(data, file_path);
    
    *out_data = data;
    
    return true;
}

bool platform_allocate_and_read_entire_file(u8_array *out_data, memory_arena *memory, cstring file_path)
{
    auto file_info = platform_get_file_info(file_path);
    if (!file_info.ok || file_info.is_directory)
        return false;
        
    u8_array data;
    data.base  = allocate_bytes(memory, file_info.byte_count, 1);
    data.count = file_info.byte_count;
    bool ok = platform_read_entire_file(data, file_path);
    *out_data = data;
    
    return ok;
}

#include "platform.cpp"

bool platform_key_was_pressed(platform_api *platform, u8 key)
{
    auto button = platform->keys[key];
    return (button.half_transition_count >= 2 - button.is_active);
}

platform_update_delta_seconds_declaration
{
    u64 time_ticks = platform_get_realtime_ticks(platform);
    
    u64 delta_ticks = time_ticks - platform->last_time_ticks;
    
    platform->delta_seconds = (f32) delta_ticks / platform->ticks_per_second;
    platform->last_time_ticks = time_ticks;
}