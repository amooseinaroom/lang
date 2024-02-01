
def game_title = "template";

struct program_state
{
    expand default default_program_state;
}

func game_init program_init_type
{
    state.letterbox_width_over_heigth = 16.0 / 9.0;
}

func game_update program_update_type
{
    var memory  = state.memory ref;
    var tmemory = state.temporary_memory ref;
    var ui      = state.ui ref;

    var font = state.font;

    // update(platform, state);

    var cursor = cursor_below_position(font.info, 20, ui.viewport_size.height - 20);
    print(ui, 10, font, cursor ref,  "fps: %\nhello world\n", 1.0 / platform.delta_seconds);

    if platform.do_quit
    {
    }

    return true;
}

enum render_texture_slot render_texture_slot_base
{
}