
module ui;

type ui_id u64;

func box_is_hot(ui ui_system ref, box box2) (result b8)
{
    var cursor = ui.cursor;

    var result = get_intersection(box, ui.scissor_box);
    if not result.ok
        return false;

    return (result.intersection.min.x <= cursor.x) and (cursor.x < result.intersection.max.x) and (result.intersection.min.y <= cursor.y) and (cursor.y < result.intersection.max.y);
}

func request_active(ui ui_system ref, id ui_id, active_mask u32) (ok b8)
{
    if ui.hot_id is id
    {
        assert(ui.active_id is 0);
        ui.active_id = id;
        ui.active_mask = active_mask;

        return true;
    }
    else
    {
        return false;
    }
}

func release_active(ui ui_system ref, id ui_id)
{
    assert(ui.active_id is id);
    ui.active_id = 0;
    // we don't clear the ui.active_mask, so it can be used
}

func request_hot(ui ui_system ref, id ui_id, priority f32)
{
    if ui.next_hot_priority > priority
    {
        ui.next_hot_id       = id;
        ui.next_hot_priority = priority;
    }
}

func id_is_active(ui ui_system ref, id ui_id) (is_hot b8)
{
    return ui.active_id is id;
}

func id_is_hot(ui ui_system ref, id ui_id) (is_hot b8)
{
    return ui.hot_id is id;
}

func drag(ui ui_system ref, id ui_id, cursor vec2, active_mask u32, is_hot b8, priority f32 = 0) (has_changed b8, is_dragging b8, displacement vec2)
{
    assert(id);

    var has_changed = false;
    var is_dragging = false;
    var displacement vec2;

    if ui.active_id is id
    {
        if (active_mask bit_and ui.active_mask) is 0
        {
            release_active(ui, id);
            has_changed = true;
        }
        else
        {
            is_dragging = true;
        }

        displacement = cursor - ui.drag_start_cursor;
    }
    else if active_mask and request_active(ui, id, active_mask)
    {
        ui.drag_start_cursor = cursor;
        has_changed = true;
        is_dragging = true;
    }

    if is_hot
        request_hot(ui, id, priority);

    return has_changed, is_dragging, displacement;
}

func button(ui ui_system ref, id ui_id, box box2, priority f32 = 0) (was_pressed b8)
{
    return button(ui, id, ui.cursor_left_active, box_is_hot(ui, box), priority);
}

func button(ui ui_system ref, id ui_id, active_mask u32, is_hot b8, priority f32 = 0) (was_pressed b8)
{
    assert(id);

    var was_pressed = false;
    if ui.active_id is id
    {
        if (active_mask bit_and ui.active_mask) is 0
        {
            release_active(ui, id);
            was_pressed = is_hot;
        }
    }
    else if active_mask
    {
        request_active(ui, id, active_mask);
    }

    if is_hot
        request_hot(ui, id, priority);

    return was_pressed;
}

func slider(ui ui_system ref, id ui_id, influence vec2, min f32, max f32, value f32 ref, cursor vec2, is_active b8, is_hot b8, priority f32 = 0)
{
    var result = drag(ui, id, cursor, is_active cast(u32), is_hot, priority);
    if result.is_dragging
        value deref = (dot(result.displacement, influence) - min) / (max - min);
}

func location_id(index u32 = 0, location = get_call_location()) (id ui_id)
{
    assert(location.file_index < (1 bit_shift_left 16));
    assert(location.line < (1 bit_shift_left 20));
    assert(index < (1 bit_shift_left 30));

    return (location.file_index cast(ui_id) bit_shift_left 50) bit_or (location.line cast(ui_id) bit_shift_left 30) bit_or index;
}
