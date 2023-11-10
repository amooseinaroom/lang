    
#pragma once

#include <windows.h>
#include "utf8_string.h"

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

#define platform_require_location(condition, location, ...) \
        platform_conditional_fatal_error_location(condition, location, "Error", "Requirement:\n    " # condition "\nfailed.\n\nGetLastError(): 0x%08x" __VA_ARGS__, GetLastError())

struct platform_window
{
    struct
    {
        HWND handle;
        HDC  device_context;
    } win32;
};

// not really inheritance, but c++ is a pain
struct platform_api : platform_api_base
{
    struct
    {
        HINSTANCE instance;
    } win32;
};

struct platform_file_search_iterator : platform_file_search_iterator_base
{
    struct
    {
    
        WIN32_FIND_DATAA find_data;
        HANDLE           handle;
    } win32;
};

const cstring platform_win32_window_class_name = "my window class";

LRESULT platform_win32_window_callback(HWND window_handle, UINT message, WPARAM w_param, LPARAM l_param)
{
    switch (message)
    {
        case WM_DESTROY:
        {
            PostQuitMessage(0);
        } break;
        
        // disable beep when pressing alt + ...
        // since we have no menu shortcuts
        case WM_MENUCHAR:
        {
            return MNC_CLOSE << 16;
        } break;
    }
    
    return DefWindowProcA(window_handle, message, w_param, l_param);
}

platform_init_declaration
{
    *platform = {};
    auto win32 = &platform->win32;
    win32->instance = (HINSTANCE) GetModuleHandleA(null);
    
    WNDCLASSA window_class = {};
    window_class.lpszClassName = platform_win32_window_class_name;
    window_class.hInstance     = win32->instance;
    window_class.lpfnWndProc   = platform_win32_window_callback;
    window_class.hbrBackground = (HBRUSH) (COLOR_BACKGROUND);
    window_class.hCursor       = LoadCursor(null, IDC_ARROW);
    
    platform_require( RegisterClassA(&window_class) );
    
    LARGE_INTEGER ticks;
    platform_require( QueryPerformanceFrequency(&ticks) );
    platform->ticks_per_second = ticks.QuadPart;
    
    platform->last_time_ticks = platform_get_realtime_ticks(platform);
}

platform_get_working_directory_declaration
{
    string working_directory;
    working_directory.count = GetCurrentDirectoryA(0, null);
    platform_require(working_directory.count, "GetCurrentDirectory(0, null) failed");
    
    working_directory = allocate_array(memory, u8, working_directory.count + 1);
    platform_require( GetCurrentDirectoryA(working_directory.count, (char *) working_directory.base) );
    working_directory.count--; // has 0 terminal character at the end for win32 functions, but excluded from count
    
    for (u32 i = 0; i < working_directory.count; i++)
    {
        if (working_directory.base[i] == '\\')
            working_directory.base[i] = '/';
    }
    
    return working_directory;
}

void platform_win23_push_char(platform_api *platform, u32 code, bool is_character, bool shift_is_active, bool control_is_active, bool alt_is_active)
{
    // filter special "characters"
    if (is_character && (code < 32))
        return;
    
    // filter ctrl+backspace wich generates a character, thanks ...
    if (is_character && (code == 127))
        return;
    
    if (platform->character_count < carray_count(platform->characters))
    {
        auto character = &platform->characters[platform->character_count++];
        
        character->code = code;
        character->is_character = is_character;
        character->shift_is_active   = shift_is_active;
        character->control_is_active = control_is_active;
        character->alt_is_active     = alt_is_active;
    }
}

platform_get_realtime_ticks_declaration
{
    LARGE_INTEGER ticks;
    platform_require( QueryPerformanceCounter(&ticks) );
    return ticks.QuadPart;
}

platform_handle_messages_declaration
{
    auto win32 = &platform->win32;
    
    bool shift_is_active   = GetKeyState(VK_SHIFT)   >> 7;
    bool control_is_active = GetKeyState(VK_CONTROL) >> 7;
    bool alt_is_active     = GetKeyState(VK_MENU)    >> 7;
    platform->character_count = 0;
    
    for (u32 i = 0; i < carray_count(platform->keys); i++)
        platform->keys[i].half_transition_count = 0;
    
    MSG msg;
    while (PeekMessageA(&msg, null, 0, 0, PM_REMOVE))
    {
        switch (msg.message)
        {
            case WM_QUIT:
            {
                return false;
            } break;
        
            case WM_CHAR:
            {
               platform_win23_push_char(platform, msg.wParam, true, false, false, false);
            } break;
            
            case WM_KEYDOWN:
            {
                if (msg.wParam == VK_CONTROL)
                {
                    control_is_active = true;
                }
                else if (msg.wParam == VK_SHIFT)
                {
                    shift_is_active = true;
                }
                else
                {
                    platform_win23_push_char(platform, msg.wParam, false, shift_is_active, control_is_active, alt_is_active);
                }
                
                platform_button_update(&platform->keys[msg.wParam], true);
            } break;
            
            case WM_SYSKEYDOWN:
            {
                if (msg.wParam == VK_CONTROL)
                {
                    control_is_active = true;
                }
                else if (msg.wParam == VK_SHIFT)
                {
                    shift_is_active = true;
                }
                else
                {
                    platform_win23_push_char(platform, msg.wParam, false, shift_is_active, control_is_active, true);
                }
                
                platform_button_update(&platform->keys[msg.wParam], true);
            } break;
            
            case WM_KEYUP:
            {
                if (msg.wParam == VK_CONTROL)
                {
                    control_is_active = false;
                }
                
                if (msg.wParam == VK_SHIFT)
                {
                    shift_is_active = false;
                }
                
                platform_button_update(&platform->keys[msg.wParam], false);
            } break;
            
            case WM_SYSKEYUP:
            {
                platform_button_update(&platform->keys[msg.wParam], false);
            } break;
        }
    
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    
    platform_update_delta_seconds(platform);
    
    return true;
}

platform_window_get_position_declaration
{
    MONITORINFO monitor_info = { sizeof(monitor_info) };
    platform_require( GetMonitorInfo(MonitorFromWindow(window->win32.handle, MONITOR_DEFAULTTOPRIMARY), &monitor_info) );
    
    RECT rectangle;
    platform_require( GetClientRect(window->win32.handle, &rectangle) );
    
    POINT min;
    min.x = rectangle.left;
    min.y = rectangle.bottom;
    platform_require( ClientToScreen(window->win32.handle, &min) );
    
    s32 width  = rectangle.right - rectangle.left;
    s32 height = rectangle.bottom - rectangle.top;
    
    platform_window_position position;
    position.x      = min.x;
    position.y      = monitor_info.rcMonitor.bottom - min.y;
    position.width  = width;
    position.height = height;
    
    return position;
}

platform_window_init_declaration
{
    assert(!window->win32.handle);
    
    DWORD window_style = WS_OVERLAPPEDWINDOW;
    
    RECT client_rect = {};
    client_rect.right  = width;
    client_rect.bottom = height;
    AdjustWindowRect(&client_rect, window_style, FALSE);
    
    width  = client_rect.right  - client_rect.left;
    height = client_rect.bottom - client_rect.top;
    
    s32 window_x;
    s32 window_y;
    if (!use_xy)
    {
        window_x = CW_USEDEFAULT;
        window_y = CW_USEDEFAULT;
    }
    else
    {
        window_x = 0;
        window_y = 0;
    }
    
    window->win32.handle = CreateWindowExA(0, platform_win32_window_class_name, title, window_style, window_x, window_y, width, height, null, null, platform->win32.instance, 0);
    platform_require(window->win32.handle != INVALID_HANDLE_VALUE);                                         
    
    if (maximized)
    {
        // does not error
        ShowWindow(window->win32.handle, SW_SHOWMAXIMIZED);
    }
    else if (use_xy)
    {
        assert(window_x == 0 && window_y == 0);
        
        auto position = platform_window_get_position(platform, window);
        x = x - position.x;
        y = position.y - y;
        platform_require( SetWindowPos(window->win32.handle, null, x, y, 0, 0, SWP_NOSIZE | SWP_SHOWWINDOW) );
    }
    else
    {
        // does not error
        ShowWindow(window->win32.handle, SW_SHOWNORMAL);
    }
    
    window->win32.device_context = GetDC(window->win32.handle);
    platform_require(window->win32.device_context);
    
    PIXELFORMATDESCRIPTOR pixel_format_descriptor = {};
    pixel_format_descriptor.nSize        = sizeof(PIXELFORMATDESCRIPTOR);
    pixel_format_descriptor.nVersion     = 1; // allways 1
    pixel_format_descriptor.dwFlags      = PFD_DRAW_TO_WINDOW;// | PFD_DOUBLEBUFFER; // | PFD_SUPPORT_OPENGL
    pixel_format_descriptor.iPixelType   = PFD_TYPE_RGBA;
    pixel_format_descriptor.cColorBits   = 32;
    pixel_format_descriptor.cDepthBits   = 24;
    pixel_format_descriptor.cStencilBits = 8;
    pixel_format_descriptor.iLayerType   = PFD_MAIN_PLANE;
    
    s32 pixel_format = ChoosePixelFormat(window->win32.device_context, &pixel_format_descriptor);
    platform_require(pixel_format);
    platform_require( SetPixelFormat(window->win32.device_context, pixel_format, &pixel_format_descriptor) );
}

platform_window_get_size_declaration
{
    RECT viewport;
    platform_require( GetClientRect(window->win32.handle, &viewport) );
        
    platform_window_size size;
    size.width  = viewport.right - viewport.left;
    size.height = viewport.bottom - viewport.top;
    
    return size;
}

platform_file_search_begin_declaration
{
    string relative_path_prefix = { 0, relative_path_pattern.base };
    for (u32 i = 0; i < relative_path_pattern.count; i++)
    {
        if (relative_path_pattern.base[i] == '/')
            relative_path_prefix.count = i + 1;
            
        assert(relative_path_pattern.base[i] != '\\');
    }
    
    string name = { relative_path_pattern.count - relative_path_prefix.count, relative_path_prefix.base + relative_path_prefix.count };
    
    cstring pattern;
    if (name.count)
        pattern = (cstring) print_zero_terminated(tmemory, "%.*s*%.*s*", fs(relative_path_prefix), fs(name)).base;
    else
        pattern = (cstring) print_zero_terminated(tmemory, "%.*s*", fs(relative_path_prefix)).base;

    platform_file_search_iterator iterator = {};
    iterator.relative_path_prefix = relative_path_prefix;
    
    iterator.win32.handle = FindFirstFileA(pattern, &iterator.win32.find_data);
    if (iterator.win32.handle == INVALID_HANDLE_VALUE)
        iterator.win32.handle = 0;
    
    free_bytes(tmemory, (u8 *) pattern);
    
    return iterator;
}

platform_file_search_end_declaration
{
    free_array(tmemory, &iterator->found_file.absolute_path);
    free_array(tmemory, &iterator->found_file.relative_path);
    iterator->win32.handle = 0;
}

platform_file_search_next_declaration
{
    if (!iterator->win32.handle)
        return false;
        
    free_array(tmemory, &iterator->found_file.absolute_path);
    free_array(tmemory, &iterator->found_file.relative_path);
    
    iterator->found_file.is_directory = (iterator->win32.find_data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
    
    string relative_path;
    if (iterator->win32.find_data.cFileName[0] == '.' && iterator->win32.find_data.cFileName[1] == '\0')
    {
        // copy, since we will free it
        relative_path = print(tmemory, "%.*s", fs(iterator->relative_path_prefix));
    }
    else
    {
        relative_path = print(tmemory, "%.*s%s", fs(iterator->relative_path_prefix), iterator->win32.find_data.cFileName);
        
        if (iterator->found_file.is_directory)
            relative_path.count += print(tmemory, "/").count;
        
        for (u32 i = 0; i < relative_path.count; i++)
            if (relative_path.base[i] == '\\')
                relative_path.base[i] = '/';
    }
        
    string absolute_path = get_absolute_path(tmemory, platform->working_directory, relative_path);
    
    iterator->found_file.relative_path = relative_path;
    iterator->found_file.absolute_path = absolute_path;
    
    if (!FindNextFileA(iterator->win32.handle, &iterator->win32.find_data))
        iterator->win32.handle = 0;
    
    return true;
}

platform_read_embedded_file_declaration
{
    HMODULE module = null; // exe
    HRSRC resource = FindResourceA(module, filename, RT_RCDATA);
    platform_require(resource);
    if (!resource)
        return {};
    
    HGLOBAL data_handle = LoadResource(module, resource);
    require(data_handle);
    
    u8_array data;
    data.base = (u8 *) LockResource(data_handle);
    require(data.base);
    
    data.count = (usize) SizeofResource(module, resource);
    require(data.count);
    
    // no need to unlock data ..
    
    return data;
}

#if 0
memory_arena platform_memory_arena(usize byte_count)
{
    auto bytes = platform_allocate_bytes(byte_count);
    
    memory_arena arena = {};
    arena.base  = bytes.base;
    arena.count = bytes.count;
    
    return arena;
}
#endif

platform_fatal_error_location_va_declaration
{
    cstring layout =
        "%s,%d\n"
        "    %s\n"
        "\n";

    u32 byte_count = _scprintf(layout, location.file, location.line, location.function);
    byte_count += _vscprintf(format, va_arguments);
     
    u8 _text[1024];
    string text = { carray_count(_text),  _text };
    
    u32 offset = 0;
    offset += sprintf_s((char *) text.base, text.count, layout, location.file, location.line, location.function);
    offset += vsprintf_s((char *) text.base + offset, text.count - offset, format, va_arguments);
    
    printf("\n%s:\n%s\n", label, text.base);
    
    bool do_break = false;
    switch (MessageBox(null, (char *) text.base, label, MB_TASKMODAL | MB_CANCELTRYCONTINUE | MB_ICONERROR))
    { 
        // Instead of calling debug break here, we just return if we want to break.
        // This way we can place the break in the assert macro and actually break at the right position
        case IDTRYAGAIN:
        {
            do_break = true;
        } break;
        
        case IDCANCEL:
        {
            exit(-1);
        } break;
    }   
    
    return do_break;
}

platform_allocate_bytes_location_declaration
{
    if (!byte_count)
        return {};

    usize page_alignment_mask = 4095;
    
    u8_array memory;
    memory.count = (byte_count + page_alignment_mask) & ~page_alignment_mask;
    memory.base  = (u8 *) VirtualAlloc(null, memory.count, MEM_COMMIT, PAGE_READWRITE);
    platform_require_location(memory.base, call_location, "out of memory"); // this will never trigger on x64
    
#if defined _DEBUG

    {
        auto table = &global_debug_platform_allocation_table;
        
        for (usize i = 0; i < table->count; i++)
        {
            assert(table->bases[i] != memory.base);
        }
        
        assert(table->count < carray_count(table->bases));
        table->bases[table->count]       = memory.base;
        table->byte_counts[table->count] = memory.count;
        table->locations[table->count]   = call_location;
        table->count++;
        
        table->byte_count += memory.count;
    }
    
#endif
    
    return memory;
}

platform_free_bytes_location_declaration
{
    if (base)
        platform_require_location(VirtualFree((void *) base, 0, MEM_RELEASE), call_location);
        
#if defined _DEBUG

    if (base)
    {
        auto table = &global_debug_platform_allocation_table;
        
        usize index = -1;
        for (usize i = 0; i < table->count; i++)
        {
            if (table->bases[i] == base)
            {
                index = i;
                break;
            }
        }
        
        assert(index != -1);
        assert(table->count);
        
        assert(table->byte_counts[index] <= table->byte_count);
        table->byte_count -= table->byte_counts[index];
        
        --table->count;
        table->bases[index]       = table->bases[table->count];
        table->byte_counts[index] = table->byte_counts[table->count];
        table->locations[index]   = table->locations[table->count];
    }
    
#endif
}

platform_get_file_info_declaration
{
    WIN32_FILE_ATTRIBUTE_DATA data;
    BOOL ok = GetFileAttributesExA(file_path, GetFileExInfoStandard, &data);
    
    if (!ok)
        return {};
    
    u64 byte_count = (((u64) data.nFileSizeHigh) << 32) | data.nFileSizeLow;
    
    u64 write_timestamp = (((u64) data.ftLastWriteTime.dwHighDateTime) << 32) | (u64) data.ftLastWriteTime.dwLowDateTime;
    
    platform_file_info result;
    result.ok = true;
    result.is_directory = (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
    result.byte_count = byte_count;
    result.write_timestamp = write_timestamp;
    
    return result;
}

platform_read_entire_file_declaration
{
    auto file_info = platform_get_file_info(file_path);
    assert(file_info.ok && !file_info.is_directory && (file_info.byte_count == memory.count));

    HANDLE file_handle = CreateFileA(file_path, GENERIC_READ, FILE_SHARE_READ, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);
    
    // might be written to
    if (file_handle == INVALID_HANDLE_VALUE)
        return false;
    
    // we can only read in ~4gb chunks
    while (memory.count)
    {
        DWORD byte_count;
        
        // has higher bits set
        if (memory.count >> 32) 
            byte_count = 0xFFFFFFFF;
        else
            byte_count = memory.count;
        
        DWORD read_byte_count;
        auto ok = ReadFile(file_handle, memory.base, byte_count, &read_byte_count, null);
        assert(ok && (byte_count == read_byte_count));
        
        memory.base  += byte_count;
        memory.count -= byte_count;
    }
    
    CloseHandle(file_handle);
    
    return true;
}

platform_write_entire_file_declaration
{
    HANDLE file_handle = CreateFileA(file_path, GENERIC_WRITE, 0, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, null);
    //platform_require(file_handle != INVALID_HANDLE_VALUE);
    
    if (file_handle == INVALID_HANDLE_VALUE)
        return false;
    
    while (memory.count)
    {
        DWORD byte_count;
        // has higher bits set
        if (memory.count >> 32) 
            byte_count = 0xFFFFFFFF;
        else
            byte_count = memory.count;
        
        DWORD write_byte_count;
        auto ok = WriteFile(file_handle, memory.base, byte_count, &write_byte_count, null);
        //platform_require(ok && (byte_count == write_byte_count));
        if (!ok || byte_count != write_byte_count)
            return false;
        
        memory.base  += byte_count;
        memory.count -= byte_count;
    }
    
    CloseHandle(file_handle);
    
    return true;
}
