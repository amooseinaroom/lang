
#pragma once

#include "basic.h"
#include "platform.h"

union rgba8
{
    struct
    {
        u8 red, green, blue, alpha;
    };
    
    struct
    {
        u8 r, g, b, a;
    };
    
    u32 value32;
    
    u8  values8[4];
};

struct sr_frame_buffer
{
    s32 width, height;
    s32 row_advance; // adds support for sub frame buffers
    rgba8 *base;
};

rgba8 to_premultiplied_alpha(rgba8 color)
{
    color.r = (u8) ((u32) color.r * color.a / 255);
    color.g = (u8) ((u32) color.g * color.a / 255);
    color.b = (u8) ((u32) color.b * color.a / 255);
    
    return color;
}

rgba8 blend_premultiplied_alpha(rgba8 destination, rgba8 source, rgba8 color = { 255, 255, 255, 255 })
{
    rgba8 result;
    result.r = (u8) (((u32) destination.r * (255 - source.a) + source.r * color.r) / 255);
    result.g = (u8) (((u32) destination.g * (255 - source.a) + source.g * color.g) / 255);
    result.b = (u8) (((u32) destination.b * (255 - source.a) + source.b * color.b) / 255);
    result.a = (u8) ((u32) source.a * color.a / 255);
    
    return result;
}

sr_frame_buffer make_frame_buffer(memory_arena *memory, s32 width, s32 height)
{
    sr_frame_buffer frame_buffer = {};
    frame_buffer.width       = width;
    frame_buffer.height      = height;
    frame_buffer.row_advance = width;
    frame_buffer.base = allocate_items(memory, rgba8, width * height);
    
    return frame_buffer;
}

sr_frame_buffer sub_frame_buffer(sr_frame_buffer frame_buffer, s32 x, s32 y, s32 width, s32 height)
{
    assert(x >= 0);
    assert(y >= 0);
    assert(width > 0);
    assert(height > 0);
    assert(x + width  <= frame_buffer.width);
    assert(y + height <= frame_buffer.height);
    
    sr_frame_buffer result;
    result.width  = width;
    result.height = height;
    result.row_advance = frame_buffer.row_advance; // same as parent
    result.base = frame_buffer.base + y * result.row_advance + x;
    
    return result;
}

void fill_box(sr_frame_buffer *frame_buffer, s32 x, s32 y, s32 width, s32 height, rgba8 color)
{
    if (x < 0)
    {
        width += x; // x < 0
        x = 0;
    }
    
    if (y < 0)
    {
        height += y; // y < 0
        y = 0;
    }
    
    if (x >= frame_buffer->width)
        return;
    
    if (y >= frame_buffer->height)
        return;
    
    s32 end_x = min(x + width, frame_buffer->width);
    s32 end_y = min(y + height, frame_buffer->height);
    
    for (s32 y_it = y; y_it < end_y; y_it++)
    {
        for (s32 x_it = x; x_it < end_x; x_it++)
        {
            frame_buffer->base[y_it * frame_buffer->row_advance + x_it] = color;
        }
    }
}

void blend_box(sr_frame_buffer *frame_buffer, s32 x, s32 y, s32 width, s32 height, rgba8 color)
{
    if (x < 0)
    {
        width += x; // x < 0
        x = 0;
    }
    
    if (y < 0)
    {
        height += y; // y < 0
        y = 0;
    }
    
    if (x >= frame_buffer->width)
        return;
    
    if (y >= frame_buffer->height)
        return;
    
    s32 end_x = min(x + width, frame_buffer->width);
    s32 end_y = min(y + height, frame_buffer->height);
    
    color = to_premultiplied_alpha(color);
    
    for (s32 y_it = y; y_it < end_y; y_it++)
    {
        for (s32 x_it = x; x_it < end_x; x_it++)
        {
            auto destination = &frame_buffer->base[y_it * frame_buffer->row_advance + x_it];
            *destination = blend_premultiplied_alpha(*destination, color);
        }
    }
}

void blit_blend(sr_frame_buffer *destination, s32 destination_x, s32 destination_y, sr_frame_buffer source, s32 source_x, s32 source_y, s32 source_width, s32 source_height, rgba8 color = { 255, 255, 255, 255 })
{
    assert(destination->base != source.base);
    
    assert((0 <= source_x) && (source_x < source.width));
    assert((0 <= source_y) && (source_y < source.height));
    assert(source_width >= 0);
    assert(source_x + source_width <= source.width);
    assert(source_height >= 0);
    assert(source_y + source_height <= source.height);

    if (destination_x < 0)
    {
        source_width += destination_x;
        source_x     -= destination_x;
        destination_x = 0;
    }
    
    if (destination_y < 0)
    {
        source_height += destination_y;
        source_y     -= destination_y;
        destination_y = 0;
    }
     
    if (destination_x >= destination->width)
        return;
        
    if (destination_y >= destination->height)
        return;
    
    s32 width  = min(source_width,  destination->width - destination_x);
    s32 height = min(source_height, destination->height - destination_y);
    
    color = to_premultiplied_alpha(color);
    
    for (s32 y = 0; y < height; y++)
    {
        for (s32 x = 0; x < width; x++)
        {
            auto source_color      = source.base[(y + source_y) * source.row_advance + x + source_x];
            auto destination_color = &destination->base[(y + destination_y) * destination->row_advance + x + destination_x];
            *destination_color = blend_premultiplied_alpha(*destination_color, source_color, color);
        }
    }
}

void present(platform_api *platform, platform_window *window, s32 window_width, s32 window_height, sr_frame_buffer frame_buffer)
{
    assert(frame_buffer.width == frame_buffer.row_advance); // "sub frame buffers are not supported");
    
    if ((frame_buffer.width <= 0) || (frame_buffer.height <= 0))
        return;
    
    // convert rgb8 to windows bgr
    for (s32 i = 0; i < frame_buffer.width * frame_buffer.height; i++)
    {
        auto color = frame_buffer.base[i];
        frame_buffer.base[i].r = color.b;
        frame_buffer.base[i].b = color.r;
    }
    
    BITMAPINFO bitmap_info = {};
    BITMAPINFOHEADER *header = &bitmap_info.bmiHeader;
    header->biSize        = sizeof(*header);
    header->biWidth       = frame_buffer.width;
    header->biHeight      = frame_buffer.height;
    header->biPlanes      = 1;
    header->biBitCount    = 32;
    header->biCompression = BI_RGB;
    
    platform_require( StretchDIBits(window->win32.device_context,
        0, 0, window_width, window_height,
        0, 0, frame_buffer.width, frame_buffer.height,
        frame_buffer.base,
        &bitmap_info,
        0, SRCCOPY) );
        
    SwapBuffers(window->win32.device_context);
    //platform_require( SwapBuffers(window->win32.device_context) );
}