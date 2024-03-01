import ui;
import im;
import camera;
import random;
import timing;
import font;

multiline_comment
{
    useage:
    define these values

    def game_title = "my_game";

    struct program_state
    {
        expand default default_program_state;

        // your additional state
    }

    func game_init program_init_type
    {

    }

    func game_update program_update_type
    {
    }
}

// can be overridden
def camera_fov = 0.5;
def game_settings_path = "settings.bin";
def use_render_system = true;

struct default_program_state
{
    expand base program_state_base;

    memory           memory_arena;
    temporary_memory memory_arena;

    actual_timing_table timing_table;

    gl gl_api;
    ui ui_system;
    im im_api;
    render render_system;

    window platform_window;
    camera fly_camera;

    font_memory memory_arena;
    font ui_font;

    random random_pcg;

    letterbox_width_over_heigth f32;

    memory_reload_used_byte_count usize;

    worker_threads platform_worker_threads;

    debug_is_active b8;
    debug_camera fly_camera;
}

struct platform_worker_threads
{
    platform     platform_api ref;
    threads      platform_thread[128];
    thread_count u32;

    jobs           worker_thread_job[1024];
    job_count      s64;
    next_job_index s64;
    done_job_count s64;
}

// COMPILER BUG functions are not treated as refs when checking for dependencies,
// so we need to use job ref in callback here
func worker_thread_job_callback(job worker_thread_job ref);

struct worker_thread_job
{
    callback worker_thread_job_callback;
    data     u8 ref;
}

func queue_job(workers platform_worker_threads ref, expand job worker_thread_job) (id u32)
{
    assert(workers.job_count < workers.jobs.count);
    var index = workers.job_count;
    workers.jobs[index] = job;
    platform_locked_increment(workers.platform, workers.job_count ref);

    return index;
}

func jobs_are_done(workers platform_worker_threads ref) (ok b8)
{
    if (workers.job_count is workers.done_job_count)
    {
        workers.job_count      = 0;
        workers.next_job_index = 0;
        workers.done_job_count = 0;

        return true;
    }

    return false;
}

func program_init program_init_type export
{
	var memory = state.memory ref;

    var tmemory = state.temporary_memory ref;
    init(tmemory);

    if timing_enabled
    {
        timing_init(120);
        state.actual_timing_table = global_timing_table;
    }

    if enable_print
        platform_enable_console(platform);

    var gl = state.gl ref;
    gl_init(gl, platform);

    var window_placement = load_game(platform, state);

    platform_window_init(platform, state.window ref, game_title, window_placement);
    gl_window_init(platform, gl, state.window ref);
    gl_set_vertical_sync(true);

    // crc32_init();

    init(state.ui ref, platform, gl);
    init(state.im ref, platform, gl);

    state.memory_reload_used_byte_count = temporary_begin(memory);

    init(state.font_memory ref);
    init(state.font ref, platform, state.font_memory ref, tmemory, "C:/windows/fonts/consola.ttf", 24, 1024);

    state.random = platform_get_random_from_time(platform);

    init(state.camera ref, { 0, 3, 3 } vec3, {} vec3);
    state.debug_camera = state.camera;

    var worker_threads = state.worker_threads ref;
    worker_threads.thread_count = platform.logical_cpu_count - 1;
    worker_threads.platform = platform;
    loop var i; worker_threads.thread_count
    {
        platform_thread_init(worker_threads.threads[i] ref, platform, get_function_reference(worker_thread_process platform_thread_function), worker_threads);
        platform_thread_start(platform, worker_threads.threads[i] ref);
    }

    // needs to be defined by user: func game_init program_init_type
    game_init(platform, state);
}

func worker_thread_process platform_thread_function
{
    var workers  = data cast(platform_worker_threads ref);
    var platform = workers.platform;

    while true
    {
        var next_job_index = platform_locked_increment(platform, workers.next_job_index ref);
        if (next_job_index <= workers.job_count)
        {
            var job = workers.jobs[next_job_index - 1] ref;
            var callback = job.callback;
            callback(job);
            var done_job_count = platform_locked_increment(platform, workers.done_job_count ref);
            assert(done_job_count <= workers.job_count);
        }
        else
        {
            platform_locked_decrement(platform, workers.next_job_index ref);
        }

        platform_sleep_milliseconds(platform, 15);
    }
}

func program_update program_update_type export
{
    if timing_enabled
        global_timing_table = state.actual_timing_table;

    timer_frame_begin();

    var memory = state.memory ref;

    var tmemory = state.temporary_memory ref;
    clear(tmemory);

    var gl       = state.gl ref;
    var ui       = state.ui ref;
    var im       = state.im ref;
    var window   = state.window ref;

	// sync console handles for hot realoding
    if enable_hot_reloading and lang_debug
        platform_enable_console(platform);

    if library_was_reloaded
    {
        // reset memory
        temporary_end(memory, state.memory_reload_used_byte_count);

		// crc32_init();
		gl_load_bindings();

		// HACK:
		platform_win32_ticks_per_second = platform.win32.ticks_per_second;

        if use_render_system
		    reload(state.render ref, platform, gl, tmemory);

        // FIX THIS
        platform_win32 = platform;
        platform_win32_console_output = platform.console_output;
        platform_win32_ticks_per_second = platform.ticks_per_second;
    }

    var font = state.font;

    var delta_seconds = minimum(platform.delta_seconds, 1.0 / 20.0);

    platform_window_frame(platform, window);
    var window_size = window.size;
    var mouse_position = window.mouse_position;

    // TODO: let user code be notified and enable them to react
    // now needs to happen after platform_window_frame
    if platform.do_quit or window.do_close
    {
        save_game(platform, state);
        platform.do_quit = true;
    }

    if platform_key_is_active(platform, platform_key.alt) and platform_key_was_pressed(platform, platform_key.enter)
        platform_window_set_fullscreen(platform, window, not window.is_fullscreen);

    ui_frame(ui, delta_seconds);
    ui_window(ui, platform, window);

    var letterbox = ui.scissor_box;
    if state.letterbox_width_over_heigth is_not 0
    {
        letterbox = get_letterbox_canvas(ui, state.letterbox_width_over_heigth);
        apply_letterbox_canvas(ui, letterbox);
    }

    var camera_to_clip = mat4_perspective_projection_fov(camera_fov, ui.viewport_size.x cast(f32) / ui.viewport_size.y, 0.1, 1000);
    var clip_to_camera = mat4_inverse_perspective_projection(camera_to_clip);
    var camera_to_world = state.camera.camera_to_world;

    if lang_debug
    {
        state.debug_is_active xor= platform_key_was_pressed(platform, platform_key.f0 + 1);

        if state.debug_is_active
        {
            update(state.debug_camera ref, platform, window);
            camera_to_world = state.debug_camera.camera_to_world;
        }
    }

    var world_to_clip = camera_to_clip * mat4_inverse_transform_unscaled(camera_to_world);
    var clip_to_world = camera_to_world * mat4_inverse_perspective_projection(camera_to_clip);
    im_frame(im, ui.viewport_size, camera_to_world, camera_to_clip, clip_to_camera);

    push_perspective_projection(im, state.camera.camera_to_world, camera_to_clip, [ 0, 1, 1, 1 ] vec4);

    push_transform(im, mat4_identity);
    push_transform(im, state.camera.camera_to_world);

    if lang_debug and state.debug_is_active
        print(ui, 0, font, 0, ui.viewport_size.height - 20, "fps: %, debug: %", 1 / delta_seconds, state.debug_is_active);

    if use_render_system
    {
        frame(state.render ref, gl, window_size);

        // reset lights
        state.render.lighting = {} render_lighting_buffer;
        state.render.light_count = 0;

        // reset command buffer
        var buffer = state.render.buffer ref;
        buffer.counts = {} render_buffer_counts;

        var pass = push_pass(buffer);
        pass.framebuffer_handle = state.render.default_framebuffer.handle;
        pass.framebuffer_size   = window_size;
        pass.clear_depth = 1;
        pass.enable_clear_depth = true;
    }

    // needs to be defined by user: func game_update program_update_type { ... }
    game_update(platform, state, library_was_reloaded, state_byte_count);

    // rendering
    {
        glEnable(GL_DEPTH_TEST);
        glDisable(GL_BLEND);
        glFrontFace(GL_CCW);
        glEnable(GL_CULL_FACE);
        glCullFace(GL_BACK);
        glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);

        glViewport(0, 0, window.size.width, window.size.height);
        glScissor(0, 0, window.size.width, window.size.height);

        if state.letterbox_width_over_heigth is_not 0
        {
            //glClearColor(0.01, 0.01, 0.01, 1);
            glClearColor(0, 0, 0, 1);
            glClear(GL_COLOR_BUFFER_BIT);

            var size = get_size(letterbox);
            glEnable(GL_SCISSOR_TEST);
            glViewport(letterbox.min.x cast(s32), letterbox.min.y cast(s32), size.width cast(s32), size.height cast(s32));
            glScissor (letterbox.min.x cast(s32), letterbox.min.y cast(s32), size.width cast(s32), size.height cast(s32));
        }

        if lang_debug and state.debug_is_active
            glClearColor(0.3, 0.3, 1.0, 1);

        glClear(GL_COLOR_BUFFER_BIT bit_or GL_DEPTH_BUFFER_BIT);

        glEnable(GL_FRAMEBUFFER_SRGB);

        if use_render_system
        {
            var buffer = state.render.buffer ref;

            upload_buffers(state.render ref, gl, buffer, tmemory);

            execute(state.render ref, gl, buffer, camera_to_world, world_to_clip, clip_to_world);

            {
                bind_framebuffer(gl, 0);
                var size = get_size(letterbox);
                glViewport(letterbox.min.x cast(s32), letterbox.min.y cast(s32), size.width cast(s32), size.height cast(s32));
                glScissor (letterbox.min.x cast(s32), letterbox.min.y cast(s32), size.width cast(s32), size.height cast(s32));
            }
        }

        if state.debug_is_active
            im_present(im, gl);
        else
            im_skip_present(im);

        ui_present(gl, ui);

        gl_window_present(platform, gl, window);
    }

    timer_frame_end();

    // for hot code reloading
    if timing_enabled
        state.actual_timing_table = global_timing_table;

    return not platform.do_quit;
}

func save_game(platform platform_api ref, state program_state ref)
{
    var tmemory = state.temporary_memory ref;
    var used_byte_count = tmemory.used_byte_count;

    var window_placement = platform_window_get_placement(platform, state.window ref);
    platform_write_entire_file(platform, game_settings_path, value_to_u8_array(window_placement));

    tmemory.used_byte_count = used_byte_count;
}

func load_game(platform platform_api ref, state program_state ref) (window_placement platform_window_placement)
{
    var tmemory = state.temporary_memory ref;
    var used_byte_count = tmemory.used_byte_count;

    var window_placement platform_window_placement;
    window_placement.position.x  = -1;
    window_placement.position.y  = -1;
    window_placement.size.width  = 1280;
    window_placement.size.height =  720;
    var source = try_platform_read_entire_file(platform, tmemory, game_settings_path);
    if source.ok and (source.data.count is type_byte_count(platform_window_placement))
        window_placement = source.data.base cast(platform_window_placement ref) deref;

    tmemory.used_byte_count = used_byte_count;

    return window_placement;
}