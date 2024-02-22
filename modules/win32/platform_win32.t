module platform;

import win32;
import string;
import random;
import memory;
import meta;

struct platform_api
{
    expand base platform_api_base;

    expand win32 struct
    {
        instance       HINSTANCE;
        window_class_name cstring;
        time_ticks        u64;
        ticks_per_second  u64;

        // same as global, but helps with dll reloading
        console_output HANDLE;

        closed_windows HWND[32];
        closed_window_count u32;

        monitors      platform_win32_monitor[32];
        monitor_count u32;
    };
}

struct platform_win32_monitor
{
    handle HMONITOR;
    id     platform_monitor_id;
}

struct platform_window
{
    expand base platform_window_base;

    placement_backup WINDOWPLACEMENT;
    handle           HWND;
    device_context   HDC;
}

struct platform_library
{
    win32 HMODULE;
}

enum platform_key u8
{
    backspace = VK_BACK;
    enter     = VK_RETURN;
    escape    = VK_ESCAPE;
    tabulator = VK_TAB;
    delete    = VK_DELETE;

    shift   = VK_SHIFT;
    alt     = VK_MENU;
    control = VK_CONTROL;

    mouse_left   = VK_LBUTTON;
    mouse_middle = VK_MBUTTON;
    mouse_right  = VK_RBUTTON;

    page_down = VK_NEXT;
    page_up   = VK_PRIOR;

    home = VK_HOME;
    end  = VK_END;

    left  = VK_LEFT;
    right = VK_RIGHT;
    down  = VK_DOWN;
    up    = VK_UP;

    minus = VK_OEM_MINUS;
    plus  = VK_OEM_PLUS;

    f0  = VK_F1 - 1;
}

enum platform_special_character u32
{
    backspace = VK_BACK;
    enter     = VK_RETURN;
    escape    = VK_ESCAPE;
    tabulator = VK_TAB;
    delete    = VK_DELETE;

    page_down = VK_NEXT;
    page_up   = VK_PRIOR;

    home = VK_HOME;
    end  = VK_END;

    left  = VK_LEFT;
    right = VK_RIGHT;
    down  = VK_DOWN;
    up    = VK_UP;
}

var global platform_win32_console_output   HANDLE;
var global platform_win32_ticks_per_second u64;

var global platform_win32 platform_api ref;

func platform_init platform_init_type
{
    platform_win32 = platform;

    platform.instance = GetModuleHandleA(null) cast(HINSTANCE);
    platform.window_class_name = "My Window Class\0".base cast(cstring);

    var window_class WNDCLASSA;
    window_class.hInstance     = platform.instance;
    window_class.lpfnWndProc   = get_function_reference(platform_win32_window_callback WNDPROC);
    window_class.hbrBackground = COLOR_BACKGROUND cast(ssize) cast(HBRUSH);
    window_class.lpszClassName = platform.window_class_name;
    window_class.style         = CS_OWNDC;
    window_class.hCursor       = LoadCursorA(null, IDC_ARROW);
    platform_require(RegisterClassA(window_class ref));

    // load xinput if available
    {
        var xinput = platform_load_library(platform, "xinput1_4");

        if not xinput.win32
            xinput = platform_load_library(platform, "xinput1_3");

        if not xinput.win32
            xinput = platform_load_library(platform, "xinput9_1_0");

        if xinput.win32
        {
            XInputGetState        = platform_load_symbol(platform, xinput, "XInputGetState");
            XInputGetCapabilities = platform_load_symbol(platform, xinput, "XInputGetCapabilities");
        }

        platform_win32_check_gamepad_connections = true;
    }

    platform_require(QueryPerformanceFrequency(platform.ticks_per_second ref));
    platform_require(QueryPerformanceCounter(platform.time_ticks ref));

    {
        var info SYSTEM_INFO;
        GetSystemInfo(info ref);
        platform.logical_cpu_count = info.dwNumberOfProcessors;
    }

    {
        var working_directory string = platform.working_directory_buffer;

        var count = GetCurrentDirectoryA(0, null);
        platform_require(count, "GetCurrentDirectory(0, null) failed");
        assert(count <= working_directory.count);

        platform_require( GetCurrentDirectoryA(count, working_directory.base cast(cstring)) );
        working_directory.count = (count - 1) cast(usize); // has 0 terminal character at the end for win32 functions, but excluded from count

        loop var i u32; working_directory.count cast(u32)
        {
            if working_directory[i] is "\\"[0]
                working_directory[i] = "/"[0];
        }

        platform.working_directory = working_directory;
    }

    platform_win32_ticks_per_second = platform.ticks_per_second;
}

func platform_win32_monitor_enumerate_callback MONITORENUMPROC
{
    var platform = platform_win32;

    platform_require(platform.monitor_count < platform.monitors.count);

    var monitor = platform.monitors[platform.monitor_count] ref;
    platform.monitor_count += 1;

    var monitor_info_ex MONITORINFOEXA;
    monitor_info_ex.cbSize = type_byte_count(MONITORINFOEXA);
    GetMonitorInfoA(unnamedParam1, monitor_info_ex.base ref);

    monitor.handle = unnamedParam1;
    copy_bytes(monitor.id.win32_name.base, monitor_info_ex.szDevice.base, monitor.id.win32_name.count);

    return true;
}

struct platform_monitor_id
{
    win32_name u8[CCHDEVICENAME];
}

func platform_win32_get_monitor(platform platform_api ref, monitor_id platform_monitor_id, window platform_window ref) (monitor_handle HMONITOR)
{
    var monitor_handle HMONITOR;
    loop var i u32; platform.monitor_count
    {
        if platform.monitors[i].id.win32_name is monitor_id.win32_name
        {
            monitor_handle = platform.monitors[i].handle;
            break;
        }
    }

    if not monitor_handle
        monitor_handle = MonitorFromWindow(window.handle, MONITOR_DEFAULTTOPRIMARY);

    return monitor_handle;
}

func platform_window_init platform_window_init_type
{
    assert(not window.handle);

    var window_style = WS_OVERLAPPEDWINDOW;

    var client_rect RECT;

    if not platform.monitor_count
        platform_require(EnumDisplayMonitors(null, null, get_function_reference(platform_win32_monitor_enumerate_callback MONITORENUMPROC), 0));

    if x is_not -1
        client_rect.left = x;

    var monitor_handle = platform_win32_get_monitor(platform, monitor_id, window);

    var monitor_info MONITORINFO;
    monitor_info.cbSize = type_byte_count(MONITORINFO);
    platform_require(GetMonitorInfoA(monitor_handle, monitor_info ref));

    if y is_not -1
        client_rect.top = monitor_info.rcMonitor.bottom - height - y;

    client_rect.right  = client_rect.left + width;
    client_rect.bottom = client_rect.top  + height;
    AdjustWindowRect(client_rect ref, window_style, 0);

    if x is -1
        x = CW_USEDEFAULT;
    else
        x = client_rect.left;

    if y is -1
        y = CW_USEDEFAULT;
    else
        y = client_rect.top;

    var buffer u8[512];
    window.handle = CreateWindowExA(0, platform.window_class_name, as_cstring(buffer, title), window_style, x, y, client_rect.right - client_rect.left, client_rect.bottom - client_rect.top, null, null, platform.instance, null);
    platform_require(window.handle is_not INVALID_HANDLE_VALUE);

    ShowWindow(window.handle, SW_SHOW);

    // so we can reference the platform in the window callback
    // a global variable might be better
    //window->win32.platform = platform;

    // handling this error is just a mess, not gonna do it!
    //SetWindowLongPtrA(window->win32.handle, GWLP_USERDATA, (u64) window);

    window.is_fullscreen = false;
    window.is_resizeable = true;

    window.device_context = GetDC(window.handle);
    platform_require(window.device_context is_not null);

    // try set window icon
    {
        var icon = LoadIconA(platform.instance, as_cstring(buffer, "icon.ico"));
        if icon
            SetClassLongPtrA(window.handle, GCLP_HICON, icon);
    }
}

func platform_window_init platform_window_init_type2
{
    platform_window_init(platform, window, title, placement.size.width, placement.size.height, placement.position.x, placement.position.y, placement.monitor_id);
}

struct platform_window_placement
{
    position   vec2s;
    size       vec2s;
    monitor_id platform_monitor_id;
}

func platform_window_get_placement platform_window_get_placement_type
{
    var placement platform_window_placement;

    var monitor_info MONITORINFO;
    monitor_info.cbSize = type_byte_count(MONITORINFO);
    var monitor_handle = MonitorFromWindow(window.handle, MONITOR_DEFAULTTOPRIMARY);
    platform_require(monitor_handle);
    platform_require(GetMonitorInfoA(monitor_handle, monitor_info ref));

    loop var i u32; platform.monitor_count
    {
        if platform.monitors[i].handle is monitor_handle
        {
            placement.monitor_id = platform.monitors[i].id;
            break;
        }
    }

    var client_rectangle RECT;
    GetClientRect(window.handle, client_rectangle ref);
    var min POINT;
    min.x = client_rectangle.left;
    min.y = client_rectangle.bottom;
    ClientToScreen(window.handle, min ref);

    var width  = client_rectangle.right - client_rectangle.left;
    var height = client_rectangle.bottom - client_rectangle.top;

    placement.position.x  = min.x;
    placement.position.y  = monitor_info.rcMonitor.bottom - min.y;
    placement.size.width  = width;
    placement.size.height = height;

    return placement;
}

func platform_window_set_placement platform_window_set_placement_type
{
    var monitor_info MONITORINFO;
    monitor_info.cbSize = type_byte_count(MONITORINFO);

    var monitor_handle = platform_win32_get_monitor(platform, placement.monitor_id, window);
    platform_require(GetMonitorInfoA(monitor_handle, monitor_info ref));

    var client_rectangle RECT;
    GetClientRect(window.handle, client_rectangle ref);

    var window_rectangle RECT;
    GetWindowRect(window.handle, window_rectangle ref);

    var min POINT;
    min.x = client_rectangle.left;
    min.y = client_rectangle.bottom;
    ClientToScreen(window.handle, min ref);

    SetWindowPos(window.handle, null, placement.position.x + (min.x - window_rectangle.left), monitor_info.rcMonitor.bottom - placement.position.y - (min.y - window_rectangle.bottom), placement.size.width, placement.size.height, SWP_SHOWWINDOW);
}

func platform_window_frame platform_window_frame_type
{
    // was closed

    // TODO make this thread safe, since window callback can change it
    loop var i u32; platform.closed_window_count
    {
        // we have to manually remove them, assuming all active windows are eventually being called
        if platform.closed_windows[i] is window.handle
        {
            platform.closed_window_count -= 1;
            platform.closed_windows[i] = platform.closed_windows[platform.closed_window_count];
            window.do_close = true;
            break;
        }
    }

    var rect RECT;
    platform_require(GetClientRect(window.handle, rect ref));

    window.size.width  = rect.right - rect.left;
    window.size.height = rect.bottom - rect.top;

    var cursor POINT;
    GetCursorPos(cursor ref);

    ScreenToClient(window.handle, cursor ref);

    window.previous_mouse_position = window.mouse_position;

    window.mouse_position.x = cursor.x;
    window.mouse_position.y = window.size.height - 1 - cursor.y;
}

func platform_window_set_fullscreen platform_window_set_fullscreen_type
{
    if window.is_fullscreen is_not enable_fullscreen
    {
        var style = GetWindowLongA(window.handle, GWL_STYLE);
        if style bit_and WS_OVERLAPPEDWINDOW
        {
            assert(not window.is_fullscreen);

            var monitor_info MONITORINFO;
            monitor_info.cbSize = type_byte_count(MONITORINFO);
            platform_require(GetWindowPlacement(window.handle, window.placement_backup ref) and GetMonitorInfoA(MonitorFromWindow(window.handle, MONITOR_DEFAULTTOPRIMARY), monitor_info ref));
            window.size.width  = monitor_info.rcMonitor.right - monitor_info.rcMonitor.left;
            window.size.height = monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top;

            SetWindowLongA(window.handle, GWL_STYLE, style bit_and bit_not WS_OVERLAPPEDWINDOW);
            SetWindowPos(window.handle, HWND_TOP,
                            monitor_info.rcMonitor.left, monitor_info.rcMonitor.top,
                            monitor_info.rcMonitor.right - monitor_info.rcMonitor.left,
                            monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top, SWP_NOOWNERZORDER bit_or SWP_FRAMECHANGED);

            window.is_fullscreen = true;
        }
        else
        {
            assert(window.is_fullscreen);

            style bit_or= WS_OVERLAPPEDWINDOW;

            if not window.is_resizeable
                style bit_and= bit_not WS_THICKFRAME;

            SetWindowLongA(window.handle, GWL_STYLE, style);
            SetWindowPlacement(window.handle, window.placement_backup ref);
            SetWindowPos(window.handle, null, 0, 0, 0, 0, SWP_NOMOVE bit_or SWP_NOSIZE bit_or SWP_NOZORDER bit_or SWP_NOOWNERZORDER bit_or SWP_FRAMECHANGED);

            window.is_fullscreen = false;
        }
    }
}

func platform_handle_messages platform_handle_messages_type
{
    // previous do_quit was not overridden
    if platform.do_quit
        return false;

    platform.do_quit = false;

    loop var key_index; platform.keys.count
    {
        platform.keys[key_index].half_transition_count = 0;
        platform.keys[key_index].was_repeated          = false;
    }

    var with_shift   b8 = GetKeyState(VK_SHIFT)   bit_shift_right 7;
    var with_control b8 = GetKeyState(VK_CONTROL) bit_shift_right 7;
    var with_alt     b8 = GetKeyState(VK_MENU)    bit_shift_right 7;

    platform_button_poll(platform.keys[platform_key.alt] ref,     with_alt);
    platform_button_poll(platform.keys[platform_key.shift] ref,   with_shift);
    platform_button_poll(platform.keys[platform_key.control] ref, with_control);

    platform.character_count = 0;
    platform.total_character_count = 0;
    platform.mouse_wheel_delta = 0;

    // we can't do this, since the window call back may be called at any time
    // platform_win32_closed_window_count = 0;

    var msg MSG;
    while PeekMessageA(msg ref, null, 0, 0, PM_REMOVE)
    {
        switch msg.message
        case WM_QUIT
        {
            platform.do_quit = true;
        }
        case WM_CHAR, WM_UNICHAR
        {
            platform_win23_push_char(platform, msg.wParam cast(u32), true, false, false, false);
        }
        case WM_KEYDOWN
        {
            if msg.wParam is VK_CONTROL
                with_control = true;
            else if msg.wParam is VK_SHIFT
                with_shift = true;
            else
                platform_win23_push_char(platform, msg.wParam cast(u32), false, with_shift, with_control, with_alt);

            if (msg.lParam bit_and 0x40000000) is 0
                platform_button_update(platform.keys[msg.wParam] ref, true);
            else
                platform.keys[msg.wParam].was_repeated = true;
        }
        case WM_SYSKEYDOWN
        {
            if msg.wParam is VK_CONTROL
                with_control = true;
            else if msg.wParam is VK_SHIFT
                with_shift = true;
            else
                platform_win23_push_char(platform, msg.wParam cast(u32), false, with_shift, with_control, true);

            if (msg.lParam bit_and 0x40000000) is 0
                platform_button_update(platform.keys[msg.wParam] ref, true);
            else
                platform.keys[msg.wParam].was_repeated = true;
        }
        case WM_KEYUP
        {
            if msg.wParam is VK_CONTROL
                with_control = false;

            if msg.wParam is VK_SHIFT
                with_shift = false;

            platform_button_update(platform.keys[msg.wParam] ref, false);
        }
        case WM_SYSKEYUP
        {
            platform_button_update(platform.keys[msg.wParam] ref, false);
        }
        case WM_MOUSEWHEEL
        {
            platform.mouse_wheel_delta += (msg.wParam bit_shift_right 16) cast(s16) / 120.0;
        }

        TranslateMessage(msg ref);
        DispatchMessageA(msg ref);
    }

    // poll after handling messages, so we get the latest state
    platform_button_poll(platform.keys[VK_LBUTTON] ref, GetKeyState(VK_LBUTTON) bit_and 0x8000);
    platform_button_poll(platform.keys[VK_MBUTTON] ref, GetKeyState(VK_MBUTTON) bit_and 0x8000);
    platform_button_poll(platform.keys[VK_RBUTTON] ref, GetKeyState(VK_RBUTTON) bit_and 0x8000);

    // poll gamepads
    {
        // this is expensive, so we use a flag
        if platform_win32_check_gamepad_connections
        {
            platform_win32_check_gamepad_connections = false;

            loop var i u32; XUSER_MAX_COUNT
            {
                var capabilites XINPUT_CAPABILITIES;
                platform.gamepads[i].is_connected = XInputGetCapabilities(i, XINPUT_FLAG_GAMEPAD, capabilites ref) is ERROR_SUCCESS;
            }
        }

        loop var i u32; XUSER_MAX_COUNT
        {
            if not platform.gamepads[i].is_connected
                continue;

            var state XINPUT_STATE;
            var result = XInputGetState(i, state ref);

            var gamepad = platform.gamepads[i] ref;

            if result is_not ERROR_SUCCESS
            {
                gamepad.is_connected = false;
                continue;
            }

            gamepad.left_stick  = get_xinput_stick_direction(state.Gamepad.sThumbLX, state.Gamepad.sThumbLY,  XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE);
            gamepad.right_stick = get_xinput_stick_direction(state.Gamepad.sThumbRX, state.Gamepad.sThumbRY,  XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE);

            gamepad.left_trigger  = get_xinput_trigger_value(state.Gamepad.bLeftTrigger);
            gamepad.right_trigger = get_xinput_trigger_value(state.Gamepad.bRightTrigger);

            platform_button_poll(gamepad.left_stick_as_button ref, (gamepad.left_stick.x is_not 0) or (gamepad.left_stick.y is_not 0));
            platform_button_poll(gamepad.right_stick_as_button ref, (gamepad.right_stick.x is_not 0) or (gamepad.right_stick.y is_not 0));
            platform_button_poll(gamepad.left_trigger_as_button ref, gamepad.left_trigger is_not 0);
            platform_button_poll(gamepad.right_trigger_as_button ref, gamepad.right_trigger is_not 0);

            platform_button_poll(gamepad.direction.up ref,    state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_DPAD_UP);
            platform_button_poll(gamepad.direction.down ref,  state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_DPAD_DOWN);
            platform_button_poll(gamepad.direction.right ref, state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_DPAD_RIGHT);
            platform_button_poll(gamepad.direction.left ref,  state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_DPAD_LEFT);

            platform_button_poll(gamepad.face.down ref,  state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_A);
            platform_button_poll(gamepad.face.right ref, state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_B);
            platform_button_poll(gamepad.face.left ref,  state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_X);
            platform_button_poll(gamepad.face.up ref,    state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_Y);

            platform_button_poll(gamepad.left_shoulder ref,  state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_LEFT_SHOULDER);
            platform_button_poll(gamepad.right_shoulder ref, state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_RIGHT_SHOULDER);

            platform_button_poll(gamepad.left_thumb ref,  state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_LEFT_THUMB);
            platform_button_poll(gamepad.right_thumb ref, state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_RIGHT_THUMB);

            platform_button_poll(gamepad.select ref, state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_BACK);
            platform_button_poll(gamepad.start ref,  state.Gamepad.wButtons bit_and XINPUT_GAMEPAD_START);
        }
    }

    platform_update_time(platform);

    return true;
}

func platform_update_time platform_update_time_type
{
    var time_ticks u64;
    platform_require(QueryPerformanceCounter(time_ticks ref));

    platform.delta_seconds = (time_ticks - platform.time_ticks) cast(f32) / platform.ticks_per_second cast(f32);
    platform.time_ticks = time_ticks;
}

func platform_wait_for_input platform_wait_for_input_type
{
    assert(wait_for_keyboard or wait_for_mouse);

    if timeout_milliseconds is -1 cast(u32)
        timeout_milliseconds = INFINITE;

    var wait_mask u32;

    if wait_for_keyboard
        wait_mask bit_or= QS_KEY;

    if wait_for_mouse
        wait_mask bit_or= QS_MOUSE;

    var wait_for_all s32 = 0;
    platform_require(MsgWaitForMultipleObjects(0, null, 0, timeout_milliseconds, wait_mask) is_not WAIT_FAILED);
}

func platform_win32_window_callback WNDPROC
{
multiline_comment  {
        case WM_DESTROY
        {
            PostQuitMessage(0);
            return 0;
        }
    }

    switch msg
    // don't destroy the window, since we typically want to react to that request
    // prevents WM_DESTROY to be called
    case WM_CLOSE
    {
        assert(platform_win32.closed_window_count < platform_win32.closed_windows.count);
        platform_win32.closed_windows[platform_win32.closed_window_count] = window;
        platform_win32.closed_window_count += 1;

        return 0;
    }

    // disable beep when pressing alt + ...
    // since we have no menu shortcuts
    case WM_MENUCHAR
    {
        return MNC_CLOSE bit_shift_left 16;
    }

    // improves XInputGetState performance
    // XInputGetState is slow if device is not connected
    case WM_DEVICECHANGE
    {
        platform_win32_check_gamepad_connections = true;
    }

    return DefWindowProcA(window, msg, w_param, l_param);
}

func platform_win23_push_char(platform platform_api ref, code u32, is_character b8, with_shift b8, with_control b8, with_alt b8)
{
    // filter special "characters"
    if is_character and (code < 32)
        return;

    // filter ctrl+backspace wich generates a character, thanks ...
    if is_character and (code is 127)
        return;

    if platform.character_count < platform.character_buffer.count
    {
        var character = platform.character_buffer[platform.character_count] ref;
        platform.character_count += 1;

        character.code = code;
        character.is_character = is_character;
        character.with_shift   = with_shift;
        character.with_control = with_control;
        character.with_alt     = with_alt;
    }

    platform.total_character_count += 1;
}

func platform_format_fatal_message(builder string_builder ref, label string, location lang_code_location, condition_text string, format string, arguments lang_typed_value[]) (byte_count usize, ctext cstring, clabel cstring)
{
    var byte_count = write(builder, "%:\n\n%/%\n%(%,%):\n\n", label, location.module, location.function, location.file, location.line, location.column).count;

    byte_count += write(builder, "    Condition '%' is false\n\n", condition_text).count;

    if format.count
    {
        byte_count += write(builder, "    ").count;
        byte_count += write(builder, format, arguments).count;
        byte_count += write(builder, "\n\n").count;
    }

    byte_count += write(builder, "\0").count;

    if builder.capacity
    {
        var ctext = builder.text.base cast(cstring);
        var label_text = write(builder, "%\0", label);
        byte_count += label_text.count;
        var clabel = as_cstring(label_text);

        return byte_count, ctext, clabel;
    }
    else
    {
        byte_count += write(builder, "%\0", label).count;
        return byte_count, null, null;
    }
}

func platform_fatal_error_message platform_fatal_error_message_type
{
    var builder string_builder;
    builder.capacity  = platform_format_fatal_message(builder ref, label, location, condition_text, format, arguments).byte_count;
    builder.text.base = platform_memory_reserve(builder.capacity);
    platform_memory_commit(builder.text.base, builder.capacity);

    var message = platform_format_fatal_message(builder ref, label, location, condition_text, format, arguments);
    var result = MessageBoxExA(null, message.ctext, message.clabel, MB_CANCELTRYCONTINUE bit_or MB_ICONEXCLAMATION, 0);

    print("% %/%(%,%): %\n", label, location.file, location.function, location.line, location.column, condition_text);
    print(format, arguments);
    print("\n");

    switch result
    case IDTRYAGAIN
    {
        if IsDebuggerPresent()
            __debugbreak();

        platform_memory_free(builder.text.base);
    }
    case IDCANCEL
    {
        platform_memory_free(builder.text.base);
        ExitProcess(-1 cast(u32));
    }
    else
    {
        platform_memory_free(builder.text.base);
    }
}

func platform_require assert_type
{
    if not condition
    {
        var builder string_builder;
        builder.capacity  = 4096;
        builder.text.base = platform_memory_reserve(builder.capacity);
        platform_memory_commit(builder.text.base, builder.capacity);

        var new_format = write(builder ref, "%\n    GetLastError() = 0x%\n", format, format_hex(GetLastError(), 8));
        platform_fatal_error_message("Platform Win32 Requirement Failed", location, condition_text, new_format, arguments);

        platform_memory_free(builder.text.base);
    }
}

func platform_debug_break platform_debug_break_type
{
    __debugbreak();
}

func platform_exit platform_exit_type
{
    ExitProcess(code cast(u32));
}

func platform_get_random_from_time platform_get_random_from_time_type
{
    var filetime FILETIME;
    GetSystemTimeAsFileTime(filetime ref);
    var random random_pcg = filetime ref cast(random_pcg ref) deref;

    return random;
}

func platform_local_timestamp_milliseconds platform_local_timestamp_milliseconds_type
{
    var filetime FILETIME;
    GetSystemTimeAsFileTime(filetime ref);

    // FILETIME is a multiple of 100 nanosecconds
    // 1ms = 1.000.000ns
    var milliseconds = (filetime ref cast(u64 ref) deref) / 10000;

    return milliseconds;
}

func platform_local_date_and_time platform_local_date_and_time_type
{
    var time SYSTEMTIME;
    GetLocalTime(time ref);

    var date_and_time platform_date_and_time;
    date_and_time.year         = time.wYear;
    date_and_time.month        = time.wMonth        cast(u8);
    date_and_time.week_day     = time.wDayOfWeek    cast(u8);
    date_and_time.day          = time.wDay          cast(u8);
    date_and_time.hour         = time.wHour         cast(u8);
    date_and_time.minute       = time.wMinute       cast(u8);
    date_and_time.second       = time.wSecond       cast(u8);
    date_and_time.milli_second = time.wMilliseconds;
    return date_and_time;
}

func as_cstring(buffer u8[], text string) (ctext cstring)
{
    write(buffer, "%\0", text);
    return buffer.base cast(cstring);
}

func cstring_count(text cstring) (count usize)
{
    assert(text);
    var count usize;
    while (text + count) deref
        count += 1;

    return count;
}

func as_string(text cstring) (result string)
{
    return { cstring_count(text), text cast(u8 ref) } string;
}

func platform_get_file_info platform_get_file_info_type
{
    var buffer u8[512];

    var data WIN32_FILE_ATTRIBUTE_DATA;
    var ok = GetFileAttributesExA(as_cstring(buffer, path), GetFileExInfoStandard, data ref);
    if not ok
        return {} platform_file_info;

    // we can't just cast to u64, because ms messed up order of high and low values
    var byte_count      = (data.nFileSizeHigh cast(u64) bit_shift_right 32) bit_or (data.nFileSizeLow cast(u64));
    var write_timestamp = (data.ftLastWriteTime.dwHighDateTime cast(u64) bit_shift_right 32) bit_or (data.ftLastWriteTime.dwLowDateTime cast(u64));

    return { byte_count, write_timestamp, true } platform_file_info;
}

func platform_read_entire_file platform_read_entire_file_type
{
    var buffer u8[512];

    var file_handle = CreateFileA(as_cstring(buffer, path), GENERIC_READ, FILE_SHARE_READ, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);

    // might be written to, or does not exist
    if file_handle is INVALID_HANDLE_VALUE
        return {} u8[];

    var file_info = platform_get_file_info(platform, path);
    if not file_info.ok or (file_info.byte_count > data.count)
        return {} u8[];

    if data.count > file_info.byte_count
        data.count = file_info.byte_count;

    // we can only read in ~4gb chunks
    var offset usize = 0;
    while offset < data.count
    {
        var byte_count u32;

        var count = data.count - offset;
        if count > 0xFFFFFFFF
            byte_count = 0xFFFFFFFF;
        else
            byte_count = count cast(u32);

        var read_byte_count u32;
        var ok b8 = ReadFile(file_handle, data.base + offset, byte_count, read_byte_count ref, null);
        ok = ok and (byte_count is read_byte_count);
        if not ok
            return {} u8[];

        offset = offset + byte_count;
    }

    CloseHandle(file_handle);

    return data;
}

func platform_write_entire_file platform_write_entire_file_type
{
    var buffer u8[512];

    var file_handle = CreateFileA(as_cstring(buffer, path), GENERIC_WRITE, 0, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, null);
    if file_handle is INVALID_HANDLE_VALUE
        return false;

    while data.count
    {
        var byte_count u32;
        // has higher bits set
        if data.count > 0xFFFFFFFF
            byte_count = 0xFFFFFFFF;
        else
            byte_count = data.count cast(u32);

        var write_byte_count u32;
        var ok = WriteFile(file_handle, data.base, byte_count, write_byte_count ref, null) cast(b8);
        ok = ok and (byte_count is write_byte_count);
        if not ok
            return false;

        data.base  = data.base  + byte_count;
        data.count = data.count - byte_count;
    }

    CloseHandle(file_handle);

    return true;
}

func platform_copy_file platform_copy_file_type
{
    var to_buffer u8[512];
    var from_buffer u8[512];

    var ok = CopyFileA(as_cstring(from_buffer, from_path), as_cstring(to_buffer, to_path), (not override) cast(s32));
    return ok;


    //if ok
    //return true;

    //var error = GetLastError();
    //require(error is ERROR_ACCESS_DENIED, "Failed to copy % to %, GetLastError() = %", from_path, to_path, error);
    //return false;
}

func platform_create_directory platform_create_directory_type
{
    var buffer u8[512];
    var ok = CreateDirectoryA(as_cstring(buffer, path), null) cast(b8);
    var is_new = true;
    if not ok
    {
        ok = GetLastError() is ERROR_ALREADY_EXISTS;
        is_new = false;
    }
    platform_require(ok);

    return is_new;
}

struct platform_file_search_iterator
{
    expand base platform_file_search_iterator_base;

    expand win32 struct
    {
        find_data WIN32_FIND_DATAA;
        handle    HANDLE;
    };
}

func platform_file_search_init platform_file_search_init_type
{
    var relative_path_prefix string;
    relative_path_prefix.base = relative_path_pattern.base;
    loop var i u32; relative_path_pattern.count
    {
        if relative_path_pattern[i] is "/"[0]
            relative_path_prefix.count = i + 1;

        // COMPILER BUG: quotes in expression text is not escaped
        def slash = "\\"[0];
        assert(relative_path_pattern[i] is_not slash);
    }

    var name = { relative_path_pattern.count - relative_path_prefix.count, relative_path_prefix.base + relative_path_prefix.count } string;

    var pattern cstring;
    var pattern_buffer u8[platform_max_path_count];
    if name.count
        pattern = write(pattern_buffer, "%*%\0", relative_path_prefix, name).base cast(cstring);
    else
        pattern = write(pattern_buffer, "%*\0", relative_path_prefix).base cast(cstring);

    var iterator platform_file_search_iterator;
    iterator.relative_path_prefix = relative_path_prefix;

    iterator.win32.handle = FindFirstFileA(pattern, iterator.win32.find_data ref);
    if (iterator.win32.handle is INVALID_HANDLE_VALUE)
        iterator.win32.handle = null;

    return iterator;
}

func platform_file_search_next platform_file_search_next_type
{
    if not iterator.win32.handle
        return false;

    iterator.found_file.is_directory = (iterator.win32.find_data.dwFileAttributes bit_and FILE_ATTRIBUTE_DIRECTORY);

    if (iterator.win32.find_data.cFileName[0] is "."[0]) and (iterator.win32.find_data.cFileName[1] is 0)
    {
        // copy, since we will free it
        iterator.found_file.relative_path = write(iterator.found_file.relative_path_buffer, "%", iterator.relative_path_prefix);

        // remove trailing '/' if any
        if iterator.found_file.relative_path.count
            iterator.found_file.relative_path.count -= 1;
    }
    else
    {
        var file_name = as_string(iterator.win32.find_data.cFileName.base cast(cstring));

        iterator.found_file.relative_path = write(iterator.found_file.relative_path_buffer, "%%", iterator.relative_path_prefix, file_name);

        loop var i u32; iterator.found_file.relative_path.count
        {
            if iterator.found_file.relative_path[i] is "\\"[0]
                iterator.found_file.relative_path[i] = "/"[0];
        }
    }

    iterator.found_file.absolute_path = get_absolute_path(iterator.found_file.absolute_path_buffer, platform.working_directory, iterator.found_file.relative_path);

    if not FindNextFileA(iterator.win32.handle, iterator.win32.find_data ref)
        iterator.win32.handle = null;

    return true;
}

func platform_load_library platform_load_library_type
{
    var buffer u8[512];

    var library platform_library;
    library.win32 = LoadLibraryA(as_cstring(buffer, name));

    return library;
}

func platform_free_library platform_free_library_type
{
    platform_require(FreeLibrary(library.win32));
}

func platform_load_symbol platform_load_symbol_type
{
    var buffer u8[512];

    var result = GetProcAddress(library.win32, as_cstring(buffer, name));
    platform_require(result);

    return result;
}

func platform_enable_console platform_enable_console_type
{
    if platform
        platform_win32_console_output = platform.console_output;

    if platform_win32_console_output
        return;

    // use debugger output instead of a console
    if IsDebuggerPresent()
    {
        platform_win32_console_output = GetStdHandle(STD_OUTPUT_HANDLE);
        platform_require(platform_win32_console_output is_not INVALID_HANDLE_VALUE);
    }
    else
    {
        // try attach to console first, otherwise allocate one
        if not AttachConsole(ATTACH_PARENT_PROCESS)
        {
            var error = GetLastError();
            if error
                platform_require(AllocConsole());
        }

        platform_win32_console_output = GetStdHandle(STD_OUTPUT_HANDLE);
        platform_require(platform_win32_console_output is_not INVALID_HANDLE_VALUE);

        // fix for win 7 in visual studio command prompt
        var ignored u32;
        if not GetConsoleMode(platform_win32_console_output, ignored ref)
        {
            platform_require(FreeConsole());
            platform_require(AllocConsole());

            platform_win32_console_output = GetStdHandle(STD_OUTPUT_HANDLE);
            platform_require(platform_win32_console_output is_not INVALID_HANDLE_VALUE);
        }
    }

    if platform
        platform.console_output = platform_win32_console_output;
}

func platform_print platform_print_type
{
    if platform_win32_console_output
    {
        var written_count u32;
        // while debugging WriteConsoleA does not work for debug output so we use WriteFile instead
        platform_require(WriteFile(platform_win32_console_output, text.base, text.count cast(u32), written_count ref, null));
        assert(text.count is written_count);
    }
}

func platform_memory_reserve platform_memory_reserve_type
{
    var base = VirtualAlloc(null, byte_count, MEM_RESERVE, PAGE_NOACCESS);
    platform_require(base, location, "out of memory");
    return base;
}

func platform_memory_commit platform_memory_commit_type
{
    platform_require(VirtualAlloc(base, byte_count, MEM_COMMIT, PAGE_READWRITE), location);
}

func platform_memory_free platform_memory_free_type
{
    platform_require(VirtualFree(base, 0, MEM_RELEASE), location);
}

func platform_sleep_milliseconds platform_sleep_milliseconds_type
{
    Sleep(milliseconds);
}

func platform_realtime_counter platform_realtime_counter_type
{
    var time_ticks u64;
    platform_require(QueryPerformanceCounter(time_ticks ref));
    return time_ticks;
}

func platform_elapsed_milliseconds platform_elapsed_milliseconds_type
{
    var elapsed_milliseconds = elapsed_realtime_counter * 1000 / platform_win32_ticks_per_second;
    return elapsed_milliseconds;
}

func platform_cpu_cycle_counter platform_cpu_cycle_counter_type
{
    return __rdtsc();
}

func platform_highest_bit_index platform_highest_bit_index_type
{
    // one day we can use _BitScanReverse, but for now we can't since
    // unsinged long is not the same as unsigned int, even though they actually are!!!!!

    var index u32;
    while mask
    {
        index += 1;
        mask bit_shift_right= 1;
    }

    multiline_comment
    {
    if not _BitScanReverse(index ref, mask)
        index = 0;
    }

    return index;
}

func platform_get_executable_name platform_get_executable_name_type
{
    var file_path u8[512];
    var count = GetModuleFileNameA(null, file_path.base cast(cstring), file_path.count cast(s32)) cast(usize);
    var error = GetLastError();
    require(error is ERROR_SUCCESS, "GetModuleFileNameA failed, GetLastError() = %", error);

    var name = { count, file_path.base } string;
    loop var i usize; count
    {
        if file_path[i] is "\\"[0]
            file_path[i] = "/"[0];

        if file_path[i] is "/"[0]
            name = { count - 1 - i, file_path[i + 1] ref } string;
    }

    loop var i usize; name.count
    {
        if name[name.count - 1 - i] is "."[0]
        {
            name.count = name.count - 1 - i;
            break;
        }
    }

    require(buffer.count >= name.count, "buffer for executable name is to small, name count is %", name.count);
    copy_array({ name.count, buffer.base } string, name);
    name.base = buffer.base;

    return name;
}

struct platform_thread
{
    handle     HANDLE;
    is_running b8;
}

func platform_thread_init platform_thread_init_type
{
    assert(not thread.handle);
    thread.handle = CreateThread(null, 0, function cast(u8 ref) cast(THREAD_START_ROUTINE), data, CREATE_SUSPENDED, null);
    platform_require("CreateThread(null, 0, function, null, CREATE_SUSPENDED, null)", thread.handle);
}

func platform_thread_start platform_thread_start_type
{
    assert(thread.handle and not thread.is_running);
    platform_require(ResumeThread(thread.handle));
    thread.is_running = true;
}

func platform_thread_wait platform_thread_wait_type
{
    assert(thread.handle and thread.is_running);
    platform_require(WaitForSingleObject(thread.handle, INFINITE) is WAIT_OBJECT_0);
    platform_require(CloseHandle(thread.handle));

    thread deref = {} platform_thread;
}

func platform_locked_increment platform_locked_increment_type
{
    return _InterlockedIncrement64(value);
}

func platform_locked_decrement platform_locked_decrement_type
{
    return _InterlockedDecrement64(value);
}

// avoids expensive polling of unconnected controllers
var global platform_win32_check_gamepad_connections b8;

var global XInputGetState        = get_function_reference(DummyXInputGetState        XInputGetState_type);
var global XInputGetCapabilities = get_function_reference(DummyXInputGetCapabilities XInputGetCapabilities_type);

func DummyXInputGetState XInputGetState_type
{
    return 0;
}

func DummyXInputGetCapabilities XInputGetCapabilities_type
{
    return 0;
}

func get_xinput_stick_direction(stick_x s16, stick_y s16, threshold s16) (direction vec2)
{
    var direction vec2;
    direction.x = get_xinput_stick_axis(stick_x, threshold);
    direction.y = get_xinput_stick_axis(stick_y, threshold);

    return direction;
}

func get_xinput_stick_axis(raw_value s32, threshold s16) (value f32)
{
    var value f32;

    if raw_value > 0
    {
        if raw_value < threshold
            raw_value = 0;

        value = raw_value / 32768.0;
    }
    else
    {
        if raw_value > -threshold
            raw_value = 0;

        value = raw_value / 32767.0;
    }

    return value;
}

func get_xinput_trigger_value(raw_value u8) (value f32)
{
    if raw_value < XINPUT_GAMEPAD_TRIGGER_THRESHOLD
        raw_value = 0;

    var value = raw_value / 255.0;
    return value;
}