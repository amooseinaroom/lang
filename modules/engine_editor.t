
module engine_editor;

import platform;
import memory;
import im;
import ui;
import gizmo_3d;
import math;
import camera;

struct engine_editor
{
    memory memory_arena;

    entities engine_entity[];

    snap_grid_size f32;
    ui_scale       f32;
    ui_thickness   f32;

    is_active b8;

    //camera_is_active b8;
    camera fly_camera;
}

struct engine_entity
{
    to_parent         mat_transform;
    to_world          mat_transform;
    to_world_rotation quat;
}

func init(editor engine_editor ref)
{
    var memory = editor.memory ref;
    init(memory);

    var entities = editor.entities ref;
    reallocate_array(memory, entities, 2);
    entities[0].to_world = mat4_transform(quat_identity, v3(0, 1, 0));
    entities[1].to_world = mat4_transform(quat_identity, v3(1, 0, 0));

    editor.snap_grid_size = 1;
    editor.ui_scale       = 128;
    editor.ui_thickness   = 2;
}

func update(editor engine_editor ref, platform platform_api ref, window platform_window ref, im im_api ref, ui ui_system ref, tmemory memory_arena ref)
{
    update(editor.camera ref, platform, window);

    loop var i u32; editor.entities.count cast(u32)
    {
        var entity = editor.entities[i] ref;

        if draw_move_gizmo(editor, im, ui, location_id(i * 6), entity.to_world.translation ref)
        {

        }

        //draw_rotate_gizmo(im, ui, location_id(i * 3), entity.to_world.translation, entity.to_world_rotation ref, editor.ui_scale, editor.ui_thickness);

        //push_transform(im im_api ref, entity.to_world);
    }
}

func draw_move_gizmo(editor engine_editor ref, im im_api ref, ui ui_system ref, id_base ui_id, position vec3 ref) (is_active b8)
{
    return draw_move_gizmo(im, ui, id_base, position, 0, editor.ui_scale, editor.ui_thickness);
}

