
module gizmo_3d;

import platform;
import ui;
import im;
import math;

func to_world_scale(im im_api ref, ui ui_system ref, world_point vec3, ui_scale f32) (world_scale f32)
{
    var clip_point = project(im.world_to_clip, world_point);
    var clip_up = clip_point + [ 0, 1, 0 ] vec3;
    var world_scale = length(project(im.clip_to_world, clip_up) - world_point) * ui_scale / (0.5 * ui.viewport_size.height);
    return world_scale;
}

func draw_move_gizmo_xz(im im_api ref, ui ui_system ref, id_base ui_id, position vec3 ref, snap_grid_size f32, ui_scale f32, ui_thickness f32) (is_active b8)
{
    var is_active = drag_line(im, ui, id_base + (0 bit_shift_left 16), position, [ 1, 0, 0 ] vec3, ui_scale, [ 1.0, 0.1, 0.1, 1.0 ] vec4, 2 * ui_thickness);
    //drag_line(im, ui, id_base + (1 bit_shift_left 16), position, [ 0, 1, 0 ] vec3, world_scale, [ 0.1, 1.1, 0.1, 1.0 ] vec4, 2 * ui_thickness, thickness);
    is_active or= drag_line(im, ui, id_base + (2 bit_shift_left 16), position, [ 0, 0, 1 ] vec3, ui_scale, [ 0.1, 0.1, 1.0, 1.0 ] vec4, 2 * ui_thickness);

    is_active or= drag_plane(im, ui, id_base + (3 bit_shift_left 16), position, [ 1, 0, 0 ] vec3, [ 0, 0, 1 ] vec3, ui_scale, [ 1.0, 0.1, 1.0, 1.0 ] vec4, 2 * ui_thickness);

    if is_active and (snap_grid_size is_not 0)
    {
        var value = position deref * (1 / snap_grid_size);

        loop var i; 3
            value[i] -= fmod(value[i], 1.0);

        position deref = value * snap_grid_size;
    }

    //push_line(im, position deref, position deref + [ 0, world_scale, 0 ] vec3, [ 0.1, 1.0, 0.1, 1.0 ] vec4, thickness);
    //push_line(im, position deref, position deref + [ 0, 0, world_scale ] vec3, [ 0.1, 0.1, 1.0, 1.0 ] vec4, thickness);

    return is_active;
}

func draw_move_gizmo(im im_api ref, ui ui_system ref, id_base ui_id, position vec3 ref, snap_grid_size f32, ui_scale f32, ui_thickness f32) (is_active b8)
{
    var is_active = drag_line(im, ui, id_base + 0, position, [ 1, 0, 0 ] vec3, ui_scale, [ 1.0, 0.1, 0.1, 1.0 ] vec4, 2 * ui_thickness);
    is_active or=   drag_line(im, ui, id_base + 1, position, [ 0, 1, 0 ] vec3, ui_scale, [ 0.1, 1.0, 0.1, 1.0 ] vec4, 2 * ui_thickness);
    is_active or=   drag_line(im, ui, id_base + 2, position, [ 0, 0, 1 ] vec3, ui_scale, [ 0.1, 0.1, 1.0, 1.0 ] vec4, 2 * ui_thickness);

    is_active or=   drag_plane(im, ui, id_base + 3, position, [ 0, 1, 0 ] vec3, [ 1, 0, 0 ] vec3, ui_scale, [ 1.0, 1.0, 0.1, 1.0 ] vec4, 2 * ui_thickness);
    is_active or=   drag_plane(im, ui, id_base + 4, position, [ 0, 1, 0 ] vec3, [ 0, 0, 1 ] vec3, ui_scale, [ 0.1, 1.0, 1.0, 1.0 ] vec4, 2 * ui_thickness);
    is_active or=   drag_plane(im, ui, id_base + 5, position, [ 1, 0, 0 ] vec3, [ 0, 0, 1 ] vec3, ui_scale, [ 1.0, 0.1, 1.0, 1.0 ] vec4, 2 * ui_thickness);

    if is_active and (snap_grid_size is_not 0)
    {
        var value = position deref * (1 / snap_grid_size);

        loop var i; 3
            value[i] -= fmod(value[i], 1.0);

        position deref = value * snap_grid_size;
    }

    //push_line(im, position deref, position deref + [ 0, world_scale, 0 ] vec3, [ 0.1, 1.0, 0.1, 1.0 ] vec4, thickness);
    //push_line(im, position deref, position deref + [ 0, 0, world_scale ] vec3, [ 0.1, 0.1, 1.0, 1.0 ] vec4, thickness);

    return is_active;
}

func draw_rotate_gizmo(im im_api ref, ui ui_system ref, id_base ui_id, center vec3, rotation quat ref, snap_rotation_turns f32, ui_radius f32, ui_thickness f32) (is_active b8)
{
    var is_active   = drag_circle(im, ui, id_base + 0, center, rotation, [ 1, 0, 0 ] vec3, [ 0, 1, 0 ] vec3, snap_rotation_turns, ui_radius, [ 1, 0, 0, 1 ] vec4, ui_thickness);
    is_active bit_or= drag_circle(im, ui, id_base + 1, center, rotation, [ 0, 1, 0 ] vec3, [ 0, 0, 1 ] vec3, snap_rotation_turns, ui_radius, [ 0, 1, 0, 1 ] vec4, ui_thickness);
    is_active bit_or= drag_circle(im, ui, id_base + 2, center, rotation, [ 0, 0, 1 ] vec3, [ 1, 0, 0 ] vec3, snap_rotation_turns, ui_radius, [ 0, 0, 1, 1 ] vec4, ui_thickness);
    return is_active;
}

func draw_transform_gizmo(im im_api ref, ui ui_system ref, id_base ui_id, translation vec3 ref, rotation quat ref, snap_grid_size f32, ui_scale f32, ui_thickness f32) (is_active b8)
{
    var is_active = draw_move_gizmo(im, ui, id_base, translation, snap_grid_size, ui_scale, ui_thickness);
    var snap_rotation_turns = 1 / 24.0;
    is_active bit_or= draw_rotate_gizmo(im, ui, id_base + 6, translation deref, rotation, snap_rotation_turns, ui_scale * 3, ui_thickness);

    return is_active;
}

var global drag_start vec3;
var global drag_offset vec3;

func drag_line(im im_api ref, ui ui_system ref, id ui_id, position vec3 ref, world_direction vec3, ui_scale f32, color vec4, ui_thickness f32) (is_active b8)
{
    var clip_position = project(im.world_to_clip, position deref);

    var world_scale = to_world_scale(im, ui, position deref, ui_scale);

    var world_to = position deref + (world_direction * world_scale);
    var world_thickness = world_scale * ui_thickness / ui_scale;

    // in ui space
    var from = clip_to_ui(ui, clip_position);
    var to   = clip_to_ui(ui, project(im.world_to_clip, world_to));
    var direction = to - from;
    var bi_direction = normalize(rotate_counter_clockwise(direction));

    var relative_cursor = ui.cursor - from;
    var distance    = dot(direction, relative_cursor) / squared_length(direction);
    var bi_distance = dot(bi_direction, relative_cursor);
    var is_hot = (0 <= distance) and (distance <= 1) and (-ui_thickness <= bi_distance) and (bi_distance <= ui_thickness);

    var result = drag(ui, id, ui.cursor, ui.cursor_left_active, is_hot);
    if result.has_changed and result.is_dragging
    {
        var hit_point = get_line_intersection(im.clip_to_world, ui, from, ui.cursor, direction, position deref, world_direction).point;

        drag_start  = position deref;
        drag_offset = drag_start - hit_point;
    }
    else if result.is_dragging
    {
        var hit_result = get_line_intersection(im.clip_to_world, ui, ui.drag_start_cursor, ui.cursor, direction, drag_start, world_direction);

        if hit_result.ok
        {
            position deref = hit_result.point + drag_offset;
        }
    }

    if id_is_active(ui, id) or id_is_hot(ui, id)
        world_thickness *= 2;

    push_line(im, position deref, world_to, color); //, world_thickness);

    return result.is_dragging;
}

func drag_plane(im im_api ref, ui ui_system ref, id ui_id, position vec3 ref, world_right vec3, world_forward vec3, ui_scale f32, color vec4, ui_thickness f32) (is_active b8)
{
    var world_scale = to_world_scale(im, ui, position deref, ui_scale);

    var right   = world_right   * world_scale;
    var forward = world_forward * world_scale;
    var world_normal = cross(world_forward, world_right);
    var size = 0.5;
    var offset = 1 - size;
    var corner  = position deref + ((right + forward) * offset);

    var plane plane3;
    plane.up = world_normal;
    plane.up_dot_origin = dot(plane.up, corner);

    var world_cursor_near   = project(im.clip_to_world, ui_to_clip(ui, ui.cursor, -1));
    var world_cursor_far    = project(im.clip_to_world, ui_to_clip(ui, ui.cursor, 1));

    var ray ray3;
    ray.origin    = world_cursor_near;
    ray.direction = world_cursor_far - world_cursor_near;

    var is_hot = false;

    var hit_result = get_hit_distance(ray, plane);
    var hit_point vec3;
    var right_distance   f32;
    var forward_distance f32;
    if hit_result.ok
    {
        hit_point = ray.direction * hit_result.distance + ray.origin;

        right_distance   = dot(right  , hit_point - position deref) / squared_length(right);
        forward_distance = dot(forward, hit_point - position deref) / squared_length(forward);

        is_hot = (offset <= right_distance) and (right_distance <= (offset + size)) and (offset <= forward_distance) and (forward_distance <= (offset + size));
    }

    is_hot or= id_is_active(ui, id);

    var result = drag(ui, id, ui.cursor, ui.cursor_left_active, is_hot);
    if hit_result.ok and (hit_result.distance > 0)
    {
        if result.has_changed and result.is_dragging
        {
            drag_start = position deref;
            // story the relative offset, relative to ui scale
            drag_offset = v3(right_distance, forward_distance, 0);
        }
        else if result.is_dragging
        {
            position deref = hit_point - (((right * drag_offset.x) + (forward * drag_offset.y)));
        }
    }
    else if result.is_dragging
    {
        position deref = drag_start;
    }

    var corners vec3[4];
    corners[0] = corner;
    corners[1] = corner + (forward * size);
    corners[2] = corner + ((right + forward) * size);
    corners[3] = corner + (right * size);

    var world_thickness = world_scale * ui_thickness / ui_scale;

    if id_is_hot(ui, id) or id_is_active(ui, id)
    {
        push_triangle(im, [ corners[0], corners[1], corners[2] ] vec3[3], color);
        push_triangle(im, [ corners[0], corners[2], corners[3] ] vec3[3], color);
    }
    else
    {
        push_line(im, corners[0], corners[1], color);
        push_line(im, corners[0], corners[3], color);
        push_line(im, corners[1], corners[2], color);
        push_line(im, corners[2], corners[3], color);
    }

    return result.is_dragging;
}

func drag_circle(im im_api ref, ui ui_system ref, id ui_id, center vec3, rotation quat ref, world_normal vec3, world_right vec3, snap_rotation_turns f32, ui_radius f32, color vec4, ui_thickness f32) (is_active b8)
{
    var world_radius = viewport_to_world_scale(im, center, ui_radius);

    var plane plane3;
    plane.up = world_normal;
    plane.up_dot_origin = dot(plane.up, center);

    var world_cursor_near   = project(im.clip_to_world, ui_to_clip(ui, ui.cursor, -1));
    var world_cursor_far    = project(im.clip_to_world, ui_to_clip(ui, ui.cursor, 1));

    var ray ray3;
    ray.origin    = world_cursor_near;
    ray.direction = world_cursor_far - world_cursor_near;

    var thickness = ui_thickness;

    var hit_result = get_hit_distance(ray, plane);
    var hit_point vec3;
    if hit_result.ok
    {
        var hit_point = ray.direction * hit_result.distance + ray.origin;
        var ui_distance = world_to_viewport_scale(im, hit_point, absolute(world_radius - length(hit_point - center)));

        var is_hot = ui_distance <= ui_thickness;
        is_hot or= id_is_active(ui, id);

        var global start_rotation quat;

        var result = drag(ui, id, ui.cursor, ui.cursor_left_active, is_hot);
        if hit_result.ok and (hit_result.distance > 0)
        {

            if result.has_changed and result.is_dragging
            {
                drag_start = hit_point;
                start_rotation = rotation deref;
            }
            else if result.is_dragging
            {
                var from = normalize(drag_start - center);
                var to   = normalize(hit_point - center);

                var angle = acos(dot(from, to));
                if dot(cross(from, to), world_normal) < 0
                    angle = -angle;

                var granularity = 2 * pi32 * snap_rotation_turns;
                angle = (angle / granularity - fmod(angle / granularity, 1.0)) * granularity;

                var delta_rotation = quat_axis_angle(world_normal, angle);
                rotation deref = multiply(start_rotation, delta_rotation);

                to = transform(mat4_transform(delta_rotation), from);

                push_line(im, center, from * world_radius + center, [ 1, 1, 0, 1 ] vec4);
                push_line(im, center, to   * world_radius + center, [ 0, 1, 1, 1 ] vec4);
            }
        }
        else if result.is_dragging
        {
            rotation deref = start_rotation;
        }
    }

    if id_is_active(ui, id) or id_is_hot(ui, id)
        thickness *= 2;

    var corner_count = 32;
    var from = world_right * world_radius;
    var circle_rotation = mat4_transform(quat_axis_angle(world_normal, pi32 * 2 / corner_count));
    loop var i; corner_count
    {
        var to = transform(circle_rotation, from);
        push_line(im, from + center, to + center, color, thickness, false);
        from = to;
    }

    return false;
}

// TODO: why is this working again?^^
func get_line_intersection(clip_to_world mat_projection, ui ui_system ref, ui_from vec2, ui_to vec2, ui_direction vec2, world_origin vec3, world_direction vec3) (ok b8, point vec3)
{
    var ui_displacement = ui_direction * (dot(ui_direction, ui_to - ui_from) / squared_length(ui_direction));
    ui_to = ui_from + ui_displacement;

    //line(ui, ui_from, ui_to, [ 0, 255, 0, 255 ] rgba8);

    var world_from_near = project(clip_to_world, ui_to_clip(ui, ui_from, -1));
    var world_to_near   = project(clip_to_world, ui_to_clip(ui, ui_to, -1));
    var world_to_far    = project(clip_to_world, ui_to_clip(ui, ui_to, 1));

    var forward = world_to_far - world_to_near;
    var right   = cross(forward, world_from_near - world_to_near);
    var plane plane3;
    plane.up = cross(right, forward);

    plane.up_dot_origin = dot(plane.up, world_to_near);

    var ray ray3;
    ray.origin = world_origin;
    ray.direction = world_direction;
    var hit_result = get_hit_distance(ray, plane);
    var point = ray.direction * hit_result.distance + ray.origin;

    return hit_result.ok, point;
}
