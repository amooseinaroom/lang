
module ui;

import platform;
import memory;
import gl;
import math;
import font;
import random;
import string;

def ui_vertex_shader_source   = import_text_file("glsl/ui.vert.glsl");
def ui_fragment_shader_source = import_text_file("glsl/ui.frag.glsl");

def ui_white_handle = { ui_primitive_id.box, 0, 0 } ui_handle;

enum ui_vertex_attribute
{
    position;
    uv;
    color;
    saturation;
}

struct ui_vertex
{
    position   vec2;
    uv         vec2;
    color      rgba8;
    saturation f32;
}

enum ui_primitive_id u32
{
    box;
    rounded_box;
    rounded_box_frame;
}

struct ui_system
{
    memory memory_arena;
    handles    ui_handle[1024];
    tiles      ui_tile[1024];
    tile_count u32;
    next_tile_x     s32;
    next_tile_y     s32;
    tile_row_height s32;

    builder_settings string_builder_settings;

    expand input struct
    {
        cursor vec2;
        cursor_left_active   u8;
        cursor_middle_active u8;
        cursor_right_active  u8;

        active_id ui_id;
        hot_id    ui_id;
        active_mask u32;

        drag_start_cursor vec2;

        next_hot_id       ui_id;
        next_hot_priority f32;
    };

    carret_blink_time f32;

    expand viewport_size vec2;

    scissor_box box2;

    base_layer s32;

    current_box box2;

    print struct
    {
        previous_font_glyphs font_glyph ref; // assuming different fonts have different glyph data
        previous_glyph_index u32;
    };

    shader ui_shader;

    atlas          gl_texture;
    vertex_buffer  gl_vertex_buffer;

    textures      gl_texture[];

    quad_commands ui_quad_command[];

    texture_count u32;
    quad_command_count u32;
}

struct ui_shader
{
    handle u32;
    diffuse_texture s32;
}

struct ui_handle
{
    id           u32;
    pixel_height f32;
    thickness    f32;
}

struct ui_tile
{
    x s32;
    y s32;
    width  s32;
    height s32;
    x_slices s32[2];
    y_slices s32[2];
}

struct ui_quad_command
{
    texture_index  u32;
    layer          s32;
    vertices       ui_vertex[4];
}

func init(ui ui_system ref, platform platform_api ref, gl gl_api ref)
{
    init(ui.memory ref);

    reload_shader(gl, ui.shader, "ui", get_type_info(ui_vertex_attribute), ui_vertex_shader_source, false, ui_fragment_shader_source);
    assert(ui.shader.diffuse_texture is_not -1);

    ui.atlas = gl_create_texture_2d(1024, 1024, false, {} u8[], GL_RGBA);
    ui.textures.count = 32;
    ui.quad_commands.count = 4096;
    ui_frame_end(ui);

    clear_atlas(ui);
}

func clear_atlas(ui ui_system ref)
{
    // clear texture
    glBindTexture(GL_TEXTURE_2D, ui.atlas.handle);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ui.atlas.width, ui.atlas.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
    glBindTexture(GL_TEXTURE_2D, 0);

    ui.next_tile_x = 0;
    ui.next_tile_y = 0;
    ui.tile_row_height = 0;
    ui.tile_count = 0;

    create_tile(ui, ui_white_handle, 1, 1); // should be tile_index 0
    var buffer = tile_buffer_begin(ui, 0);
    buffer.colors[0] = rgba8_white;
    tile_buffer_end(ui, 0, buffer);
}

func get_tile_index(ui ui_system ref, handle ui_handle) (tile_index u32)
{
    loop var i u32; ui.tile_count
    {
        if (ui.handles[i].id is handle.id) and (ui.handles[i].pixel_height is handle.pixel_height)and (ui.handles[i].thickness is handle.thickness)
        {
            return i;
        }
    }

    return -1 cast(u32);
}

func create_tile(ui ui_system ref, handle ui_handle, width s32, height s32) (tile ui_tile ref)
{
    if ui.next_tile_x + width >= ui.atlas.width
    {
        ui.next_tile_x = 0;
        ui.next_tile_y = ui.next_tile_y + ui.tile_row_height;
        ui.tile_row_height = 0;

        assert(width <= ui.atlas.width);
        assert(ui.next_tile_y + height <= ui.atlas.height);
    }

    ui.handles[ui.tile_count] = handle;
    var tile = ui.tiles[ui.tile_count] ref;
    ui.tile_count = ui.tile_count + 1;
    tile.x = ui.next_tile_x;
    tile.y = ui.next_tile_y;
    tile.width  = width;
    tile.height = height;
    //tile.x_slices[0] = (corner_radius + 0.5) cast(s32);
    //tile.x_slices[1] = 1;
    //tile.y_slices[0] = (corner_radius + 0.5) cast(s32);
    //tile.y_slices[1] = 1;

    ui.tile_row_height = maximum(ui.tile_row_height, height);
    ui.next_tile_x = ui.next_tile_x + width;

    return tile;
}

struct ui_buffer
{
    colors rgba8[];
    width  s32;
    height s32;
}

func tile_buffer_begin(ui ui_system ref, tile_index u32) (buffer ui_buffer)
{
    assert(tile_index < ui.tile_count);
    var tile = ui.tiles[tile_index];

    var buffer ui_buffer;
    buffer.width  = tile.width;
    buffer.height = tile.height;
    buffer.colors.count = (buffer.width * buffer.height) cast(usize);
    buffer.colors.base = allocate_array(ui.memory ref, get_type_info(rgba8), buffer.colors.count);

    loop var i; buffer.colors.count
    {
        buffer.colors[i] = [ 0, 0, 0, 0] rgba8;
    }

    return buffer;
}

func tile_buffer_end(ui ui_system ref, tile_index u32, buffer ui_buffer)
{
    assert(tile_index < ui.tile_count);
    var tile = ui.tiles[tile_index];

    assert((tile.width is buffer.width) and (tile.height is buffer.height));

    glBindTexture(GL_TEXTURE_2D, ui.atlas.handle);
    glTexSubImage2D(GL_TEXTURE_2D, 0, tile.x, tile.y, tile.width cast(u32), tile.height cast(u32), GL_RGBA, GL_UNSIGNED_BYTE, buffer.colors.base);
    glBindTexture(GL_TEXTURE_2D, 0);

    free(ui.memory ref, buffer.colors.base);
}

func rounded_box(buffer ui_buffer, x s32, y s32, width s32, height s32, corner_radius f32, color rgba8)
{
    loop var y; height
        loop var x; width
        {
            var pixel_color = color;

            var center vec2;

            if x < corner_radius
                center[0] = corner_radius - 0.5;
            else if x > (width - corner_radius)
                center[0] = width - corner_radius + 0.5;
            else
                center[0] = x + 0.5;

            if y < corner_radius
                center[1] = corner_radius - 0.5;
            else if y > (height - corner_radius)
                center[1] = height - corner_radius + 0.5;
            else
                center[1] = y + 0.5;

            var p = [ x, y ] vec2 + 0.5;
            var d = corner_radius - length(p - center);
            if d < 0
                pixel_color = [ 0, 0, 0, 0] rgba8;
            else if d < 1
                pixel_color[3] = (d * 255) cast(u8);

            buffer.colors[(y * width) + x] = pixel_color;
        }
}

func rounded_box_frame(buffer ui_buffer, x s32, y s32, width s32, height s32, corner_radius f32, thickness f32, color rgba8)
{
    thickness *= 0.5;

    var actual_radius = corner_radius - thickness - 0.5;

    loop var y; height
        loop var x; width
        {
            var pixel_color = color;

            var center vec2;

            if x < (corner_radius - 1)
                center[0] = corner_radius - 1;
            else if x > (width - corner_radius + 1)
                center[0] = width - corner_radius + 1;
            else
                center[0] = x + 0.5;

            if y < (corner_radius - 1)
                center[1] = corner_radius - 1;
            else if y > (height - corner_radius + 1)
                center[1] = height - corner_radius + 1;
            else
                center[1] = y + 0.5;

            var p = [ x, y ] vec2 + 0.5;
            var d = -(absolute(length(p - center) - actual_radius) - thickness);
            if d <= 0
                pixel_color = [ 0, 0, 0, 0] rgba8;
            else if d < 1
                pixel_color[3] = (d * 255) cast(u8);

            buffer.colors[(y * width) + x] = pixel_color;
        }
}


func bezier_sample(points vec2[3], ratio f32) (result vec2)
{
    var one_minus_ratio = 1.0 - ratio;
    var result = (points[0] * (one_minus_ratio * one_minus_ratio)) + (points[1] * (2 * one_minus_ratio * ratio)) + (points[2] * (ratio * ratio));
    return result;
}

func bezier_curve(buffer ui_buffer, curve vec2[3], thickness f32, color rgba8)
{
    var four_a = (curve[0] - (curve[1] * 2) + curve[2]) * 4;
    var b = (curve[1] - curve[0]) * 2;

    if (four_a[0] is 0) or (four_a[1] is 0)
        return;

    var inverse_2_a = [ 2 / four_a[0], 2 / four_a[1] ] vec2;
    var b2 = scale(b, b);

    loop var y; buffer.height
    {
        loop var x; buffer.width
        {
            var p = [ x, y ] vec2;

            // p is c0 * (1 - t)² + c1 * 2 * (1 - t) * t + c2 * t²
            // p is c0 * (1 - 2t + t²) + c1 * (2t - 2t²) + c2 * t²
            // p is (c0 - 2 * c1 + c2) * t² + (-2 * c0 + 2 c1) * t + c0
            var c = curve[0] - p;

            var squared_root = b2 - scale(four_a, c);
            if (squared_root[0] < 0) or (squared_root[1] < 0)
                continue;

            var root = [ sqrt(squared_root[0]), sqrt(squared_root[1]) ] vec2;

            var t0 = scale(-root - b, inverse_2_a);
            var t1 = scale(root - b, inverse_2_a);

            var t f32;
            if (absolute(t0[0] - t0[1]) < 0.01) or (absolute(t0[0] - t1[1]) < 0.01)
                t = t0[0];
            else if (absolute(t1[0] - t0[1]) < 0.01) or (absolute(t1[0] - t1[1]) < 0.01)
                t = t1[0];
            else
                continue;

            if (t < 0) or (t > 1)
                continue;

            buffer.colors[(y * buffer.width) + x] = color;

            continue;


            var left  = 0.0;
            var right = 1.0;

            var l = bezier_sample(curve, left);
            var r = bezier_sample(curve, right);
            var dl = squared_length(p - l);
            var dr = squared_length(p - r);

            while true
            {
                if absolute(dl - dr) < 1
                    break;

                if dl < dr
                {
                    right = (left + right) * 0.5;
                    r = bezier_sample(curve, right);

                    var ndr = squared_length(p - r);
                    if ndr >= dr
                        break;

                    dr = ndr;
                }
                else
                {
                    left  = (left + right) * 0.5;
                    l = bezier_sample(curve, left);

                    var ndl = squared_length(p - l);
                    if ndl >= dl
                        break;

                    dl = ndl;
                }
            }

            var coverage = thickness - length(p - l);
            if coverage > 0
            {
                buffer.colors[(y * buffer.width) + x] = color;

                if coverage < 1
                    buffer.colors[(y * buffer.width) + x][3] = (color[3] * coverage) cast(u8);
            }
        }
    }

}

multiline_comment {
func bezier_curve(ui ui_system ref, handle ui_handle, points vec2[3], color rgba8)
{
    var min = points[0];
    var max = points[0];

    loop var i = 1; points.count
    {
        min[0] = minimum(min[0], points[i][0]);
        min[1] = minimum(min[1], points[i][1]);

        max[0] = maximum(max[0], points[i][0]);
        max[1] = maximum(max[1], points[i][1]);
    }

    var tile_index = get_tile_index(ui, handle);
    if tile_index is (-1 cast(u32))
    {
        var width  = (max[0] - min[0]) cast(s32);
        var height = (max[1] - min[1]) cast(s32);

        tile_index = ui.tile_count;
        var tile = create_tile(ui, handle, width, height);

        var buffer = tile_buffer_begin(ui, tile_index);

        var thickness = handle.pixel_height;
        bezier_curve(buffer, [ points[0] - min, points[1] - min, points[2] - min ] vec2[], thickness, [ 255, 255, 255, 255 ] rgba8);

        tile_buffer_end(ui, tile_index, buffer);
    }

    add_tile(ui, tile_index, min[0] cast(s32), min[1] cast(s32), color);
}
}

func add_command(ui ui_system ref, texture gl_texture) (command ui_quad_command ref)
{
    var texture_index = -1 cast(u32);

    loop var i u32; ui.texture_count
    {
        if ui.textures[i].handle is texture.handle
        {
            texture_index = i;
            break;
        }
    }

    if texture_index is (-1 cast(u32))
    {
        texture_index = ui.texture_count;
        ui.textures[texture_index] = texture;
        ui.texture_count = ui.texture_count + 1;
    }

    ui.quad_command_count += 1;
    if (ui.quad_command_count > ui.quad_commands.count)
        return null;

    var command = ui.quad_commands[ui.quad_command_count - 1] ref;

    command.texture_index = texture_index;
    return command;
}

multiline_comment
{
func add_tile(ui ui_system ref, tile_index u32, x s32, y s32, color rgba8 = rgba8_white)
{
    assert(tile_index < ui.tile_count);
    var tile = ui.tiles[tile_index];

    assert(ui.command_count < ui.commands.count);
    var command = ui.commands[ui.command_count] ref;
    ui.command_count = ui.command_count + 1;

    command.texture_index = 0;
    command.x = x;
    command.y = y;
    command.width  = tile.width;;
    command.height = tile.height;
    command.texture_x      = tile.x;
    command.texture_y      = tile.y;
    command.texture_width  = tile.width;
    command.texture_height = tile.height;
    command.color = color;
}
}

struct ui_quad_info
{
    layer      s32;
    saturation f32;
    color      rgba8;
}

def ui_default_quad_info = { 0,  1.0, rgba8_white } ui_quad_info;

func add_3x3_slice(ui ui_system ref, expand quad_info = ui_default_quad_info, tile_index u32, x s32, y s32, width s32, height s32)
{
    assert(tile_index < ui.tile_count);
    var tile = ui.tiles[tile_index];

    var x_last_slice = tile.width  - tile.x_slices[0] - tile.x_slices[1];
    var y_last_slice = tile.height - tile.y_slices[0] - tile.y_slices[1];

    var x_slices = [ x, x + tile.x_slices[0], x + width  - x_last_slice, x + width ] s32[];
    var y_slices = [ y, y + tile.y_slices[0], y + height - y_last_slice, y + height ] s32[];

    var x_texture_slices = [ tile.x, tile.x + tile.x_slices[0], tile.x + tile.x_slices[0] + tile.x_slices[1], tile.x + tile.width ] s32[];
    var y_texture_slices = [ tile.y, tile.y + tile.y_slices[0], tile.y + tile.y_slices[0] + tile.y_slices[1], tile.y + tile.height ] s32[];

    loop var slice_y; 3
    {
        loop var slice_x; 3
        {
            add_quad(ui, quad_info, x_slices[slice_x], y_slices[slice_y], x_slices[slice_x + 1] - x_slices[slice_x], y_slices[slice_y + 1] - y_slices[slice_y], ui.atlas, x_texture_slices[slice_x], y_texture_slices[slice_y], x_texture_slices[slice_x + 1] - x_texture_slices[slice_x], y_texture_slices[slice_y + 1] - y_texture_slices[slice_y]);
        }
    }
}

func get_quad_intersection(ui ui_system ref, box box2, uv_box = {} box2) (ok b8, intersection_box box2, intersection_uv_box box2)
{
    var viewport_scale = 2.0 / ui.viewport_size;

    var result = get_intersection(box, ui.scissor_box);
    if not result.ok
        return false, {} box2, {} box2;

    var intersection = result.intersection;

    var box_size = box.max - box.min;
    var inverse_box_size = [ 1.0 / box_size.x, 1.0 / box_size.y ] vec2;

    var min = scale(intersection.min - box.min, inverse_box_size);
    var max = scale(intersection.max - box.min, inverse_box_size);

    intersection.min = scale(intersection.min, viewport_scale) - 1;
    intersection.max = scale(intersection.max, viewport_scale) - 1;

    var intersection_uv_box box2;
    intersection_uv_box.min = lerp(uv_box.min, uv_box.max, min);
    intersection_uv_box.max = lerp(uv_box.min, uv_box.max, max);

    return true, intersection, intersection_uv_box;
}

func add_quad(ui ui_system ref, expand quad_info = ui_default_quad_info, x s32, y s32, width s32, height s32, texture = {} gl_texture, texture_x s32 = 0, texture_y s32 = 0, texture_width s32 = 1, texture_height s32 = 1)
{
    add_quad(ui, quad_info, quad_info, quad_info, quad_info, x, y, width, height, texture, texture_x, texture_y, texture_width, texture_height);
}

func add_quad(ui ui_system ref, expand quad_infos ui_quad_info[4], x s32, y s32, width s32, height s32, texture = {} gl_texture, texture_x s32 = 0, texture_y s32 = 0, texture_width s32 = 1, texture_height s32 = 1)
{
    var command = add_command(ui, texture);
    if not command
        return;

    var box box2;
    box.min = [ x, y ] vec2;
    box.max = box.min + [ width, height ] vec2;

    var texture_scale = [ 1.0 / texture.width, 1.0 / texture.height ] vec2;

    var uv_box box2;
    uv_box.min = scale([ texture_x, texture_y ] vec2, texture_scale);
    uv_box.max = uv_box.min + scale([ texture_width, texture_height ] vec2, texture_scale);
    var result = get_quad_intersection(ui, box, uv_box);
    if not result.ok
    {
        ui.quad_command_count -= 1;
        return;
    }

    loop var i; quad_infos.count - 1
        assert(quad_infos[i].layer is quad_infos[i + 1].layer);

    ui.current_box = merge(ui.current_box, box);

    command.layer = ui.base_layer + quad_infos[0].layer;

    command.vertices[0].position = result.intersection_box.min;
    command.vertices[0].uv       = result.intersection_uv_box.min;
    command.vertices[0].color    = quad_infos[0].color;
    command.vertices[0].saturation = quad_infos[0].saturation;

    command.vertices[2].position = result.intersection_box.max;
    command.vertices[2].uv       = result.intersection_uv_box.max;
    command.vertices[2].color    = quad_infos[2].color;
    command.vertices[2].saturation = quad_infos[2].saturation;

    command.vertices[1].position.x = command.vertices[2].position.x;
    command.vertices[1].position.y = command.vertices[0].position.y;
    command.vertices[1].uv.x       = command.vertices[2].uv.x;
    command.vertices[1].uv.y       = command.vertices[0].uv.y;
    command.vertices[1].color      = quad_infos[1].color;
    command.vertices[1].saturation = quad_infos[1].saturation;

    command.vertices[3].position.x = command.vertices[0].position.x;
    command.vertices[3].position.y = command.vertices[2].position.y;
    command.vertices[3].uv.x       = command.vertices[0].uv.x;
    command.vertices[3].uv.y       = command.vertices[2].uv.y;
    command.vertices[3].color      = quad_infos[3].color;
    command.vertices[3].saturation = quad_infos[3].saturation;
}

func set_base_layer(ui ui_system ref, base_layer s32) (previous_base_layer s32)
{
    var previous_base_layer = ui.base_layer;
    ui.base_layer = base_layer;

    return previous_base_layer;
}

func draw_rounded_box(ui ui_system ref, expand quad_info ui_quad_info, expand box box2, corner_radius s32)
{
    var handle = { ui_primitive_id.rounded_box, corner_radius, 0 } ui_handle;
    var tile_index = get_tile_index(ui, handle);
    if tile_index is (-1 cast(u32))
    {
        //var size = box.max - box.min;
        var width  = (corner_radius * 2 + 1) cast(s32);
        var height = (corner_radius * 2 + 1) cast(s32);

        tile_index = ui.tile_count;
        var tile = create_tile(ui, handle, width, height);
        tile.x_slices[0] = (corner_radius + 0.5) cast(s32);
        tile.x_slices[1] = 1;
        tile.y_slices[0] = (corner_radius + 0.5) cast(s32);
        tile.y_slices[1] = 1;

        var buffer = tile_buffer_begin(ui, tile_index);
        rounded_box(buffer, 0, 0, width, height, corner_radius, [ 255, 255, 255, 255 ] rgba8);

        tile_buffer_end(ui, tile_index, buffer);
    }

    var size = box.max - box.min;
    add_3x3_slice(ui, quad_info, tile_index, box.min[0] cast(s32), box.min[1] cast(s32), size[0] cast(s32), size[1] cast(s32));
}

func draw_rounded_box_frame(ui ui_system ref, expand quad_info ui_quad_info, expand box box2, corner_radius s32, frame_thickness f32)
{
    var handle = { ui_primitive_id.rounded_box_frame, corner_radius, frame_thickness } ui_handle;
    var tile_index = get_tile_index(ui, handle);
    if tile_index is (-1 cast(u32))
    {
        //var size = box.max - box.min;
        var width  = (corner_radius * 2 + 1) cast(s32);
        var height = (corner_radius * 2 + 1) cast(s32);

        tile_index = ui.tile_count;
        var tile = create_tile(ui, handle, width, height);
        tile.x_slices[0] = (corner_radius + 0.5) cast(s32);
        tile.x_slices[1] = 1;
        tile.y_slices[0] = (corner_radius + 0.5) cast(s32);
        tile.y_slices[1] = 1;

        var buffer = tile_buffer_begin(ui, tile_index);
        rounded_box_frame(buffer, 0, 0, width, height, corner_radius, frame_thickness, quad_info.color);

        tile_buffer_end(ui, tile_index, buffer);
    }

    var size = box.max - box.min;
    add_3x3_slice(ui, quad_info, tile_index, box.min[0] cast(s32), box.min[1] cast(s32), size[0] cast(s32), size[1] cast(s32));
}

func draw_box(ui ui_system ref, expand quad_infos ui_quad_info[4], expand box box2)
{
    add_quad(ui, quad_infos, box.min.x cast(s32), box.min.y cast(s32), (box.max.x - box.min.x) cast(s32), (box.max.y - box.min.y) cast(s32), ui.atlas);
}

func draw_box(ui ui_system ref, quad_info = ui_default_quad_info, expand box box2)
{
    add_quad(ui, quad_info, box.min.x cast(s32), box.min.y cast(s32), (box.max.x - box.min.x) cast(s32), (box.max.y - box.min.y) cast(s32), ui.atlas);
}

// TODO: if a default value is provided to an expand argument, use the default value per field for every skipped field
func draw_rounded_box(ui ui_system ref, layer s32 = 0, saturation = 1.0, color = rgba8_white, expand box box2, corner_radius s32)
{
    draw_rounded_box(ui, { layer, saturation, color } ui_quad_info, box, corner_radius);
}

func draw_rounded_box_frame(ui ui_system ref, layer s32 = 0, saturation = 1.0, color = rgba8_white, expand box box2, corner_radius s32, frame_thickness f32)
{
    draw_rounded_box_frame(ui, { layer, saturation, color } ui_quad_info, box, corner_radius, frame_thickness);
}

// TODO: if a default value is provided to an expand argument, use the default value per field for every skipped field
func draw_box(ui ui_system ref, layer s32, saturation = 1.0, color = rgba8_white, expand box box2)
{
    draw_box(ui, { layer, saturation, color } ui_quad_info, box);
}

func draw_texture(ui ui_system ref, expand quad_info = ui_default_quad_info, texture gl_texture, expand position vec2, expand alignment = [ 0, 0 ] vec2, expand texture_scale = [ 1, 1 ] vec2)
{
    var size = scale(v2(texture.width, texture.height), texture_scale);
    position -= scale(alignment, size);

    add_quad(ui, quad_info, position.x cast(s32), position.y cast(s32), size.width cast(s32), size.height cast(s32), texture, 0, 0, texture.width, texture.height);
}

func draw_texture_box(ui ui_system ref, expand quad_info = ui_default_quad_info, texture gl_texture, expand position vec2, texture_box box2, expand alignment = [ 0, 0 ] vec2, texture_scale = [ 1, 1 ] vec2, flip_x = false, flip_y = false)
{
    assert(texture_box.min.x >= 0);
    assert(texture_box.min.y >= 0);
    assert(texture_box.max.x <= texture.width);
    assert(texture_box.max.y <= texture.height);

    var box_size = texture_box.max - texture_box.min;

    var size = scale(box_size, texture_scale);
    position -= scale(alignment, size);

    if flip_x
    {
        var temp = texture_box.min.x;
        texture_box.min.x = texture_box.max.x;
        texture_box.max.x = temp;
        box_size.width = -box_size.width;
    }

    if flip_y
    {
        var temp = texture_box.min.y;
        texture_box.min.y = texture_box.max.y;
        texture_box.max.y = temp;
        box_size.height = -box_size.height;
    }

    add_quad(ui, quad_info, position.x cast(s32), position.y cast(s32), size.width cast(s32), size.height cast(s32), texture, texture_box.min.x cast(s32), texture_box.min.y cast(s32), box_size.width cast(s32), box_size.height cast(s32));
}

func draw_line(ui ui_system ref, expand quad_info = ui_default_quad_info, expand from vec2, expand to vec2, thickness = 1.0)
{
    draw_line(ui, quad_info.layer, from, quad_info.saturation, quad_info.color, thickness, to, quad_info.saturation, quad_info.color, thickness);
}

func draw_box_lines(ui ui_system ref, expand quad_info = ui_default_quad_info, expand box box2, thickness = 1.0)
{
    //box.min -= 0.5;
    //box.max -= 1;

    //draw_line(ui, box.min, box.max.x, box.min.y, color, thickness, layer);
    //draw_line(ui, box.min, box.min.x, box.max.y, color, thickness, layer);
    //draw_line(ui, box.min.x, box.max.y, box.max, color, thickness, layer);
    //draw_line(ui, box.max.x, box.min.y, box.max, color, thickness, layer);

    draw_line(ui, quad_info, box.min, box.max.x - 1, box.min.y, thickness);
    draw_line(ui, quad_info, box.min, box.min.x, box.max.y - 1, thickness);
    draw_line(ui, quad_info, box.min.x, box.max.y - 1, box.max - 1, thickness);
    draw_line(ui, quad_info, box.max.x - 1, box.min.y, box.max - 1, thickness);
}

// the line is drawn at the centers of to and from (+ 0.5)
// some day will be: func line(ui ui_system ref, from vec2, from_color = to_color, to vec2, to_color rgba8, thickness = 1.0)
func draw_line(ui ui_system ref, layer s32 = 0, from vec2, from_saturation = 1.0, from_color rgba8, from_thickness = 1.0, to vec2, to_saturation = 1.0, to_color rgba8, to_thickness = 1.0)
{
    var quad = ui.quad_commands[ui.quad_command_count] ref;
    ui.quad_command_count += 1;

    var right = normalize(to - from) * 0.5;
    var _up    = rotate_counter_clockwise(right);
    var from_up = _up * from_thickness;
    var to_up   = _up * to_thickness;

    var viewport_scale = [ 2.0 / ui.viewport_size.width, 2.0 / ui.viewport_size.height ] vec2;

    from += 0.5 - right;
    to   += right + 0.5;

    quad deref = {} ui_quad_command;
    quad.layer = layer;
    quad.vertices[0].position = scale(from - from_up, viewport_scale) - 1;
    quad.vertices[0].color    = from_color;
    quad.vertices[0].saturation = from_saturation;

    quad.vertices[1].position = scale(to - to_up, viewport_scale) - 1;
    quad.vertices[1].color    = to_color;
    quad.vertices[1].saturation = to_saturation;

    quad.vertices[2].position = scale(to + to_up, viewport_scale) - 1;
    quad.vertices[2].color    = to_color;
    quad.vertices[2].saturation = to_saturation;

    quad.vertices[3].position = scale(from + from_up, viewport_scale) - 1;
    quad.vertices[3].color    = from_color;
    quad.vertices[3].saturation = from_saturation;
}

func ui_frame(ui ui_system ref, delta_seconds f32)
{
    ui.hot_id = ui.next_hot_id;
    ui.next_hot_id = 0;
    ui.next_hot_priority = 0x7FFFFFFF;

    if ui.active_id
        ui.hot_id = 0;

    ui.carret_blink_time = fmod(ui.carret_blink_time + (delta_seconds * 2), 1.0);
}

func ui_window(ui ui_system ref, platform platform_api ref, window platform_window ref)
{
    ui.viewport_size.x = window.size.x;
    ui.viewport_size.y = window.size.y;

    ui.cursor.x = window.mouse_position.x;
    ui.cursor.y = window.mouse_position.y;

    clear_sissor_box(ui);

    if ui.active_id
    {
        ui.cursor_left_active   = platform_key_is_active(platform, platform_key.mouse_left) cast(u8);
        ui.cursor_middle_active = platform_key_is_active(platform, platform_key.mouse_middle) cast(u8);
        ui.cursor_right_active  = platform_key_is_active(platform, platform_key.mouse_right) cast(u8);
    }
    else if box_is_hot(ui, ui.scissor_box)
    {
        ui.cursor_left_active   = platform_key_is_active(platform, platform_key.mouse_left) cast(u8);
        ui.cursor_middle_active = platform_key_is_active(platform, platform_key.mouse_middle) cast(u8);
        ui.cursor_right_active  = platform_key_is_active(platform, platform_key.mouse_right) cast(u8);
    }
    else
    {
        ui.cursor_left_active   = 0;
        ui.cursor_middle_active = 0;
        ui.cursor_right_active  = 0;
    }

    ui.current_box = {} box2;
    ui.print.previous_font_glyphs = null;
}

func clear_sissor_box(ui ui_system ref)
{
    ui.scissor_box.min = {} vec2;
    ui.scissor_box.max = ui.viewport_size;
}

func ui_present(gl gl_api ref, ui ui_system ref)
{
    var viewport_scale = [ 2.0 / ui.viewport_size.width, 2.0 / ui.viewport_size.height ] vec2;

    var commands = { ui.quad_command_count, ui.quad_commands.base } ui_quad_command[];
    if commands.count > ui.quad_commands.count
        commands.count = ui.quad_commands.count;

    // radix sort
    if commands.count
    {
        def bucket_bit_count = 3;

        var _buckets ui_quad_command[][1 bit_shift_left bucket_bit_count];
        var buckets = { _buckets.count, _buckets.base } ui_quad_command[][];

        loop var i; buckets.count
            reallocate_array(ui.memory ref, buckets[i] ref, commands.count);

        // sort by texture
        {
            var value = ui.texture_count;
            var shift_count u32 = 0;
            while value
            {
                loop var i; buckets.count
                    buckets[i].count = 0;

                value = value bit_shift_right bucket_bit_count;

                loop var i; commands.count
                {
                    var command = commands[i];
                    radix_fill_bucket(buckets ref, command, shift_count, command.texture_index);
                }

                radix_empty_buckets(commands, buckets);
                shift_count += bucket_bit_count;
            }
        }

        {
            var min_layer = commands[0].layer;
            var max_layer = min_layer;

            loop var i = 1; commands.count
            {
                min_layer = minimum(min_layer, commands[i].layer);
                max_layer = maximum(max_layer, commands[i].layer);
            }

            var value = (max_layer - min_layer + 1) cast(u32);
            var shift_count u32 = 0;
            while value
            {
                loop var i; buckets.count
                    buckets[i].count = 0;

                value = value bit_shift_right bucket_bit_count;

                loop var i; commands.count
                {
                    var command = commands[i];
                    radix_fill_bucket(buckets ref, command, shift_count, (command.layer - min_layer) cast(u32));
                }

                radix_empty_buckets(commands, buckets);
                shift_count += bucket_bit_count;
            }
        }

        // HACK: deleting first bucket is enough
        free(ui.memory ref, buckets[0].base);
    }

    if commands.count
    {
        var vertices ui_vertex[];
        reallocate_array(ui.memory ref, vertices ref, commands.count * 6);

        var iterator = vertices.base cast(ui_vertex[6] ref);
        loop var i; commands.count
        {
            var quad = commands[i];

            iterator[0] = quad.vertices[0];
            iterator[1] = quad.vertices[1];
            iterator[2] = quad.vertices[2];
            iterator[3] = quad.vertices[0];
            iterator[4] = quad.vertices[2];
            iterator[5] = quad.vertices[3];

            iterator += 1;
        }

        resize_buffer(gl, ui.vertex_buffer ref, get_type_info(ui_vertex_attribute), get_type_info(ui_vertex), vertices.count, vertices.base);

        glDisable(GL_DEPTH_TEST);

        glUseProgram(ui.shader.handle);
        glUniform1i(ui.shader.diffuse_texture, 0);

        glActiveTexture(GL_TEXTURE0 + 0);

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glBindVertexArray(ui.vertex_buffer.vertex_array);

        var vertex_offset u32;
        var texture_index = -1 cast(u32);
        var texture_vertex_count u32;
        loop var i; commands.count
        {
            var quad = commands[i];

            if texture_index is_not quad.texture_index
            {
                if texture_vertex_count
                {
                    glBindTexture(GL_TEXTURE_2D, ui.textures[texture_index].handle);
                    glDrawArrays(GL_TRIANGLES, vertex_offset, texture_vertex_count);
                    vertex_offset += texture_vertex_count;
                }

                texture_index = quad.texture_index;
                texture_vertex_count = 0;
            }

            texture_vertex_count += 6;
        }

        // render last texture
        if texture_vertex_count
        {
            glBindTexture(GL_TEXTURE_2D, ui.textures[texture_index].handle);
            glDrawArrays(GL_TRIANGLES, vertex_offset, texture_vertex_count);
            vertex_offset += texture_vertex_count;
        }

        glBindVertexArray(0);
        glUseProgram(0);
    }

    ui_frame_end(ui);
}

func radix_fill_bucket(buckets ui_quad_command[][] ref, command ui_quad_command, shift_count u32, value u32)
{
    var mask = buckets.count - 1;
    assert((mask bit_and buckets.count) is 0); // power of two

    var bucket_index = (value bit_shift_right shift_count) bit_and mask;
    buckets[bucket_index].count += 1;
    buckets[bucket_index][buckets[bucket_index].count - 1] = command;
}

func radix_empty_buckets(commands ui_quad_command[], buckets ui_quad_command[][])
{
    var index u32 = 0;
    loop var bucket_index; buckets.count
    {
        loop var item u32; buckets[bucket_index].count
        {
            commands[index] = buckets[bucket_index][item];
            index += 1;
        }
    }

    assert(index is commands.count);
}

func ui_frame_end(ui ui_system ref)
{
    var texture_count      = ui.textures.count;
    var quad_command_count = ui.quad_commands.count;

    clear(ui.memory ref);

    if texture_count < ui.texture_count
        texture_count = ui.texture_count;

    reallocate_array(ui.memory ref, ui.textures ref, texture_count);
    ui.textures[0] = ui.atlas;
    ui.texture_count = 1;

    if quad_command_count < ui.quad_command_count
        quad_command_count = ui.quad_command_count;

    reallocate_array(ui.memory ref, ui.quad_commands ref, quad_command_count);
    ui.quad_command_count = 0;
}

struct ui_font
{
    info font_info;
    atlas gl_texture;
}

func init(font ui_font ref, platform platform_api ref, memory memory_arena ref, temp_memory memory_arena ref, path string, pixel_height s32, texture_size s32 = 512)
{
    var font_data = platform_read_entire_file(platform, temp_memory, path);
    var alpha_texture = load(memory, font.info ref, font_data, pixel_height, texture_size);
    font.atlas = gl_create_texture_2d(font.info.atlas_width, font.info.atlas_height, false, alpha_texture, GL_RED, true, [ GL_ONE, GL_ONE, GL_ONE, GL_RED ] u32[]);

    free(memory,      alpha_texture.base);
    free(temp_memory, font_data.base);
}

func print(ui ui_system ref, expand quad_info ui_quad_info, font ui_font, cursor font_cursor ref, text string)
{
    var space_index = get_glyph_index(font.info, " "[0]);

    if ui.print.previous_font_glyphs is_not font.info.glyphs.base
        ui.print.previous_glyph_index = space_index;

    ui.print.previous_font_glyphs = font.info.glyphs.base;

    var iterator = make_iterator(font.info, text, cursor deref);

    while iterator.text.count
    {
        var result = advance(iterator ref);
        if result.glyph_index is_not (-1 cast(u32))
        {
            var glyph = font.info.glyphs[result.glyph_index];

            add_quad(ui, quad_info, iterator.cursor.x + glyph.x_draw_offset, iterator.cursor.y + glyph.y_draw_offset, glyph.width, glyph.height, font.atlas, glyph.x, glyph.y, glyph.width, glyph.height);

            // bounding box
            var box box2;
            box.min = [ iterator.cursor.x + glyph.x_draw_offset, iterator.cursor.y - font.info.bottom_margin ] vec2;
            box.max = box.min + [ glyph.width, font.info.max_glyph_height ] vec2;
            ui.current_box = merge(ui.current_box, box);
        }
    }

    cursor deref = iterator.cursor;
}

func print(ui ui_system ref, expand quad_info ui_quad_info, font ui_font, cursor font_cursor ref, format string, expand values lang_typed_value[])
{
    var buffer u8[4096];
    var builder string_builder;
    builder.text.base = buffer.base;
    builder.capacity  = buffer.count;
    builder.settings  = ui.builder_settings;

    write(builder ref, format, values);
    print(ui, quad_info, font, cursor, builder.text);
}

func print(ui ui_system ref, quad_info = ui_default_quad_info, font ui_font, expand position vec2, format string, expand values = {} lang_typed_value[])
{
    var cursor = cursor_at_baseline(font.info, position);
    print(ui, quad_info, font, cursor ref, format, values);
}

func print(ui ui_system ref, layer s32 = 0, saturation = 1.0, color = rgba8_white, font ui_font, expand position vec2, format string, expand values = {} lang_typed_value[])
{
    print(ui, { layer, saturation, color } ui_quad_info, font, position, format, values);
}

func print(ui ui_system ref, layer s32 = 0, saturation = 1.0, color = rgba8_white, font ui_font, cursor font_cursor ref, format string, expand values = {} lang_typed_value[])
{
    print(ui, { layer, saturation, color } ui_quad_info, font, cursor, format, values);
}

// TODO: if a default value is provided to an expand argument, use the default value per field for every skipped field
func print_aligned(ui ui_system ref, layer s32 = 0, saturation = 1.0, color = rgba8_white, font ui_font, expand position vec2, expand alignment = [ 0.5, 0.5 ] vec2, format string, expand arguments = {} lang_typed_value[]) (box box2)
{
    return print_aligned(ui, { layer, saturation, color } ui_quad_info, font, position, alignment, format, arguments);
}

func print_aligned(ui ui_system ref, quad_info ui_quad_info, font ui_font, expand position vec2, expand alignment = [ 0.5, 0.5 ] vec2, format string, expand arguments = {} lang_typed_value[]) (box box2)
{
    var align_state = draw_aligned_begin(ui, position, alignment);

    print(ui, quad_info, font, {} vec2, format, arguments);

    var box = draw_aligned_end(ui, align_state);

    // debug text box
    // draw_box_lines(ui, 10000, 1.0, [ 0, 0, 255, 255 ] rgba8, box, 1);

    return box;
}

func scissor_begin(ui ui_system ref, scissor_box box2) (previous_scissor_box box2)
{
    var previous_scissor_box = ui.scissor_box;
    ui.scissor_box = scissor_box;
    return previous_scissor_box;
}

func scissor_end(ui ui_system ref, previous_scissor_box box2)
{
    ui.scissor_box = previous_scissor_box;
}

struct ui_draw_aligned_state
{
    previous_print_box     box2;
    previous_scissor_box   box2;
    position               vec2;
    alignment              vec2;
    previous_command_count u32;
}

// to get the box of what is being currently drawn
func draw_box_begin(ui ui_system ref) (begin_box box2)
{
    var begin_box = ui.current_box;
    // HACK: inverted box
    ui.current_box = [ [ 100000.0, 100000.0 ] vec2, [ -100000.0, -100000.0 ] vec2 ] box2;

    return begin_box;
}

func draw_box_end(ui ui_system ref, begin_box box2) (result box2)
{
    var result = ui.current_box;
    ui.current_box = merge(begin_box, ui.current_box);

    return result;
}

func draw_aligned_begin(ui ui_system ref, expand position vec2, expand alignment = [ 0.5, 0.5 ] vec2) (state ui_draw_aligned_state)
{
    var state ui_draw_aligned_state;
    state.previous_print_box = draw_box_begin(ui);
    state.position = position;
    state.alignment = alignment;
    state.previous_command_count = ui.quad_command_count;

    // ignore scissor_box
    state.previous_scissor_box = ui.scissor_box;
    ui.scissor_box = [ [ -100000.0, -100000.0 ] vec2, [ 100000.0, 100000.0 ] vec2 ] box2;

    return state;
}

func draw_aligned_end(ui ui_system ref, state ui_draw_aligned_state) (box box2)
{
    var size = get_size(ui.current_box);
    var offset = v2(v2s(state.position - ui.current_box.min - scale(state.alignment, size)));

    var box = move(ui.current_box, offset);

    //var viewport_scale = [ 2.0 / ui.viewport_size.width, 2.0 / ui.viewport_size.height ] vec2;
    //offset = scale(offset, viewport_scale);

    ui.scissor_box = state.previous_scissor_box;

    var quad_command_count = minimum(ui.quad_commands.count cast(u32), ui.quad_command_count);
    var quad_command_index = state.previous_command_count;
    loop var command_index = state.previous_command_count; quad_command_count
    {
        var command = ui.quad_commands[command_index];

        var box box2;
        box.min = scale(command.vertices[0].position + 1, ui.viewport_size * 0.5) + offset;
        box.max = scale(command.vertices[2].position + 1, ui.viewport_size * 0.5) + offset;

        var uv_box box2;
        uv_box.min = command.vertices[0].uv;
        uv_box.max = command.vertices[2].uv;
        var result = get_quad_intersection(ui, box, uv_box);
        if not result.ok
        {
            ui.quad_command_count -= 1;
            continue;
        }

        {
            command.vertices[0].position = result.intersection_box.min;
            command.vertices[0].uv       = result.intersection_uv_box.min;

            command.vertices[2].position = result.intersection_box.max;
            command.vertices[2].uv       = result.intersection_uv_box.max;

            command.vertices[1].position.x = command.vertices[2].position.x;
            command.vertices[1].position.y = command.vertices[0].position.y;
            command.vertices[1].uv.x       = command.vertices[2].uv.x;
            command.vertices[1].uv.y       = command.vertices[0].uv.y;

            command.vertices[3].position.x = command.vertices[0].position.x;
            command.vertices[3].position.y = command.vertices[2].position.y;
            command.vertices[3].uv.x       = command.vertices[0].uv.x;
            command.vertices[3].uv.y       = command.vertices[2].uv.y;
        }

        ui.quad_commands[quad_command_index] = command;
        quad_command_index += 1;
    }

    // debug
    // draw_box_lines(ui, 100, 1.0, [ 255, 0, 0, 255 ] rgba8, box, 2);
    // draw_box_lines(ui, 100, 1.0, [ 0, 0, 255, 255 ] rgba8, [ state.position -5, state.position + 5 ] box2, 2);

    ui.current_box = box;
    draw_box_end(ui, state.previous_print_box);

    return box;
}

func boxed_print(ui ui_system ref, box box2, font ui_font, text_color rgba8, format string, expand arguments = {} lang_typed_value[])
{
    var text = allocate_text(ui.memory ref, ui.builder_settings, format, arguments);
    boxed_text(ui, box, font, text_color, text);
    free(ui.memory ref, text.base);
}

func boxed_text(ui ui_system ref, box box2, font ui_font, text_color rgba8, text string)
{
    var text_size = get_text_size(font.info, text);

    var box_size = box.max - box.min;

    var position vec2;
    position.x = (box.min.x + ((box_size.width  - text_size.width) / 2)) cast(s32);
    position.y = (box.min.y + font.info.bottom_margin + ((box_size.height - text_size.height) / 2)) cast(s32);

    print(ui, text_color, font, position, text);
}

func get_letterbox_canvas(ui ui_system ref, target_width_over_height = 16.0 / 9.0) (canvas_box box2)
{
    var canvas_box box2;
    var canvas_size = ui.viewport_size;
    var width_over_height = ui.viewport_size.x / ui.viewport_size.y;

    if width_over_height >= target_width_over_height
        canvas_size.x = canvas_size.y * target_width_over_height;
    else
        canvas_size.y = canvas_size.x / target_width_over_height;

    canvas_box = box2_size((ui.viewport_size - canvas_size) * 0.5, canvas_size);
    canvas_box.min.x = floor(canvas_box.min.x);
    canvas_box.min.y = floor(canvas_box.min.y);
    canvas_box.max.x = ceil(canvas_box.max.x);
    canvas_box.max.y = ceil(canvas_box.max.y);

    return canvas_box;
}

func apply_letterbox_canvas(ui ui_system ref, canvas_box box2)
{
    ui.viewport_size = get_size(canvas_box);
    ui.cursor -= canvas_box.min;
    clear_sissor_box(ui);
}

func draw_letterbox_border(ui ui_system ref, expand quad_info = { 0x7FFFFFFF, 1.0, [ 20, 20, 20, 255 ] rgba8 } ui_quad_info, canvas_box box2)
{
    if canvas_box.min.x is_not 0
    {
        draw_box(ui, quad_info, v2(0), v2(canvas_box.min.x, canvas_box.max.y));
        draw_box(ui, quad_info, v2(canvas_box.max.x, 0), v2(ui.viewport_size.width, canvas_box.max.y));
    }
    else
    {
        draw_box(ui, quad_info, v2(0), v2(canvas_box.max.x, canvas_box.min.y));
        draw_box(ui, quad_info, v2(0, canvas_box.max.y), v2(canvas_box.max.x, ui.viewport_size.height));
    }
}

func ui_to_clip(ui ui_system ref, ui_point vec2, z f32 = -1) (clip_point vec3)
{
    var clip_point = vec3_expand(scale(ui_point, 2 / ui.viewport_size) - 1, z);
    return clip_point;
}

func clip_to_ui(ui ui_system ref, clip_point vec3) (ui_point vec2)
{
    var ui_point = scale(vec2_cut(clip_point) + 1, ui.viewport_size * 0.5);
    return ui_point;
}

struct ui_editable_text
{
    expand base editable_text;
    is_active b8;
}

func ui_make_quad_info(layer s32 = 0, saturation = 1.0, color = rgba8_white) (quad_info ui_quad_info)
{
    return { layer, saturation, color } ui_quad_info;
}

func ui_make_quad_info(layer s32 = 0, saturation = 1.0, color vec4) (quad_info ui_quad_info)
{
    return { layer, saturation, to_premultiplied_rgba8(color) } ui_quad_info;
}

func ui_edit_text_box(ui ui_system ref, id ui_id, priority f32, expand quad_info = ui_default_quad_info, font ui_font, box box2, expand alignment = [ 0, 1 ] vec2, text ui_editable_text ref, characters platform_character[] ref)
{
    // display line wrapped chat log
    var wrapped_scope = ui_wrapped_text_box_begin(ui, quad_info.layer, font, box, alignment);
    //ui_wrapped_text_box_append(ui, wrapped_scope ref, text);

    multiline_comment
    {
    if not text.is_active
    {
        var i u32;
        label character_loop loop i; characters.count
        {
            var character = characters[i];
            if not character.is_character
            {
                switch character.code
                case platform_special_character.enter
                {
                    text.base_is_active = true;
                    carret_blink_time = 0;
                    break;
                }
            }
        }

        characters.base  += i;
        characters.count -= i;
    }
    }

    if button(ui, id, box, priority)
        text.is_active = true;

    if text.is_active
    {

        var character_count = characters.count;
        if edit_text(text.base ref, characters)
            ui.carret_blink_time = 0.0;

        if character_count is_not characters.count
        {
            // HACK
            var character = (characters.base - 1) deref;
            if not character.is_character and (character.code is platform_special_character.enter)
            {
                text.is_active = false;
            }
        }
    }

    {
        var left  = { text.base.edit_offset, text.base.buffer.base } string;
        var right = { text.base.used_count - text.base.edit_offset, text.base.buffer.base + text.base.edit_offset} string;

        ui_wrapped_text_box_append(ui, wrapped_scope ref, left);

        if text.is_active
        {
            var carret_color = [ 50, 255, 150, ((sin(2 * pi32 * (0.25 + ui.carret_blink_time)) * 0.5 + 0.5) * 255) cast(u8) ] rgba8;
            //var carret_cursor = cursor;
            draw_box(ui, 102, carret_color, { v2(wrapped_scope.cursor.position) - v2(1, wrapped_scope.font.info.bottom_margin + 2), v2(wrapped_scope.cursor.position) + v2(1, wrapped_scope.font.info.line_spacing - wrapped_scope.font.info.bottom_margin + 2) } box2);
        }

        ui_wrapped_text_box_append(ui, wrapped_scope ref, right);
    }

    ui_wrapped_text_box_end(ui, wrapped_scope);
}


struct ui_wrapped_text_box_scope
{
    aligned_state ui_draw_aligned_state;
    font          ui_font;
    cursor        font_cursor;
    box box2;
    layer         s32;
}

func ui_wrapped_text_box_begin(ui ui_system ref, layer s32 = 0, font ui_font, box box2, expand alignment = [ 0, 1 ] vec2) (scope ui_wrapped_text_box_scope)
{
    var scope ui_wrapped_text_box_scope;
    scope.font = font;
    var pivot = get_point(box, alignment);
    scope.aligned_state = draw_aligned_begin(ui, pivot, alignment);
    scope.cursor = cursor_at_baseline(font.info, 0, 0);
    scope.layer = layer;
    scope.box = box;

    return scope;
}

func ui_wrapped_text_box_end(ui ui_system ref, scope ui_wrapped_text_box_scope)
{
    var old_scissor_box = scope.aligned_state.previous_scissor_box;
    scope.aligned_state.previous_scissor_box = scope.box;
    draw_aligned_end(ui, scope.aligned_state);
    ui.scissor_box = old_scissor_box;
}

func ui_wrapped_text_box_append(ui ui_system ref, scope ui_wrapped_text_box_scope ref, text string)
{
    var font = scope.font;
    var cursor = scope.cursor ref;
    var layer = scope.layer;

    var white_space = " \t\n\r";
    var it = text;
    while it.count
    {
        var token = try_skip_until_set(it ref, white_space, false, true);
        if token.count
        {
            var width = get_text_size(font.info, token).width;
            if (cursor.position.x + width) > (scope.box.max.x - scope.box.min.x)
                print(ui, layer, font, cursor, "\n");

            print(ui, layer, font, cursor, token);
        }

        var space_text string;
        space_text.base = it.base;
        space_text.count = try_skip_set(it ref, white_space);
        if space_text.count
            print(ui, layer, font, cursor, space_text);
    }
}