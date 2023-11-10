
#pragma once

#include "render.h"

struct ui_quad
{
    box2s box;
    vec2s texture_offset;
    rgba8 color;
    s32   layer;
    s32   render_target_index;
    s32   texture_index;
};

buffer_type(ui_quads, ui_quad_array, ui_quad);
buffer_type(ui_textures, ui_texture_array, sr_frame_buffer);

struct ui_state
{
    ui_quads    quads;
    ui_textures render_targets;
    ui_textures textures;
    //s32_buffer  layer_stack;
    
    u32 render_target_index;
    s32 layer;
    
    // for sorting
    s32 min_layer, max_layer;
};

void init(ui_state *ui)
{
    resize_buffer(&ui->render_targets, 0);
    resize_buffer(&ui->textures, 0);
    resize_buffer(&ui->quads, 0);
    ui->render_target_index = -1;
    ui->layer = 0;
    ui->min_layer = 0;
    ui->max_layer = 0;
}

u32 get_texture_index(ui_textures *textures, sr_frame_buffer texture)
{
    for (u32 i = 0; i < textures->count; i++)
    {
        auto other = textures->base[i];
        if (values_are_equal(other, texture))
            return i;
    }
    
    resize_buffer(textures, textures->count + 1);
    textures->base[textures->count - 1] = texture;
    
    return textures->count - 1;
}

u32 set_render_target(ui_state *ui, sr_frame_buffer render_target)
{
    auto previous = ui->render_target_index;
    ui->render_target_index = get_texture_index(&ui->render_targets, render_target);
    
    return previous;
}

void push_quad(ui_state *ui, u32 render_target_index, s32 layer, u32 texture_index, vec2s texture_offset, box2s box, rgba8 color)
{
    assert(render_target_index < ui->render_targets.count);
    
    ui->min_layer = minimum(ui->min_layer, layer);
    ui->max_layer = maximum(ui->max_layer, layer);
    
    resize_buffer(&ui->quads, ui->quads.count + 1);
    auto quad = &ui->quads.base[ui->quads.count - 1];
    *quad = {};
    quad->box                 = box;
    quad->color               = color;
    quad->layer               = layer;
    quad->render_target_index = render_target_index;
    quad->texture_index       = texture_index;
    quad->texture_offset      = texture_offset;
}

void push_quad(ui_state *ui, u32 render_target_index, s32 layer, sr_frame_buffer texture, vec2s texture_offset, box2s box, rgba8 color)
{
    auto texture_index = get_texture_index(&ui->textures, texture);
    
    assert(texture_offset.x >= 0 && texture_offset.x < texture.width);
    assert(texture_offset.y >= 0 && texture_offset.y < texture.height);
    assert(texture_offset.x + box.max.x - box.min.x <= texture.width);
    assert(texture_offset.y + box.max.y - box.min.y <= texture.height);
    
    push_quad(ui, render_target_index, layer, texture_index, texture_offset, box, color);
}

void push_quad(ui_state *ui, s32 layer, sr_frame_buffer texture, vec2s texture_offset, box2s box, rgba8 color)
{
    push_quad(ui, ui->render_target_index, layer, texture, texture_offset, box, color);
}

void push_quad(ui_state *ui, s32 layer, u32 texture_index, vec2s texture_offset, box2s box, rgba8 color)
{
    push_quad(ui, ui->render_target_index, layer, texture_index, texture_offset, box, color);
}

void push_quad(ui_state *ui, u32 texture_index, vec2s texture_offset, box2s box, rgba8 color)
{
    push_quad(ui, ui->render_target_index, ui->layer, texture_index, texture_offset, box, color);
}

void push_quad(ui_state *ui, s32 layer, box2s box, rgba8 color)
{
    push_quad(ui, ui->render_target_index, layer, -1, {}, box, color);
}

void push_quad(ui_state *ui, box2s box, rgba8 color)
{
    push_quad(ui, ui->layer, box, color);
}

void push_text(ui_state *ui, s32 layer, loaded_font font, font_cursor *cursor, rgba8 color, string text)
{
    auto texture_index = get_texture_index(&ui->textures, font.atlas);

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
            
                push_quad(ui, layer, texture_index, vec2s { glyph.atlas_box.x, glyph.atlas_box.y }, box2_size(cursor->x + glyph.x_offset, cursor->y + glyph.y_offset, glyph.atlas_box.width, glyph.atlas_box.height), color);
            
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

void print(ui_state *ui, s32 layer, loaded_font font, font_cursor *cursor, rgba8 color, cstring format, ...)
{
    u8 buffer[1024];
    
    va_list va_arguments;
    va_start(va_arguments, format);
    
    auto count = vsprintf_s((char *) buffer, carray_count(buffer), format, va_arguments);
    
    string text;
    text.base  = buffer;
    text.count = count;
    push_text(ui, layer, font, cursor, color, text);
}

void render(ui_state *ui)
{
    // TODO: better sort
    
    // sort
    
    // insertion sort lol
    usize sorted_count = 0;
    for (s32 layer = ui->min_layer; layer <= ui->max_layer; layer++)
    {
        for (usize i = sorted_count; i < ui->quads.count; i++)
        {
            if (ui->quads.base[i].layer == layer)
            {
                mswap(ui->quads.base[i], ui->quads.base[sorted_count]);
                sorted_count++;
            }
        }
    }
    assert(sorted_count == ui->quads.count);
    
    for (u32 i = 0; i < ui->quads.count; i++)
    {
        auto quad = ui->quads.base[i];
        
        assert(quad.render_target_index < ui->render_targets.count);
        auto render_target = ui->render_targets.base[quad.render_target_index];
        
        if (quad.texture_index != -1)
        {
            assert(quad.texture_index < ui->textures.count);
            auto texture = ui->textures.base[quad.texture_index];
            blit_blend(&render_target, quad.box.min.x, quad.box.min.y, texture, quad.texture_offset.x, quad.texture_offset.y, quad.box.max.x - quad.box.min.x, quad.box.max.y - quad.box.min.y, quad.color);
        }
        else
        {
            blend_box(&render_target, quad.box.min.x, quad.box.min.y, quad.box.max.x - quad.box.min.x, quad.box.max.y - quad.box.min.y, quad.color);
        }
    }
    
    init(ui);
}
