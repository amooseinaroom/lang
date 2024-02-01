module platform;

import random;
import memory;
import math;

def u32_invalid_index = -1 cast(u32);

// can be overriden
def platform_max_path_count = 512 cast(u32);

// need to be defined in specialized platform layer

func platform_init_type(platform platform_api ref);
func platform_window_init_type(platform platform_api ref, window platform_window ref, title string, width s32, height s32, x s32 = -1, y s32 = -1, monitor_id = {} platform_monitor_id);
func platform_window_init_type2(platform platform_api ref, window platform_window ref, title string, placement platform_window_placement);
func platform_window_set_fullscreen_type(platform platform_api ref, window platform_window ref, enable_fullscreen b8);
func platform_window_get_placement_type(platform platform_api ref, window platform_window ref) (placement platform_window_placement);
func platform_window_set_placement_type(platform platform_api ref, window platform_window ref, placement platform_window_placement);
func platform_window_frame_type(platform platform_api ref, window platform_window ref);
func platform_handle_messages_type(platform platform_api ref) (result b8);
func platform_update_time_type(platform platform_api ref);
func platform_wait_for_input_type(platform platform_api ref, wait_for_keyboard = true, wait_for_mouse = true, timeout_milliseconds = -1 cast(u32));

func platform_fatal_error_message_type(label string, location lang_code_location, condition_text string, format = "", expand arguments = {} lang_typed_value[]);

func platform_get_random_from_time_type(platform platform_api ref) (random random_pcg);

func platform_get_file_info_type(platform platform_api ref, path string) (result platform_file_info);
func platform_read_entire_file_type(data u8[], platform platform_api ref, path string) (result u8[]);
func platform_write_entire_file_type(platform platform_api ref, path string, data u8[]) (ok b8);
func platform_copy_file_type(platform platform_api ref, to_path string, from_path string, override = true) (ok b8);
func platform_create_directory_type(platform platform_api ref, path string, requires_is_new b8) (is_new b8);

func platform_file_search_init_type(platform platform_api ref, relative_path_pattern string) (iterator platform_file_search_iterator);
func platform_file_search_next_type(platform platform_api ref, iterator platform_file_search_iterator ref) (ok b8);

func platform_load_library_type(platform platform_api ref, name string) (library platform_library);
func platform_free_library_type(platform platform_api ref, library platform_library);
func platform_load_symbol_type(platform platform_api ref, library = {} platform_library, name string) (result u8 ref);
func platform_enable_console_type(platform platform_api ref = null);
func platform_print_type(text string);
func platform_debug_break_type();
func platform_exit_type(code s32);
func platform_memory_reserve_type(byte_count usize, location = get_call_location()) (base u8 ref);
func platform_memory_commit_type(base u8 ref, byte_count usize, location = get_call_location());
func platform_memory_free_type(base u8 ref, location = get_call_location());

func platform_thread_function(data u8 ref);

func platform_thread_init_type(thread platform_thread ref, platform platform_api ref, function platform_thread_function, data u8 ref);
func platform_thread_start_type(platform platform_api ref, thread platform_thread ref);
func platform_thread_wait_type(platform platform_api ref, thread platform_thread ref);

func platform_locked_increment_type(platform platform_api ref, value s64 ref) (incremented_value s64);
func platform_locked_decrement_type(platform platform_api ref, value s64 ref) (decremented_value s64);

func platform_sleep_milliseconds_type(platform platform_api ref, milliseconds u32);

func platform_realtime_counter_type() (counter u64);
func platform_elapsed_milliseconds_type(elapsed_realtime_counter u64) (milliseconds u64);
func platform_cpu_cycle_counter_type() (counter u64);

// platform_highest_bit_index returns 0 if mask is 0
func platform_highest_bit_index_type(mask u32) (bit_index u32);

func platform_get_executable_name_type(platform platform_api ref, buffer u8[]) (name string);
func platform_local_date_and_time_type(platform platform_api ref) (date_and_time platform_date_and_time);

// platform_api should be expanding on this
struct platform_api_base
{
    keys                  platform_button[256];
    character_buffer      platform_character[64];
    character_count       u32; // <= characters.count
    total_character_count u32;

    working_directory_buffer u8[512];
    working_directory string;

    mouse_wheel_delta f32; // 1.0 is one wheel turn

    gamepads platform_gamepad[4];

    logical_cpu_count u32;

    delta_seconds f32;

    do_quit b8;
}

struct platform_window_base
{
    size                    vec2s;

    mouse_position          vec2s;
    previous_mouse_position vec2s;

    is_resizeable b8;
    is_fullscreen b8;

    // user pressed close button
    do_close b8;
}

struct platform_file_search_iterator_base
{
    relative_path_prefix string;

    // only valid if platform_file_search_next returned true
    found_file struct
    {
        absolute_path_buffer u8[platform_max_path_count];
        relative_path_buffer u8[platform_max_path_count];
        absolute_path        string;
        relative_path        string;
        is_directory         b8;        
    };
}

// platform defined
// struct platform_window_placement
// struct platform_library {}
// struct platform_thread {}
// struct platform_file_search_iterator { expand base platform_file_search_iterator_base; }
// enum platform_key u8 {}
// enum platform_special_character u32 {}

struct platform_character
{
    code         u32;
    is_character b8;
    with_shift   b8;
    with_control b8;
    with_alt     b8;
}

func platform_get_characters(platform platform_api ref) (characters platform_character[])
{
    return { platform.character_count, platform.character_buffer.base } platform_character[];
}

struct platform_button
{
    is_active             b8;
    was_repeated          b8;
    half_transition_count u8;
}

func platform_button_was_pressed(button platform_button) (result b8)
{
    return button.half_transition_count >= (2 - button.is_active cast(u8));
}

func platform_button_was_released(button platform_button) (result b8)
{
    return button.half_transition_count >= (1 + button.is_active cast(u8));
}

func platform_key_is_active(platform platform_api ref, key u32) (result b8)
{
    return platform.keys[key].is_active;
}

func platform_key_was_repeated(platform platform_api ref, key u32) (result b8)
{
    return platform.keys[key].was_repeated;
}

func platform_key_was_pressed(platform platform_api ref, key u32) (result b8)
{
    return platform_button_was_pressed(platform.keys[key]);
}

func platform_key_was_released(platform platform_api ref, key u32) (result b8)
{
    return platform_button_was_released(platform.keys[key]);
}

func platform_button_update(button platform_button ref, is_active b8)
{
    // make sure overflow bit remains
    var overflow_mask = button.half_transition_count bit_and 0x80;
    var increment = (button.is_active is_not is_active) cast(u8);
    button.half_transition_count = (button.half_transition_count + increment) bit_or overflow_mask;

    button.is_active     = is_active;
    button.was_repeated = is_active;
}

func platform_button_poll(button platform_button ref, is_active b8)
{
    button.half_transition_count = (button.is_active is_not is_active) cast(u8);
    button.is_active    = is_active;
    button.was_repeated = false;
}

//def platform_button mask u8
//{
//    is_active                       u1;
//    half_transition_count           u6;
//    half_transition_count_over_flow u1;
//}

struct platform_gamepad
{
    left_stick  vec2;
    right_stick vec2;

    left_trigger  f32;
    right_trigger f32;

    left_stick_as_button    platform_button;
    right_stick_as_button   platform_button;
    left_trigger_as_button  platform_button;
    right_trigger_as_button platform_button;

    left_thumb  platform_button;
    right_thumb platform_button;

    left_shoulder  platform_button;
    right_shoulder platform_button;

    select platform_button;
    start  platform_button;

    direction union
    {
        buttons platform_button[4];

        expand button struct {
            left  platform_button;
            right platform_button;
            down  platform_button;
            up    platform_button;
        };
    };

    face union
    {
        buttons platform_button[4];

        expand button struct {
            left  platform_button;
            right platform_button;
            down  platform_button;
            up    platform_button;
        };
    };

    is_connected b8;
}

type vec2s union
{
    expand xy     struct { x     s32; y      s32; };
    expand size   struct { width s32; height s32; };
    expand values s32[2];
};

override(lang) func require assert_type
{
    if not condition
        platform_fatal_error_message("Requirement Failed", location, condition_text, format, arguments);
}

override(lang) func assert assert_type
{
    if lang_debug
    {
        if not condition
            platform_fatal_error_message("Assertion Failed", location, condition_text, format, arguments);
    }
}

struct platform_file_info
{
    byte_count      u64;
    write_timestamp u64;
    ok b8;
}

struct platform_date_and_time
{
    year         u32;
    month        u8;
    day          u8;
    week_day     u8;
    hour         u8;
    minute       u8;
    second       u8;
    milli_second u16;
}

// for convenience
func as_cstring(text string, location = get_call_location()) (result cstring)
{
    assert(text[text.count - 1] is 0, "text needs to be 0-terminated", location);
    return text.base cast(cstring);
}

func platform_read_entire_file(platform platform_api ref, arena memory_arena ref, path string) (result u8[])
{
    var result = try_platform_read_entire_file(platform, arena, path);
    assert(result.ok);

    return result.data;
}

func try_platform_read_entire_file(platform platform_api ref, arena memory_arena ref, path string) (ok b8, data u8[])
{
    var info = platform_get_file_info(platform, path);
    if not info.ok
        return false, {} u8[];

    var data u8[];
    data.count = info.byte_count;
    data.base  = allocate(arena, data.count, 1);
    platform_read_entire_file(data, platform, path);

    return true, data;
}
