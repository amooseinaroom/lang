
#pragma once

#include "basic.h"
#include "platform.h"
#include "render.h"

void stb_assert_wrapper(int a) 
{
    assert(a);
}

#define STB_TRUETYPE_IMPLEMENTATION
#define STBTT_assert(x) stb_assert_wrapper(x) 
#include "stb_truetype.h"


struct font_glyph
{
    u32 utf32_code_point;
    s32 x_offset;
    s32 y_offset;
    s32 x_advance;
    
    struct 
    {
        s32 x, y;
        s32 width, height;
    } atlas_box;
};

struct loaded_font
{
    font_glyph glyphs[128];
    u32 glyph_count;
    
    s32 line_advance;
    
    s32 left_margin;
    s32 right_margin;
    s32 bottom_margin;
    s32 top_margin;

    sr_frame_buffer atlas;
};

loaded_font make_font(memory_arena *memory, cstring file_path, s32 pixel_height, s32 atlas_width, s32 atlas_height)
{
    loaded_font font = {};

    auto font_atlas = make_frame_buffer(memory, atlas_width, atlas_height);
    
    u8_array data;
    require(platform_allocate_and_read_entire_file(&data, memory, file_path));
    
    stbtt_fontinfo font_info;
    auto ok = stbtt_InitFont(&font_info, data.base, 0);
    assert(ok);
    
    f32 scale = stbtt_ScaleForPixelHeight(&font_info, pixel_height);
    s32 ascent;
    s32 decent;
    s32 line_gab;
    stbtt_GetFontVMetrics(&font_info, &ascent, &decent, &line_gab);

    s32 line_advance = scale * (ascent - decent + line_gab);
    
    u8_array glyph_buffer;
    glyph_buffer.count = 64 * 64;
    glyph_buffer.base  = allocate_bytes(memory, glyph_buffer.count, 1);
    
    // utf32 code points
    
    s32 x_offset = 0;
    s32 y_offset = 0;
    s32 y_max_height = 0;
    
    s32 left_margin   = 0;
    s32 right_margin  = 0;
    s32 bottom_margin = 0;
    s32 top_margin    = 0;
    
    for (u32 code_point = ' '; code_point < 128; code_point++)
    {
        s32 x0, x1, y0, y1;
        stbtt_GetCodepointBitmapBoxSubpixel(&font_info, code_point, scale, scale, 0, 0, &x0, &y0, &x1, &y1);
        
        s32 width  = x1 - x0;
        s32 height = y1 - y0;
        stbtt_MakeCodepointBitmapSubpixel(&font_info, glyph_buffer.base, width, height, width, scale, scale, 0, 0, code_point);
        
        auto glyph = &font.glyphs[font.glyph_count++];
        
        if (x_offset + width + 1 > font_atlas.width)
        {
            x_offset = 0;
            y_offset += y_max_height;
            y_max_height = 0;
            
            assert(y_offset + height < font_atlas.height);
        }
        
        y_max_height = max(y_max_height, height);
        
        s32 x_advance;
        s32 maybe_x_offset; // we use x0 as the x_offset but doc suggests it might be this value
        stbtt_GetCodepointHMetrics(&font_info, code_point, &x_advance, &maybe_x_offset);
        
        glyph->utf32_code_point = code_point;
        glyph->x_offset = x0;
        glyph->y_offset = -y1;
        glyph->x_advance = x_advance * scale;
        
        glyph->atlas_box.x = x_offset;
        glyph->atlas_box.y = y_offset;
        glyph->atlas_box.width  = width;
        glyph->atlas_box.height = height;
        
        for (s32 y = 0; y < height; y++)
        {
            for (s32 x = 0; x < width; x++)
            {
                rgba8 color;
                color.r = glyph_buffer.base[y * width + x];
                color.g = color.r;
                color.b = color.r;
                color.a = color.r;
                
                font_atlas.base[(height - 1 - y + y_offset) * font_atlas.width + x + x_offset] = color;
            }
        }
        
        x_offset += width + 1;
        assert(x_offset <= font_atlas.width);
        
        left_margin   = max(left_margin,   -glyph->x_offset);
        right_margin  = max(right_margin,  glyph->atlas_box.width + glyph->x_offset);
        bottom_margin = max(bottom_margin, -glyph->y_offset);
        top_margin    = max(top_margin,    glyph->atlas_box.height + glyph->y_offset);
    }

    free_bytes(memory, glyph_buffer.base);
    free_bytes(memory, data.base);

    font.atlas = font_atlas;
    font.line_advance  = line_advance;
    font.left_margin   = left_margin;
    font.right_margin  = right_margin;
    font.bottom_margin = bottom_margin;
    font.top_margin    = top_margin;

    return font;
}

struct font_cursor
{
    s32 x, y;
    s32 line_x;
};

font_cursor make_font_cursor(s32 x, s32 y)
{
    font_cursor cursor = {};
    
    cursor.x = x;
    cursor.y = y;
    cursor.line_x = x;
    
    return cursor;
}

void newline(loaded_font font, font_cursor *cursor)
{
    cursor->y -= font.line_advance;
    cursor->x = cursor->line_x;
}

//#define DEBUG_FONT_SPECIAL_CODES

vec2s get_size(loaded_font font, string text)
{
    font_cursor cursor = {};
    vec2s size = { 0, cursor.y + font.top_margin };
    s32 line_end_x = cursor.line_x;
    
    while (text.count)
    {
        u32 code_point = text.base[0];
        text.base++;
        text.count--;
        
        if (code_point == '\n')
        {
            newline(font, &cursor);
            
            size.x = maximum(size.x, line_end_x - cursor.line_x);
            line_end_x = cursor.line_x;
        }
        else
        {
            u32 glyph_index = -1;
            for (u32 i = 0; i < font.glyph_count; i++)
            {
                if (font.glyphs[i].utf32_code_point == code_point)
                {
                    glyph_index = i;
                    break;
                }
            }
            
            if (glyph_index != -1)
            {
                auto glyph = font.glyphs[glyph_index];
                line_end_x = cursor.x + glyph.x_offset + glyph.atlas_box.width;
            
                cursor.x += glyph.x_advance;
            }
        }
    }
    
    size.x = maximum(size.x, line_end_x - cursor.line_x);
    size.y -= cursor.y - font.bottom_margin;
    
    return size;
}

void write(sr_frame_buffer *frame_buffer, loaded_font font, font_cursor *cursor, rgba8 color, string text)
{
    while (text.count)
    {
        u32 code_point = text.base[0];
        
    #if !defined DEBUG_FONT_SPECIAL_CODES
        if (code_point == '\n')
        {
            newline(font, cursor);
        }
        else
    #endif
        {
        #if defined DEBUG_FONT_SPECIAL_CODES
            bool defer_newline = false;
            if (code_point == '\r')
                code_point = 'R';
            else if (code_point == ' ')
                code_point = '.';
            else if (code_point == '\t')
                code_point = 'T';
            else if (code_point == '\n')
            {
                code_point = 'N';
                defer_newline = true;
            }
        #endif
                
            u32 glyph_index = -1;
            for (u32 i = 0; i < font.glyph_count; i++)
            {
                if (font.glyphs[i].utf32_code_point == code_point)
                {
                    glyph_index = i;
                    break;
                }
            }
            
            if (glyph_index != -1)
            {
                auto glyph = font.glyphs[glyph_index];
            
                blit_blend(frame_buffer, cursor->x + glyph.x_offset, cursor->y + glyph.y_offset, font.atlas, glyph.atlas_box.x, glyph.atlas_box.y, glyph.atlas_box.width, glyph.atlas_box.height, color);
                
                cursor->x += glyph.x_advance;
            }
            
        #if defined DEBUG_FONT_SPECIAL_CODES
            if (defer_newline)
                newline(font, cursor);
        #endif
        }
    
        text.base++;
        text.count--;
    }
}

void print(sr_frame_buffer *frame_buffer, loaded_font font, font_cursor *cursor, rgba8 color, cstring format, ...)
{
    u8 buffer[1024];
    
    va_list va_arguments;
    va_start(va_arguments, format);
    
    auto count = vsprintf_s((char *) buffer, carray_count(buffer), format, va_arguments);
    
    string text;
    text.base  = buffer;
    text.count = count;
    write(frame_buffer, font, cursor, color, text);
}