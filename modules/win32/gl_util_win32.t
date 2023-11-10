module gl;

import platform;
import win32;
import memory;
import string;

struct gl_api
{
    expand base gl_api_base;
    
    // win32 specific
    win32_context             HGLRC;
    win32_init_window_handle  HWND;
    win32_init_device_context HDC;
}

func gl_init gl_init_type
{
    var window_class WNDCLASSA;
    window_class.hInstance     = platform.instance;
    window_class.lpfnWndProc   = get_function_reference(DefWindowProcA WNDPROC);
    window_class.hbrBackground = COLOR_BACKGROUND cast(usize) cast(HBRUSH);
    window_class.lpszClassName = "gl dummy window class\0".base cast(cstring);
    window_class.style         = CS_OWNDC;
    window_class.hCursor       = LoadCursorA(null, IDC_ARROW);
    platform_require(RegisterClassA(window_class ref));

    var window_handle = CreateWindowExA(0, window_class.lpszClassName, "gl dummy window\0".base cast(cstring), WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 128, 128, null, null, window_class.hInstance, null);
    platform_require(window_handle is_not null);

    var device_context = GetDC(window_handle);
    platform_require(device_context is_not null);
    
    gl_win32_window_init_1(device_context);
    
    var gl_context = wglCreateContext(device_context);
    platform_require(gl_context is_not null);
    
    platform_require(wglMakeCurrent(device_context, gl_context));
    
    gl_load_bindings();
    
    if wglChoosePixelFormatARB and wglCreateContextAttribsARB
    {
        platform_require(wglMakeCurrent(null, null));
    
        var gl_3_3_window_handle = CreateWindowExA(0, window_class.lpszClassName, as_cstring("gl dummy window\0"), WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 128, 128, null, null, window_class.hInstance, null);
        platform_require(gl_3_3_window_handle is_not INVALID_HANDLE_VALUE);

        var gl_3_3_device_context = GetDC(gl_3_3_window_handle);
        platform_require(gl_3_3_device_context is_not null);
        
        gl_win32_window_init_3_3(gl_3_3_device_context);
        
        var context_attributes =
        [
            WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
            WGL_CONTEXT_MINOR_VERSION_ARB, 3,
            WGL_CONTEXT_FLAGS_ARB,         WGL_CONTEXT_DEBUG_BIT_ARB,
            WGL_CONTEXT_PROFILE_MASK_ARB,  WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
            0
        ] u32[];
        
        if backwards_compatible
            { context_attributes[7] = WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB; }
            
        var gl_3_3_context = wglCreateContextAttribsARB(gl_3_3_device_context, null, context_attributes[0] ref cast(s32 ref));
        
        if gl_3_3_context
        {
            platform_require(wglDeleteContext(gl_context));
            platform_require(ReleaseDC(window_handle, device_context));
            platform_require(DestroyWindow(window_handle));
            
            gl_context     = gl_3_3_context;
            device_context = gl_3_3_device_context;
            window_handle  = gl_3_3_window_handle;
            
            gl.is_version_3_3 = true;
        }
        else
        {
            platform_require(ReleaseDC(gl_3_3_window_handle, gl_3_3_device_context));
            platform_require(DestroyWindow(gl_3_3_window_handle));
        }
        
        platform_require(wglMakeCurrent(device_context, gl_context));
    }
    
    gl.win32_context             = gl_context;
    gl.win32_init_window_handle  = window_handle;
    gl.win32_init_device_context = device_context;    

    gl_base_init(gl.base ref);
}

func gl_set_vertical_sync gl_set_vertical_sync_type
{
    wglSwapIntervalEXT(enabled cast(s32));
}

func gl_window_init gl_window_init_type
{
    if gl.is_version_3_3
    {
        gl_win32_window_init_3_3(window.device_context);
    }
    else
    {
        gl_win32_window_init_1(window.device_context);
    }
    
    platform_require(wglMakeCurrent(window.device_context, gl.win32_context));
}

func gl_window_frame gl_window_frame_type
{
    platform_window_frame(platform, window);
    platform_require(wglMakeCurrent(window.device_context, gl.win32_context));
}

func gl_window_present gl_window_present_type
{
    SwapBuffers(window.device_context);
}

func gl_win32_window_init_1(device_context HDC)
{
    var pixel_format_descriptor PIXELFORMATDESCRIPTOR;
    pixel_format_descriptor.nSize        = type_byte_count(type_of(pixel_format_descriptor)) cast(u16);
    pixel_format_descriptor.nVersion     = 1; // allways 1
    pixel_format_descriptor.dwFlags      = PFD_DRAW_TO_WINDOW bit_or PFD_SUPPORT_OPENGL bit_or PFD_DOUBLEBUFFER;
    pixel_format_descriptor.iPixelType   = PFD_TYPE_RGBA;
    pixel_format_descriptor.cColorBits   = 24; //32;
    pixel_format_descriptor.cDepthBits   = 24;
    pixel_format_descriptor.cStencilBits = 8;
    pixel_format_descriptor.iLayerType   = PFD_MAIN_PLANE;
    
    var pixel_format = ChoosePixelFormat(device_context, pixel_format_descriptor ref);
    platform_require(pixel_format is_not 0);
    platform_require(SetPixelFormat(device_context, pixel_format, pixel_format_descriptor ref));
}

func gl_win32_window_init_3_3(device_context HDC)
{
    var pixel_format_attributes =
    [
        WGL_DRAW_TO_WINDOW_ARB, GL_TRUE,
        WGL_SUPPORT_OPENGL_ARB, GL_TRUE,
        WGL_DOUBLE_BUFFER_ARB,  GL_TRUE,
        WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
        WGL_COLOR_BITS_ARB, 24,
        WGL_DEPTH_BITS_ARB, 24,
        WGL_STENCIL_BITS_ARB, 8,
        
        // multi sample anti aliasing
        // WGL_SAMPLE_BUFFERS_ARB, GL_TRUE, // Number of buffers (must be 1 at time of writing)
        // WGL_SAMPLES_ARB, 1,  // Number of samples
        
        0 // end
    ] u32[];
    
    var pixel_format s32;
    var pixel_format_count u32;
    platform_require(wglChoosePixelFormatARB(device_context, pixel_format_attributes[0] ref cast(s32 ref), null, 1, pixel_format ref, pixel_format_count ref));
    platform_require(SetPixelFormat(device_context, pixel_format, null));
}

// if we compile with minimal dependencies, this list will only include gl calls, that are actually used
func gl_load_bindings gl_load_bindings_type
{
    loop var i; lang_global_variables.count
    {
        var variable = lang_global_variables[i];
        if (variable.type.type_type is lang_type_info_type.function) and not variable.type.indirection_count and starts_with(variable.name, "gl") or starts_with(variable.name, "wgl")
        {
            var buffer u8[256];
            write_cstring(buffer, variable.name);
            variable.base cast(u8 ref ref) deref = wglGetProcAddress(buffer.base cast(cstring));
        }
    }
}