
module font;

import platform;
import memory;
import math;
import string;
import stb_truetype;
import meta;

struct font_info
{
    utf32_codes     u32[];
    glyphs          font_glyph[];
    pair_x_advances s32[];
    
    pixel_height s32;
    
    line_spacing s32;
    max_glyph_height s32;
    max_x_advance    s32;
    left_margin      s32;
    right_margin     s32;
    bottom_margin    s32;
    top_margin       s32;
    
    atlas_width  s32;
    atlas_height s32;
}

struct font_glyph
{
    x      s32;
    y      s32;
    width  s32;
    height s32;
    
    x_draw_offset s32;
    y_draw_offset s32;    
}

func load(memory memory_arena ref, font font_info ref, font_data u8[], pixel_height s32, texture_size s32 = 512) (alpha_texture u8[])
{
    var stbtt_info stbtt_fontinfo;
    stbtt_InitFont(stbtt_info ref, font_data.base, 0);
    
    var scale = stbtt_ScaleForPixelHeight(stbtt_info ref, pixel_height);
    
    var ascent s32;
    var decent s32;
    var line_gab s32;
    stbtt_GetFontVMetrics(stbtt_info ref, ascent ref, decent ref, line_gab ref);
    
    font deref = {} font_info;
    font.pixel_height = pixel_height;
    font.line_spacing = (scale * (ascent - decent + line_gab))cast(s32);
    var baseline = (ascent * scale) cast(s32);
    
    font.utf32_codes.count = 128 - 32;
    font.utf32_codes.base  = allocate_array(memory, get_type_info(u32), font.utf32_codes.count);
    
    font.pair_x_advances.count = font.utf32_codes.count * font.utf32_codes.count;
    font.pair_x_advances.base  = allocate_array(memory, get_type_info(s32), font.pair_x_advances.count);
    
    font.glyphs.count = font.utf32_codes.count;
    font.glyphs.base  = allocate_array(memory, get_type_info(font_glyph), font.glyphs.count);
    
    loop var i = 32; 128
        font.utf32_codes[i - 32] = i;
        
    font.atlas_width  = texture_size;
    font.atlas_height = texture_size;
    
    var alpha_texture u8[];
    alpha_texture.count = (font.atlas_width * font.atlas_height) cast(usize);
    alpha_texture.base  = allocate(memory, alpha_texture.count, 1);
    clear(alpha_texture);
        
    var x s32 = 0;
    var y s32 = 0;
    var row_height s32 = 0;
    
    loop var i; font.glyphs.count
    {
        var code = font.utf32_codes[i];        
        
        var x0 s32;
        var x1 s32;
        var y0 s32;
        var y1 s32;
        stbtt_GetCodepointBitmapBoxSubpixel(stbtt_info ref, code, scale, scale, 0, 0, x0 ref, y0 ref, x1 ref, y1 ref);
        
        var width  = x1 - x0;
        var height = y1 - y0;
        
        if (x + width + 1 >= font.atlas_width)
        {
            x = 0;
            y = y + row_height + 1;
            row_height = 0;
            
            assert(width < font.atlas_width);
            assert(y + height < font.atlas_height);
        }
        
        stbtt_MakeCodepointBitmapSubpixel(stbtt_info ref, alpha_texture[y * font.atlas_width + x] ref, width, height, font.atlas_width, scale, scale, 0, 0, code);

        var x_advance s32;        
        
        font.glyphs[i].x      = x;
        font.glyphs[i].width  = width;
        font.glyphs[i].y      = font.atlas_height - (y + height);
        font.glyphs[i].height = height;
        font.glyphs[i].x_draw_offset = x0;
        font.glyphs[i].y_draw_offset = -y1;        
        
        font.max_glyph_height = maximum(font.max_glyph_height, height);
        font.top_margin       = maximum(font.top_margin, height + font.glyphs[i].y_draw_offset);
        font.bottom_margin    = maximum(font.bottom_margin, -font.glyphs[i].y_draw_offset);
        
        var left_margin = maximum(-font.glyphs[i].x_draw_offset, 0);
        font.left_margin      = maximum(font.left_margin, left_margin);
        font.right_margin     = maximum(font.right_margin, width - left_margin);
        
        row_height = maximum(row_height, height);
        x = x + width + 1; // + 1 to have some padding between glyphs
    }
    
    loop var y; font.atlas_height / 2
    {
        var my = font.atlas_height - 1 - y; // mirrored y
        
        loop var x; font.atlas_width
        {
            var tmp = alpha_texture[y * font.atlas_width + x];
            alpha_texture[y * font.atlas_width + x] = alpha_texture[my * font.atlas_width + x];
            alpha_texture[my * font.atlas_width + x] = tmp;
        }
    }
    
    loop var a; font.utf32_codes.count
    {
        var a_code = font.utf32_codes[a];
        var x_advance s32;
        var ignored s32;
        stbtt_GetCodepointHMetrics(stbtt_info ref, a_code, x_advance ref, ignored ref);
    
        loop var b; font.utf32_codes.count
        {
            // value is floored ...
            var b_code = font.utf32_codes[b];
            var kerning = 0; //stbtt_GetCodepointKernAdvance(stbtt_info ref, a_code, b_code);
            var pair_x_advance = (scale * (x_advance + kerning)) cast(s32);            
            font.pair_x_advances[a * font.utf32_codes.count cast(u32) + b] = pair_x_advance;
            
            font.max_x_advance = maximum(font.max_x_advance, pair_x_advance);
        }
    }

    return alpha_texture;
}

func get_glyph_index(font font_info, utf32_code u32) (index u32)
{
    var left s32 = 0;
    var right s32 = (font.utf32_codes.count - 1) cast(s32);
    
    while left <= right
    {
        var index = (left + right) / 2;
        
        if font.utf32_codes[index] is utf32_code
            return index;
        else if font.utf32_codes[index] < utf32_code
            left = index + 1;
        else
            right = index - 1;
    }
    
    return -1;
}

struct font_cursor
{
    expand position vec2s;
           line_x   s32;
}

func cursor_at_baseline(font font_info, expand baseline_start vec2) (cursor font_cursor)
{
    var cursor font_cursor;
    cursor.x = baseline_start.x cast(s32);
    cursor.y = baseline_start.y cast(s32);
    cursor.line_x = cursor.x;
    
    return cursor;
}

func cursor_below_position(font font_info, expand position vec2) (cursor font_cursor)
{
    var cursor font_cursor;
    cursor.x = position.x cast(s32);
    cursor.y = position.y cast(s32) - font.top_margin;
    cursor.line_x = cursor.x;
    
    return cursor;
}

struct font_text_iterator
{
    font           font_info;
    text           string;
    space_index    u32;
    previous_index u32;
    cursor         font_cursor;
}

func make_iterator(font font_info, text string, cursor font_cursor) (iterator font_text_iterator)
{
    var iterator font_text_iterator;
    iterator.text   = text;
    iterator.font   = font;
    iterator.cursor = cursor;
    
    iterator.space_index = get_glyph_index(font, " "[0]);
    assert(iterator.space_index is_not -1 cast(u32));
    
    iterator.previous_index = iterator.space_index;
    
    return iterator;
}

func advance(iterator font_text_iterator ref) (glyph_index u32, x_advance s32)
{
    assert(iterator.text.count);
    
    var font = iterator.font;
    
    var code = iterator.text[0];
    advance(iterator.text ref);
    
    if code is "\n"[0]
    {
        iterator.cursor.x = iterator.cursor.line_x;
        iterator.cursor.y = iterator.cursor.y - font.line_spacing;
        iterator.previous_index = iterator.space_index;
        return -1 cast(u32), 0;
    }
    
    var index = get_glyph_index(font, code);
    var x_advance s32;
    
    if index is_not -1 cast(u32)
    {
        var glyph = font.glyphs[index];        
        x_advance = font.pair_x_advances[iterator.previous_index * font.utf32_codes.count cast(u32) + index];
        iterator.cursor.x += x_advance;
        
        iterator.previous_index = index;
    }
    else
    {
        iterator.previous_index = iterator.space_index;
    }
    
    return index, x_advance;
}

func get_text_size(font font_info, text string) (size vec2s)
{
    var iterator = make_iterator(font, text, {} font_cursor);

    var width s32;
    
    // we add left and right margin, so that the bounding box does not depend on start and end letter on a line
    // we need to ignore last advance, so we keep track of previous cursor position
    var previous_x = iterator.cursor.x;
    while iterator.text.count
    {
        if iterator.text[0] is "\n"[0]
            width = maximum(width, previous_x);
        
        previous_x = iterator.cursor.x;
        advance(iterator ref);
    }
    
    width = maximum(width, previous_x);
    
    return [ width + font.left_margin +  font.right_margin, -iterator.cursor.y + font.max_glyph_height ] vec2s;
}
    
