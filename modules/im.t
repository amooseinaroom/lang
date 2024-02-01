
module im;

import platform;
import memory;
import gl;
import math;

struct im_api
{
    memory memory_arena;

    shader im_shader;

    viewport_size  vec2;
    camera_to_world mat_transform;
    clip_to_world   mat_projection;
    world_to_clip   mat_projection;

    im_frame_called b8;

    vertices im_vertex[];

    // gl specific

    white_texture gl_texture;
    vertex_buffer gl_vertex_buffer;
    camera_uniform_buffer gl_uniform_buffer;
}

func init(im im_api ref, platform platform_api ref, gl gl_api ref)
{
    init(im.memory ref);

    reload_shader(gl, im.shader, "im", get_type_info(im_vertex_attribute), get_type_info(im_uniform_buffer_binding), im_vertex_shader_source, false, im_fragment_shader_source);
    assert(im.shader.diffuse_texture is_not -1);

    // TODO make u8[] fixed array cast to u8[]
    // casting const away!
    var data u8[];
    data.base  = rgba8_white.base cast(u8 ref);
    data.count = rgba8_white.count;
    im.white_texture = gl_create_texture_2d(1, 1, data, GL_RGBA);
}

func clear(im im_api ref)
{
    clear(im.memory ref);
    im.vertices = {} im_vertex[];
}

func im_frame(im im_api ref, viewport_size vec2, camera_to_world mat_transform, camera_to_clip mat_projection, clip_to_camera mat_projection)
{
    assert(not im.im_frame_called, "", "forgot to call im_present last frame");
    im.im_frame_called = true;

    im.viewport_size   = viewport_size;
    im.camera_to_world = camera_to_world;
    im.clip_to_world   = im.camera_to_world * clip_to_camera;
    im.world_to_clip   = camera_to_clip * mat4_inverse_transform_unscaled(im.camera_to_world);
}

func im_present(im im_api ref, gl gl_api ref)
{
    assert(im.im_frame_called, "", "forgot to call im_frame this frame");
    im.im_frame_called = false;

    if im.vertices.count
    {
        {
            var camera im_camera_buffer;
            camera.world_to_clip         = im.world_to_clip;
            camera.camera_world_position = im.camera_to_world.translation_column;
            resize_buffer(gl, im.camera_uniform_buffer ref, im_uniform_buffer_binding.camera_buffer, camera);

            bind_uniform_buffer(im.camera_uniform_buffer);
        }

        var memory = im.memory ref;

        var render_vertices im_render_vertex[];
        reallocate_array(im.memory ref, render_vertices ref, im.vertices.count);

        var opaque_vertex_count u32;
        loop var i u32; im.vertices.count
        {
            if not im.vertices[i].is_transparent
            {
                render_vertices[opaque_vertex_count].position = im.vertices[i].position;
                render_vertices[opaque_vertex_count].color    = im.vertices[i].color;
                render_vertices[opaque_vertex_count].uv       = im.vertices[i].uv;
                opaque_vertex_count += 1;
            }
        }

        var transparent_vertex_count u32;
        loop var i u32; im.vertices.count
        {
            if im.vertices[i].is_transparent
            {
                render_vertices[opaque_vertex_count + transparent_vertex_count].position = im.vertices[i].position;
                render_vertices[opaque_vertex_count + transparent_vertex_count].color    = im.vertices[i].color;
                render_vertices[opaque_vertex_count + transparent_vertex_count].uv       = im.vertices[i].uv;
                transparent_vertex_count += 1;
            }
        }

        resize_buffer(gl, im.vertex_buffer ref, get_type_info(im_vertex_attribute), get_type_info(im_render_vertex), render_vertices.count, render_vertices.base);

        glUseProgram(im.shader.handle);
        glUniform1i(im.shader.diffuse_texture, 0);

        glActiveTexture(GL_TEXTURE0 + 0);
        glBindTexture(GL_TEXTURE_2D, im.white_texture.handle);

        glBindVertexArray(im.vertex_buffer.vertex_array);

        // opaque pass
        {
            glEnable(GL_DEPTH_TEST);
            glDisable(GL_BLEND);

            glDrawArrays(GL_TRIANGLES, 0, opaque_vertex_count cast(u32));
        }

        // transparent pass
        {
            glDisable(GL_DEPTH_TEST);

            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            glDrawArrays(GL_TRIANGLES, opaque_vertex_count, transparent_vertex_count cast(u32));
        }

        glBindVertexArray(0);
        glBindTexture(GL_TEXTURE_2D, 0);

        glUseProgram(0);
    }

    clear(im);
}

func im_skip_present(im im_api ref)
{
    assert(im.im_frame_called, "", "forgot to call im_frame this frame");
    im.im_frame_called = false;

    clear(im);
}

func push_triangle(im im_api ref, triangle vec3[3], color vec4)
{
    reallocate_array(im.memory ref, im.vertices ref, im.vertices.count + 3);

    var vertices = im.vertices[im.vertices.count - 3] ref cast(im_vertex[3] ref);

    loop var i; 3
    {
        vertices[i].position = triangle[i];
        vertices[i].color    = color;
    }
}

func push_triangle_lines(im im_api ref, triangle vec3[3], color vec4, expand style = im_default_opaque_style)
{
    push_line(im, triangle[0], triangle[1], color, style);
    push_line(im, triangle[1], triangle[2], color, style);
    push_line(im, triangle[2], triangle[0], color, style);
}

struct im_style
{
    viewport_thickness f32;
    is_transparent     b8;
}

def im_default_viewport_thickness = 2.0;
def im_default_opaque_style      = { im_default_viewport_thickness, false } im_style;
def im_default_transparent_style = { im_default_viewport_thickness, true } im_style;

func viewport_to_world_scale(im im_api ref, world_point vec3, viewport_scale f32) (world_scale f32)
{
    var world_scale = viewport_scale / (im.viewport_size.height * length((project(im.world_to_clip, world_point + im.camera_to_world.up) - project(im.world_to_clip, world_point)).xy));
    return world_scale;
}

func world_to_viewport_scale(im im_api ref, world_point vec3, world_scale f32) (viewport_scale f32)
{
    var viewport_scale = world_scale * (im.viewport_size.height * length((project(im.world_to_clip, world_point + im.camera_to_world.up) - project(im.world_to_clip, world_point)).xy));
    return world_scale;
}

func push_line(im im_api ref, from vec3, from_color vec4, to vec3, to_color vec4, expand style = im_default_opaque_style)
{
    reallocate_array(im.memory ref, im.vertices ref, im.vertices.count + 6);

    var vertices = im.vertices[im.vertices.count - 6] ref cast(im_vertex[6] ref);

    var from_thickness = viewport_to_world_scale(im, from, style.viewport_thickness);
    var to_thickness   = viewport_to_world_scale(im, to, style.viewport_thickness);

     //style.viewport_thickness / (im.viewport_size.height * length((project(im.world_to_clip, from + im.camera_to_world.up) - project(im.world_to_clip, from)).xy));
    //var to_thickness   = style.viewport_thickness / (im.viewport_size.height * length((project(im.world_to_clip, to   + im.camera_to_world.up)   - project(im.world_to_clip, to)).xy));

    var right = to - from;
    var from_up = normalize(cross(im.camera_to_world.translation - from, right)) * from_thickness;
    var to_up   = normalize(cross(im.camera_to_world.translation - to,   right)) * to_thickness;

    // first triangle
    vertices[0].position = from - from_up;
    vertices[0].color    = from_color;
    vertices[0].is_transparent = style.is_transparent;
    vertices[1].position = to - to_up;
    vertices[1].color    = to_color;
    vertices[1].is_transparent = style.is_transparent;
    vertices[2].position = to + to_up;
    vertices[2].color    = to_color;
    vertices[2].is_transparent = style.is_transparent;

    // second triangle
    vertices[3] = vertices[0];
    vertices[4] = vertices[2];
    vertices[5].position = from + from_up;
    vertices[5].color    = from_color;
    vertices[5].is_transparent = style.is_transparent;
}

func push_line(im im_api ref, from vec3, to vec3, color vec4, expand style = im_default_opaque_style)
{
    push_line(im, from, color, to, color, style);
}

func push_circle(im im_api ref, center vec3, radius f32, right vec3, up vec3, corner_count = 32, color vec4, expand style = im_default_opaque_style)
{
    var vertices im_vertex[];
    vertices.count = corner_count * 6;
    reallocate_array(im.memory ref, im.vertices ref, im.vertices.count + vertices.count);
    vertices.base  = im.vertices[im.vertices.count - vertices.count] ref;

    var thickness = viewport_to_world_scale(im, center, style.viewport_thickness);

    var forward = cross(right, up);
    var rotation = mat4_transform(quat_axis_angle(forward, pi32 * 2 / corner_count));

    //var camera_forward  = vec3_cut(im.camera_to_world[2]);
    //var camera_position = vec3_cut(im.camera_to_world[3]);

    var unit_circle_corner = right;

    var previous im_vertex[2];
    {
        var corner_up = unit_circle_corner * (thickness * 0.5);
        previous[0].position = unit_circle_corner * radius + center - corner_up;
        previous[0].color    = color;
        previous[0].is_transparent = style.is_transparent;
        previous[1].position = unit_circle_corner * radius + center + corner_up;
        previous[1].color    = color;
        previous[1].is_transparent = style.is_transparent;
    }

    loop var i; corner_count
    {
        var current im_vertex[2];

        unit_circle_corner = vec3_cut(rotation * vec4_expand(unit_circle_corner));

        var corner_up = unit_circle_corner * (thickness * 0.5);
        current[0].position = unit_circle_corner * radius + center - corner_up;
        current[0].color    = color;
        current[1].position = unit_circle_corner * radius + center + corner_up;
        current[1].color    = color;

        // first triangle
        vertices[i * 6 + 0] = previous[0];
        vertices[i * 6 + 1] = current[0];
        vertices[i * 6 + 2] = current[1];

        vertices[i * 6 + 3] = vertices[i * 6 + 0];
        vertices[i * 6 + 4] = vertices[i * 6 + 2];
        vertices[i * 6 + 5] = previous[1];

        previous = current;
    }
}

func push_circle(im im_api ref, center vec3, radius f32, corner_count = 32, color vec4, expand style = im_default_opaque_style)
{
    var forward = im.camera_to_world.translation - center;
    var right = normalize(cross(im.camera_to_world.up, forward));
    var up    = normalize(cross(right, forward));

    push_circle(im, center, radius, right, up, corner_count, color, style);
}

func push_transform(im im_api ref, world_to_camera mat_transform, alpha = 1.0, expand style = im_default_opaque_style)
{
    var translation = vec3_cut(world_to_camera[3]);
    push_line(im, translation, translation + vec3_cut(world_to_camera[0]), [ alpha, 0, 0, alpha ] vec4, style);
    push_line(im, translation, translation + vec3_cut(world_to_camera[1]), [ 0, alpha, 0, alpha ] vec4, style);
    push_line(im, translation, translation + vec3_cut(world_to_camera[2]), [ 0, 0, alpha, alpha ] vec4, style);
}

func push_perspective_projection(im im_api ref, camera_to_world mat_transform, camera_to_clip mat_projection, color vec4,  expand style = im_default_opaque_style)
{
    //var camera_to_world = mat4_inverse_transform(world_to_camera);
    var clip_to_camera = mat4_inverse_perspective_projection(camera_to_clip);
    var clip_to_world  = camera_to_world * clip_to_camera;

    var corners vec3[8];
    corners[0] = vec3_project(clip_to_world * [ -1, -1, -1, 1 ] vec4);
    corners[1] = vec3_project(clip_to_world * [  1, -1, -1, 1 ] vec4);
    corners[2] = vec3_project(clip_to_world * [ -1,  1, -1, 1 ] vec4);
    corners[3] = vec3_project(clip_to_world * [  1,  1, -1, 1 ] vec4);
    corners[4] = vec3_project(clip_to_world * [ -1, -1,  1, 1 ] vec4);
    corners[5] = vec3_project(clip_to_world * [  1, -1,  1, 1 ] vec4);
    corners[6] = vec3_project(clip_to_world * [ -1,  1,  1, 1 ] vec4);
    corners[7] = vec3_project(clip_to_world * [  1,  1,  1, 1 ] vec4);

    push_frustum(im, corners, color, style);
}

func push_orthographic_projection(im im_api ref, camera_to_world mat_transform, camera_to_clip mat_projection, color vec4, expand style = im_default_opaque_style)
{
    var clip_to_camera = mat4_inverse_orthographic_projection(camera_to_clip);
    var clip_to_world  = camera_to_world * clip_to_camera;

    var corners vec3[8];
    corners[0] = vec3_project(clip_to_world * [ -1, -1, -1, 1 ] vec4);
    corners[1] = vec3_project(clip_to_world * [  1, -1, -1, 1 ] vec4);
    corners[2] = vec3_project(clip_to_world * [ -1,  1, -1, 1 ] vec4);
    corners[3] = vec3_project(clip_to_world * [  1,  1, -1, 1 ] vec4);
    corners[4] = vec3_project(clip_to_world * [ -1, -1,  1, 1 ] vec4);
    corners[5] = vec3_project(clip_to_world * [  1, -1,  1, 1 ] vec4);
    corners[6] = vec3_project(clip_to_world * [ -1,  1,  1, 1 ] vec4);
    corners[7] = vec3_project(clip_to_world * [  1,  1,  1, 1 ] vec4);

    push_frustum(im, corners, color, style);
}

func push_frustum(im im_api ref, corners vec3[8], color vec4, expand style = im_default_opaque_style)
{
    push_line(im, corners[0], corners[1], color, style);
    push_line(im, corners[0], corners[2], color, style);
    push_line(im, corners[2], corners[3], color, style);
    push_line(im, corners[1], corners[3], color, style);

    push_line(im, corners[4], corners[5], color, style);
    push_line(im, corners[4], corners[6], color, style);
    push_line(im, corners[6], corners[7], color, style);
    push_line(im, corners[5], corners[7], color, style);

    push_line(im, corners[0], corners[4], color, style);
    push_line(im, corners[1], corners[5], color, style);
    push_line(im, corners[2], corners[6], color, style);
    push_line(im, corners[3], corners[7], color, style);
}

func push_box(im im_api ref, box box3, color vec4, expand style = im_default_opaque_style)
{
    var corners vec3[8];

    loop var i; corners.count
    {
        corners[i] = get_point(box, [ i bit_and 1, (i bit_shift_right 1) bit_and 1, (i bit_shift_right 2) bit_and 1 ] vec3);
    }

    push_frustum(im, corners, color, style);
}

func push_box(im im_api ref, to_world mat_transform, box box3, color vec4, expand style = im_default_opaque_style)
{
    var corners vec3[8];
    loop var i; corners.count
    {
        corners[i] = transform(to_world, get_point(box, [ i bit_and 1, (i bit_shift_right 1) bit_and 1, (i bit_shift_right 2) bit_and 1 ] vec3));
    }

    push_frustum(im, corners, color, style);
}

enum im_vertex_attribute
{
    position;
    uv;
    color;
}

enum im_uniform_buffer_binding u32
{
    camera_buffer;
}

struct im_vertex
{
    color          vec4;
    position       vec3;
    uv             vec2;
    is_transparent b8;
}

struct im_render_vertex
{
    color    vec4;
    position vec3;
    uv       vec2;
}

struct im_shader
{
    handle u32;
    diffuse_texture s32;
}

struct im_camera_buffer
{
    world_to_clip         mat_projection;
    camera_world_position vec4;
}

def im_vertex_shader_source   = import_text_file("glsl/im.vert.glsl");
def im_fragment_shader_source = import_text_file("glsl/im.frag.glsl");

