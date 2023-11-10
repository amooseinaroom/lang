
#include "platform.h"

struct parsed_type
{
    string name;
    u32 indirection_count;
};

bool add_unique(string_buffer *strings, string text)
{
    for (usize i = 0; i < strings->count; i++)
    {
        if (strings->base[i] == text)
            return false;
    }

    resize_buffer(strings, strings->count + 1);
    strings->base[strings->count - 1] = text;
    return true;
}

bool try_skip_keyword(string *iterator, string keyword)
{
    auto backup = *iterator;
    auto name = skip_name(iterator);
    if (name == keyword)
    {
        skip_white(iterator);
        
        return true;
    }
    else
    {
        *iterator = backup;
        
        return false;
    }
}

parsed_type skip_type(string *iterator)
{
    parsed_type result = {};
    
    try_skip_keyword(iterator, s("const"));
    try_skip_keyword(iterator, s("CONST")); // since windows is DUMB!!! #define CONST const
    
    try_skip_keyword(iterator, s("struct"));
    
    result.name = skip_name(iterator);
    while ((result.name == s("unsigned")) || (result.name == s("signed")) || (result.name == s("long")))
    {
        auto name = skip_name(iterator);
        result.name.count = name.base + name.count - result.name.base;
    }
    
    string c_to_lang_types[][2] =
    {
        //{ s("void"),               s("u8") },
        
        { s("char"),   s("u8") },
        { s("short"),  s("s16") },
        { s("int"),    s("s32") },
        { s("long"),   s("s32") },
        { s("float"),  s("f32") },
        { s("double"), s("f64") },
        
        { s("unsigned long"),      s("u32") },
        
        { s("unsigned char"),      s("u8") },
        { s("unsigned short"),     s("u16") },
        { s("unsigned int"),       s("u32") },
        { s("unsigned long long"), s("u64") },
        //{ s("size_t"),             s("usize") },
        
        { s("LPVOID"),             s("u8 ref") },
        { s("USHORT"),             s("u16") },
        { s("SHORT"),              s("s16") },
        { s("UINT"),               s("u32") },
        { s("INT"),                s("s32") },
        { s("BOOL"),               s("s32") },
        { s("DWORD"),              s("u32") },
        { s("FLOAT"),              s("f32") },
        { s("INT32"),              s("s32") },
        { s("INT64"),              s("s64") },
        
        { s("signed char"),      s("s8") },
        { s("signed short"),     s("s16") },
        { s("signed int"),       s("s32") },
        { s("signed long long"), s("s64") },
        
        // thank you khronos, that was completely useful gg
        { s("khronos_uint8_t"),  s("u8") },
        { s("khronos_uint16_t"), s("u16") },
        { s("khronos_uint32_t"), s("u32") },
        { s("khronos_uint64_t"), s("u64") },
        //{ s("khronos_size_t"),  s("usize") },
        
        { s("khronos_int8_t"),  s("s8") },
        { s("khronos_int16_t"), s("s16") },
        { s("khronos_int32_t"), s("s32") },
        { s("khronos_int64_t"), s("s64") },
        { s("khronos_ssize_t"), s("ssize") },
        
        { s("__GLsync"), s("u8") },
    };
    
    for (u32 i = 0; i < carray_count(c_to_lang_types); i++)
    {
        if (c_to_lang_types[i][0] == result.name)
        {
            result.name = c_to_lang_types[i][1];
            break;
        }
    }
    
    // thank you khronos, that was completely useful gg
    if (result.name == s("khronos_intptr_t"))
    {
        result.name = s("s32");
        result.indirection_count = 1;
    }
    
    //string name = *iterator;
    while (true)
    {
        if (try_skip(iterator, s("*")))
        {
            result.indirection_count++;
        }
        else if (try_skip_keyword(iterator, s("const")) || try_skip_keyword(iterator, s("CONST"))) // since windows is DUMB!!! #define CONST const
        {
        }
        else 
        {
            break;
        }
        
        skip_white(iterator);
    }
    
    if ((result.name == s("void")) || (result.name == s("VOID")))
    {
        if (result.indirection_count)
            result.name = s("u8");
        else
            result.name = {};
    }
    
    return result;
}

void print_type(string_builder *builder, parsed_type type)
{
    assert(type.name.count);
    print(builder, "%.*s", fs(type.name));
    
    for (u32 i = 0; i < type.indirection_count; i++)
        print(builder, " ref");
}

void parse_and_print_function_arguments(string_builder *builder, string *iterator, string name, parsed_type return_type, bool define_function)
{
    skip(iterator, s("(")); skip_white(iterator);
    
    print_newline(builder);
    
    if (define_function)
        print(builder, "func %.*s(", fs(name));
    else
        print(builder, "func %.*s_signature(", fs(name));
    
    u32 argument_count = 0;
    while (true)
    {
        auto type = skip_type(iterator);
        
        // function line foo(void), because C can ._.
        if (!type.name.count)
            break;
        
        auto name = skip_name(iterator);
        
        if (argument_count)
            print(builder, ", ");
            
        if (name.count)
            print(builder, "%.*s ", fs(name));
        else
            print(builder, "argument%i ", argument_count);
            
        print_type(builder, type);
        
        argument_count++;
        
        if (!try_skip(iterator, s(",")))
            break;
            
        skip_white(iterator);
    }
    
    skip(iterator, s(")"));
    skip_white(iterator);
    skip(iterator, s(";"));
    
    print(builder, ")");
    
    if (return_type.name.count)
    {
        print(builder, " (result ");
        print_type(builder, return_type);
        print(builder, ")");
    }
}

void parse_and_print_file(string_builder *builder, bool define_function, string_buffer *constants, string_buffer *dll_functions, string source)
{
    auto it = source;
    skip_white(&it);
    
    while (it.count)
    {
        skip_white(&it);
        
        string line = it;
        
        {
            string ignored;
            if (!try_skip_until_set(&ignored, &it, s("\r\n"), true))
                it = {};
        }
        
        if (try_skip(&line, s("#")) && try_skip_keyword(&line, s("define")))
        {
            skip_white(&line);
            
            auto name = skip_name(&line);
        
            //if (!starts_with(name, s("GL_")) && (exclude_wgl_constants || !starts_with(name, s("WGL_"))))
            if (!starts_with(name, s("GL_")) && !starts_with(name, s("WGL_")))
                continue;
            
            string value;
            try_skip_until_set(&value, &line, s("u\r\n"), true); // u is number prefix, we don't care about
            it = line;
            
            if (add_unique(constants, name))
                print_line(builder, "def %.*s = %.*s;", fs(name), fs(value));
            continue;
        }
    #if 0
        else if (try_skip_keyword(&line, s("struct")))
        {
            auto name = skip_name(&line);
            if (!try_skip(&line, s(";")))
                continue;
            
            // forward declared structs will only be passed by pointer, so treat them as u8
            print_line(builder, "type %.*s def u8;", fs(name));
            it = line;
        }
    #endif
        else if (try_skip_keyword(&line, s("typedef")))
        {
            auto type = skip_type(&line);
            
            if (try_skip(&line, s("(")))
            {
                // is gl function signature, we generate them ourselfs
                if (!try_skip_keyword(&line, s("APIENTRY")) || !try_skip(&line, s("*")))
                    continue;
                
                skip_white(&line);
                
                // is callback signature, we care about, like GLDEBUGPROC
                auto name = skip_name(&line);
                
                if (!starts_with(name, s("GL")))
                    continue;
                
                skip(&line, s(")"));
                
                parse_and_print_function_arguments(builder, &line, name, type, true);
                print_line(builder, ";");
                
                it = line;
            }
            else
            {
            #if 0
                auto name = skip_name(&line);
                
                // probably parsed function pointer type
                if (!starts_with(name, s("GL")))
                    continue;
                
                string ignored;
                try_skip_until_set(&ignored, &line, s(";"), true);
                it = line;
                
                print(builder, "type %.*s ", fs(name));
                if (type.name.count)
                    print_type(builder, type);
                else
                    print(builder, "u8"); // replacing void
                    
                print_line(builder, ";");
            #endif
            }
            continue;
        }
        
        //bool define_function = !try_skip_keyword(&line, s("GLAPI"));
        try_skip_keyword(&line, s("GLAPI"));
        
        try_skip_keyword(&line, s("WINGDIAPI"));
        
        //if (!define_function && !))
            //continue;
            
        //skip_white(&line);
        
        auto return_type = skip_type(&line);
        
        try_skip_keyword(&line, s("APIENTRY"));
        try_skip_keyword(&line, s("WINAPI"));
        
        auto name = skip_name(&line);
        
        if (!starts_with(name, s("gl")) && !starts_with(name, s("wgl")))
            continue;
            
        parse_and_print_function_arguments(builder, &line, name, return_type, define_function);
        
        if (define_function)
        {
            print_line(builder, " extern_binding(\"opengl32\", true);");
        }
        else
        {
            print_line(builder, ";");
            print_line(builder, "var global %.*s %.*s_signature;", fs(name), fs(name));
            
            add_unique(dll_functions, name);
        }

        it = line;
    }
}

s32 main(s32 argument_count, cstring arguments[])
{
    struct {
        cstring path;
        //bool exclude_wgl_constants;
        bool dont_define_functions;
    } files[] =
    {
        { "C:/Program Files (x86)/Windows Kits/10/Include/10.0.19041.0/um/gl/GL.h", },
        { "gl/glext.h", true },
    };
    
    string_builder builder = {};
    string_buffer constants = {};
    string_buffer dll_functions = {};
    
    // some GL types
    print_raw(&builder, R"CODE(
module gl;
    
// types are manually added, since these are a mess to generate from the headers
type GLenum u32;

type GLsizei    s32; // actually u32, but its easier to handle as s32
type GLsizeiptr ssize;
type GLintptr   ssize;

type GLvoid     u8; // since its only useful as a pointer
type GLboolean  u8;
type GLchar     u8;
type GLbitfield u32;

type GLubyte  u8;
type GLushort u16;
type GLuint   u32;
type GLuint64 u64;

type GLbyte  s8;
type GLshort s16;
type GLint   s32;
type GLint64 s64;

type GLfloat  f32;
type GLdouble f64;

type GLclampf f32;
type GLclampd f64;

type GLhalf  s16;
type GLfixed s32;

type GLuint64EXT u64;
type GLint64EXT  s64;

type GLhalfNV         u16;
type GLvdpauSurfaceNV GLintptr;

type GLhandleARB   u32;
type GLcharARB     u8;
type GLsizeiptrARB ssize;
type GLintptrARB   s32 ref;

type GLeglImageOES u8 ref;

type GLeglClientBufferEXT u8 ref;

// structs that are passed by pointer only
type GLsync      u8;

type _cl_context u8;
type _cl_event   u8;
)CODE");

    for (u32 i = 0; i < carray_count(files); i++)
    {
        string source;
        if (!platform_allocate_and_read_entire_file(&source, files[i].path))
        {
            printf("couldn't open file %s\n", files[i].path);
            return 0;
        }
            
        //bool exclude_wgl_constants = files[i].exclude_wgl_constants;
        bool define_function = !files[i].dont_define_functions;
        
        print_newline(&builder);
        print_line(&builder, "// file: %s", files[i].path);
        
        print_newline(&builder);
        parse_and_print_file(&builder, define_function, &constants, &dll_functions, source);
    }
    
    platform_write_entire_file("modules/gl.t", builder.memory.array);
    
    // gl_win32.t
    
    resize_buffer(&builder.memory, 0);
    resize_buffer(&constants, 0);
    resize_buffer(&dll_functions, 0);
    
    // some GL types
    print_raw(&builder, R"CODE(
module gl;

type HGLRC                u8 ref;
type HPBUFFERARB          u8 ref;
type HPBUFFEREXT          u8 ref;
type HGPUNV               u8 ref;
type PGPU_DEVICE          u8 ref;
type HVIDEOOUTPUTDEVICENV u8 ref;
type HVIDEOINPUTDEVICENV  u8 ref;
type HPVIDEODEV           u8 ref;

func wglGetProcAddress(name cstring) (address u8 ref)                     calling_convention "__stdcall" extern_binding("opengl32", true);
func wglCreateContext (device_context HDC) (gl_context HGLRC)             calling_convention "__stdcall" extern_binding("opengl32", true);
func wglDeleteContext ( gl_context HGLRC) (resukt u32)                    calling_convention "__stdcall" extern_binding("opengl32", true);
func wglMakeCurrent   (device_context HDC, gl_context HGLRC) (resukt u32) calling_convention "__stdcall" extern_binding("opengl32", true);
)CODE");
    
    {
        string source;
        if (!platform_allocate_and_read_entire_file(&source, "gl/wglext.h"))
        {
            printf("couldn't open file %s\n", "gl/wglext.h");
            return 0;
        }
        
        bool define_function = false;
        parse_and_print_file(&builder, define_function, &constants, &dll_functions, source);
    }
    
    platform_write_entire_file("modules/win32/gl_win32.t", builder.memory.array);
    
    /*
    print_newline(&builder);
    print_line(&builder, "func gl_init_functions()");
    print_scope_open(&builder);
    
    for (u32 i = 0; i < dll_functions.count; i++)
    {
        auto function = dll_functions.base[i];
        print_line(&builder, "%.*s = wglGetProcAddress(\"%.*s\\0\".base cast(cstring)) cast(%.*s_signature);", fs(function), fs(function), fs(function));
    }
    
    print_scope_close(&builder);
    
    platform_write_entire_file("modules/gl_win32.t", builder.memory.array);
    */

    return 0;
}