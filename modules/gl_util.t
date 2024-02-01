module gl;

import platform;
import memory;
import string;
import math;
import wavefront;
import stb_image;
import meta;

def gl_util_debug = false;

struct gl_api_base
{
    is_version_3_3                         b8;
    uniform_buffer_offset_alignment        u32;
    max_framebuffer_multi_sample_count     u32;
    max_framebuffer_color_attachment_count u32;

    draw_framebuffer_handle u32;
    read_framebuffer_handle u32;
}

func gl_init_type(gl gl_api ref, platform platform_api ref, backwards_compatible b8 = false);
func gl_window_init_type(platform platform_api ref, gl gl_api ref, window platform_window ref);
func gl_window_frame_type(platform platform_api ref, gl gl_api ref, window platform_window ref);
func gl_window_present_type(platform platform_api ref, gl gl_api ref, window platform_window ref);
func gl_load_bindings_type();
func gl_set_vertical_sync_type(enabled b8);

// called at the end of gl_init
func gl_base_init(gl gl_api_base ref)
{
    if glDebugMessageCallback
    {
        glEnable(GL_DEBUG_OUTPUT);
        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS); // message will be generated in function call scope
        glDebugMessageCallback(get_function_reference(gl_debug_message_callback GLDEBUGPROC), null);
    }

    glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, gl.uniform_buffer_offset_alignment ref cast(s32 ref));
    glGetIntegerv(GL_MAX_SAMPLES,                     gl.max_framebuffer_multi_sample_count ref cast(s32 ref));
    glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS,           gl.max_framebuffer_color_attachment_count ref cast(s32 ref));
}

func gl_debug_message_callback GLDEBUGPROC
{
    var text string;
    text.base = message cast(u8 ref);

    while (text.base + text.count) deref is_not 0
        text.count = text.count + 1;

    // ignore compile errors, we handle them ourself
    if source is_not GL_DEBUG_SOURCE_SHADER_COMPILER
        print("GL-Message: %\n", text);

    assert((type is_not GL_DEBUG_TYPE_ERROR) or (source is GL_DEBUG_SOURCE_SHADER_COMPILER), "GL-Message: %\n", text);
}

// reload_shader works with structs like this:
//
// struct my_shader
//{
//    handle u32; // gl shader program handle, matched by type u32 and name "handle"
//
//    // gl uniform locations, matched by type s32
//    material_color s32;
//    diffuse_texture s32;
//}

struct gl_shader_base
{
    handle u32;
}

func reload_shader(gl gl_api ref, shader lang_typed_value, name string, vertex_attribute_prefix = "vertex_", vertex_attributes_enum lang_type_info, uniform_buffer_bindings_enum = {} lang_type_info, expand vertex_shader_sources string[], source_separation b8, expand fragment_shader_sources string[], error_memory memory_arena ref = null) (ok b8, error_messages string)
{
    assert(shader.type.type_type is lang_type_info_type.compound);

    var compound = shader.type.compound_type deref;
    var handle u32 ref;
    loop var i; compound.fields.count
    {
        if compound.fields[i].name is "handle"
        {
            assert(compound.fields[i].type.type_type is lang_type_info_type.number);
            var number_type = compound.fields[i].type.number_type deref;
            assert(number_type.number_type is lang_type_info_number_type.u32);

            handle = (shader.base + compound.fields[i].byte_offset) cast(u32 ref);
            break;
        }
    }
    assert(handle is_not null, "shader struct has no handle u32 field");

    var result = create_shader_object(gl, name, false, vertex_shader_sources, error_memory);
    if not result.shader_object
        return false, result.error_messages;

    var vertex_shader = result.shader_object;

    result = create_shader_object(gl, name, true, fragment_shader_sources, error_memory);
    if not result.shader_object
    {
        glDeleteShader(vertex_shader); // TODO: add defer
        return false, result.error_messages;
    }

    var fragment_shader = result.shader_object;

    var program = create_program_begin(gl);

    create_program_add_shader(gl, program, vertex_shader);
    create_program_add_shader(gl, program, fragment_shader);

    create_program_bind_attributes(gl, program, vertex_attributes_enum, vertex_attribute_prefix);

    var program_result = create_program_end(gl, program, name, error_memory);

    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);

    if not program_result.ok
        return false, program_result.error_messages;

    if handle deref
        glDeleteProgram(handle deref);

    handle deref = program;

    loop var i; compound.fields.count
    {
        if compound.fields[i].name is_not "handle"
        {
            assert(compound.fields[i].type.type_type is lang_type_info_type.number);
            var number_type = compound.fields[i].type.number_type deref;
            assert(number_type.number_type is lang_type_info_number_type.s32);

            var location = (shader.base + compound.fields[i].byte_offset) cast(s32 ref);

            var name u8[256];
            write(name, "%\0", compound.fields[i].name);

            location deref = glGetUniformLocation(program, name.base);
            //assert(location deref is_not -1);
        }
    }

    if uniform_buffer_bindings_enum.reference
        gl_bind_shader_uniform_blocks(program, uniform_buffer_bindings_enum);

    return true, {} string;
}

func create_shader_object(gl gl_api ref, name string, is_fragment_shader b8, expand sources string[], error_memory memory_arena ref = null) (shader_object u32, error_messages string)
{
    var shader_kind_map =
    [
        GL_VERTEX_SHADER,
        GL_FRAGMENT_SHADER
    ] GLuint[];

    var gl_shader_kind = shader_kind_map[is_fragment_shader];
    var shader_object = glCreateShader(gl_shader_kind);

    var source_bases  u8 ref [32];
    var source_counts s32[32];
    assert(sources.count <= source_bases.count);

    loop var i; sources.count
    {
        source_bases[i]  = sources[i].base;
        source_counts[i] = sources[i].count cast(s32);
    }

    glShaderSource(shader_object, sources.count cast(s32), source_bases.base, source_counts.base);

    glCompileShader(shader_object);

    var is_compiled GLint;
    glGetShaderiv(shader_object, GL_COMPILE_STATUS, is_compiled ref);
    if is_compiled is GL_FALSE
    {
        var error_messages string;
        if error_memory
        {
            def shader_type_names = [ "vertex", "fragment" ] string[];

            write(error_memory, error_messages ref, "GLSL Compile Error: could not compile % shader %\n", shader_type_names[is_fragment_shader], name);

            var info_byte_count GLint;
            glGetShaderiv(shader_object, GL_INFO_LOG_LENGTH, info_byte_count ref);

            var offset = error_messages.count;
            reallocate_array(error_memory, error_messages ref, error_messages.count + info_byte_count cast(u32));
            glGetShaderInfoLog(shader_object, info_byte_count, info_byte_count ref cast(GLsizei ref), error_messages[offset] ref cast(GLchar ref));
        }
        else
        {
            if not is_fragment_shader
                print("GLSL Compile Error: could not compile vertex shader %\n", name);
            else
                print("GLSL Compile Error: could not compile fragment shader %\n", name);

            var message_buffer u8[4096];
            var info_byte_count GLint;
            glGetShaderiv(shader_object, GL_INFO_LOG_LENGTH, info_byte_count ref);

            if info_byte_count > (message_buffer.count cast(GLint))
                info_byte_count = message_buffer.count cast(GLint);

            glGetShaderInfoLog(shader_object, info_byte_count, info_byte_count ref cast(GLsizei ref), error_messages.base cast(GLchar ref));
            var message = { info_byte_count cast(usize), message_buffer.base } string;
            print("%\n", message);
        }

        glDeleteShader(shader_object);
        return 0, error_messages;
    }

    return shader_object, {} string;
}

func create_program_begin(gl gl_api ref) (program_object u32)
{
    var program_object = glCreateProgram();
    return program_object;
}

func create_program_add_shader(gl gl_api ref, program_object u32, shader_object u32)
{
    assert(program_object);
    assert(shader_object);

    glAttachShader(program_object, shader_object);
}

func write_cstring(buffer u8[], text string, offset usize = 0) (count usize)
{
    var builder string_builder;
    builder.text.base  = buffer.base;
    builder.text.count = offset;
    builder.capacity  = buffer.count;
    write(builder ref, text);
    write(builder ref, "\0");

     // without 0 terminal, so it can be overwritten on successive calls
    return builder.text.count - offset - 1;
}

func create_program_bind_attribute(gl gl_api ref, program_object u32, index u32, name string, prefix = {} string)
{
    assert(program_object);

    var name_buffer u8[256];
    var offset = write_cstring(name_buffer, prefix);
    offset = offset + write_cstring(name_buffer, name, offset);
    glBindAttribLocation(program_object, index, name_buffer.base cast(GLchar ref));
}

func create_program_bind_attributes(gl gl_api ref, program_object u32, attribute_enumeration_type lang_type_info, prefix = {} string)
{
    assert(attribute_enumeration_type.type_type is lang_type_info_type.enumeration);
    var enumeration = attribute_enumeration_type.enumeration_type deref;

    loop var i; enumeration.items.count
    {
        var item = enumeration.items[i];
        create_program_bind_attribute(gl, program_object, item.value cast(u32), item.name, prefix);
    }
}

func create_program_end(gl gl_api ref, program_object u32, name string, error_memory memory_arena ref = null) (ok b8, error_messages string)
{
    assert(program_object);

    glLinkProgram(program_object);

    var is_linked GLint;
    glGetProgramiv(program_object, GL_LINK_STATUS, is_linked ref);
    if not is_linked
    {
        var error_messages string;
        if error_memory
        {
            write(error_memory, error_messages ref, "GLSL Error: Could not link gl program %:\n\n", name);

            var info_byte_count GLint;
            glGetProgramiv(program_object, GL_INFO_LOG_LENGTH, info_byte_count ref);

            var offset = error_messages.count;
            reallocate_array(error_memory, error_messages ref, error_messages.count + info_byte_count cast(u32));

            glGetProgramInfoLog(program_object, info_byte_count, info_byte_count ref cast(GLsizei ref), error_messages[offset] ref cast(GLchar ref));
        }
        else
        {
            print("GLSL Error: Could not link gl program:\n\n");

            var message_buffer u8[4096];
            var info_byte_count GLint;
            glGetProgramiv(program_object, GL_INFO_LOG_LENGTH, info_byte_count ref);

            if info_byte_count > (message_buffer.count cast(GLint))
                info_byte_count = message_buffer.count cast(GLint);

            glGetProgramInfoLog(program_object, info_byte_count, info_byte_count ref cast(GLsizei ref), message_buffer.base cast(GLchar ref));
            var message = { info_byte_count cast(usize), message_buffer.base } string;
            print("%\n", message);
        }

        glDeleteProgram(program_object);

        return false, error_messages;
    }

    return true, {} string;
}

func gl_bind_shader_uniform_blocks(program_object u32, unifrom_block_enumeration_type lang_type_info, prefix = {} string)
{
    assert(unifrom_block_enumeration_type.type_type is lang_type_info_type.enumeration);
    var enumeration = unifrom_block_enumeration_type.enumeration_type deref;

    loop var i; enumeration.items.count
    {
        var item = enumeration.items[i];
        var name_buffer u8[256];
        var offset = write_cstring(name_buffer, prefix);
        offset = offset + write_cstring(name_buffer, item.name, offset);

        var index = glGetUniformBlockIndex(program_object, name_buffer.base);
        if index is_not (-1 cast(u32))
            glUniformBlockBinding(program_object, index, item.value cast(u32));
    }
}

struct gl_texture
{
    handle u32;
    width  s32;
    height s32;
    format u32;
}

func destroy(gl gl_api ref, texture gl_texture ref)
{
    glDeleteTextures(1, texture.handle ref);
    texture deref = {} gl_texture;
}

func destroy(gl gl_api ref, texture gl_texture_cube ref)
{
    glDeleteTextures(1, texture.handle ref);
    texture deref = {} gl_texture_cube;
}

func gl_create_texture_2d(width s32, height s32, bilinear_sampling = true, colors u8[], color_format u32 = GL_SRGB_ALPHA, color_channel_format u32 = GL_UNSIGNED_BYTE, swizzle = false, swizzle_map = [ 0, 0, 0, 0 ] u32[]) (texture gl_texture)
{
    var result = gl_get_texture_color_format(color_format);
    color_format = result.color_format;
    var internal_format = result.internal_color_format;

    var texture gl_texture;
    texture.width  = width;
    texture.height = height;
    texture.format = internal_format;
    glGenTextures(1, texture.handle ref);
    glBindTexture(GL_TEXTURE_2D, texture.handle);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    if bilinear_sampling
    {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
    else
    {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    }

    if swizzle
    {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_R, swizzle_map[0]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_G, swizzle_map[1]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_B, swizzle_map[2]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_A, swizzle_map[3]);
    }

    glTexImage2D(GL_TEXTURE_2D, 0, internal_format, texture.width cast(u32), texture.height cast(u32), 0, color_format, color_channel_format, colors.base);
    glBindTexture(GL_TEXTURE_2D, 0);

    return texture;
}

func gl_get_texture_color_format(color_format u32) (color_format u32, internal_color_format u32)
{
    var internal_color_format u32;

    switch color_format
    case GL_RED
    {
        color_format          = GL_RED;
        internal_color_format = GL_RED;
    }
    case GL_RG
    {
        color_format          = GL_RG;
        internal_color_format = GL_RG;
    }
    case GL_RGBA
    {
        color_format          = GL_RGBA;
        internal_color_format = GL_RGBA;
    }
    case GL_SRGB_ALPHA
    {
        color_format          = GL_RGBA;
        internal_color_format = GL_SRGB_ALPHA;
    }
    case GL_RGB
    {
        color_format    = GL_RGB;
        internal_color_format = GL_RGB;
    }
    case GL_RGB16F
    {
        color_format          = GL_RGB;
        internal_color_format = GL_RGB16F;
    }
    case GL_RGB32F
    {
        color_format          = GL_RGB;
        internal_color_format = GL_RGB32F;
    }
    case GL_RGBA32F
    {
        color_format          = GL_RGBA;
        internal_color_format = GL_RGBA32F;
    }
    case GL_SRGB
    {
        color_format          = GL_RGB;
        internal_color_format = GL_SRGB;
    }
    case GL_DEPTH_COMPONENT
    {
        color_format          = GL_DEPTH_COMPONENT;
        internal_color_format = GL_DEPTH_COMPONENT;
    }    
    case GL_DEPTH_COMPONENT24
    {
        color_format          = GL_DEPTH_COMPONENT;
        internal_color_format = GL_DEPTH_COMPONENT24;
    }   
    case GL_DEPTH_STENCIL
    {
        color_format          = GL_DEPTH_COMPONENT;
        internal_color_format = GL_DEPTH_STENCIL;
    }    
    else
    {
        assert(0);
    }

    return color_format, internal_color_format;
}

struct gl_texture_cube
{
    handle u32;
    width  s32;
    height s32;
    format u32;
}

func gl_create_texture_cube(width s32, height s32, color_format u32 = GL_SRGB_ALPHA, color_channel_format u32 = GL_UNSIGNED_BYTE, data = {} u8[]) (texture gl_texture_cube)
{
    var result = gl_get_texture_color_format(color_format);
    color_format = result.color_format;
    var internal_format = result.internal_color_format;

    var texture gl_texture_cube;
    texture.width  = width;
    texture.height = height;
    texture.format = internal_format;
    glGenTextures(1, texture.handle ref);
    glBindTexture(GL_TEXTURE_CUBE_MAP, texture.handle);

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    var face_byte_count usize;
    switch color_channel_format
    case GL_UNSIGNED_BYTE
        face_byte_count = 1;
    case GL_FLOAT
        face_byte_count = 4;
    else
        assert(0);

    switch color_format
    case GL_RED
        face_byte_count *= 1;
    case GL_RG
        face_byte_count *= 2;
    case GL_RGB
        face_byte_count *= 3;
    case GL_RGBA
        face_byte_count *= 4;
    else
        assert(0);

    face_byte_count *= (width * height) cast(usize);

    loop var i u32; 6
    {
        if data.base
            glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, internal_format, texture.width cast(u32), texture.height cast(u32), 0, color_format, color_channel_format, data[i * face_byte_count] ref);
        else
            glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, internal_format, texture.width cast(u32), texture.height cast(u32), 0, color_format, color_channel_format, null);
    }

    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);

    return texture;
}

struct gl_framebuffer
{
    handle                     u32;
    width                      s32;
    height                     s32;
    format                     u32;
    sample_count               u32;
    attachment_is_texture_mask u32; // otherwise is buffer
    color_buffer_count         u32;
    depth_stencil_format       u32;
}

struct gl_framebuffer_color_and_depth
{
    expand base gl_framebuffer;
    
    color_buffer         u32;
    depth_stencil_buffer u32;    
}

func resize_framebuffer(gl gl_api ref, framebuffer gl_framebuffer ref, width s32, height s32, color_buffers u32[], depth_stencil_buffer u32 = 0)
{
    assert(color_buffers.count is framebuffer.color_buffer_count);
    assert((depth_stencil_buffer is 0) is (framebuffer.depth_stencil_format is 0));

    if width and height and ((framebuffer.width is_not width) or (framebuffer.height is_not height))
    {
        framebuffer.width  = width;
        framebuffer.height = height;

        loop var i; color_buffers.count
        {
            if framebuffer.attachment_is_texture_mask bit_and (1 bit_shift_left i)
            {
                if framebuffer.sample_count
                {
                    glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, color_buffers[i]);
                    glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, framebuffer.sample_count, framebuffer.format, framebuffer.width, framebuffer.height, GL_TRUE cast(GLboolean));
                }
                else
                {
                    glBindTexture(GL_TEXTURE_2D, color_buffers[i]);
                    glTexImage2D(GL_TEXTURE_2D, 0, framebuffer.format, framebuffer.width, framebuffer.height, 0, GL_RGBA, GL_BYTE, null);
                }
            }
            else
            {
                glBindRenderbuffer(GL_RENDERBUFFER, color_buffers[i]);

                if framebuffer.sample_count
                    glRenderbufferStorageMultisample(GL_RENDERBUFFER, framebuffer.sample_count, framebuffer.format, framebuffer.width, framebuffer.height);
                else
                    glRenderbufferStorage(GL_RENDERBUFFER, framebuffer.format, framebuffer.width, framebuffer.height);
            }
        }

        if framebuffer.depth_stencil_format
        {
            if framebuffer.attachment_is_texture_mask bit_and (1 bit_shift_left 31)
            {
                if framebuffer.sample_count
                {
                    glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, depth_stencil_buffer);
                    glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, framebuffer.sample_count, framebuffer.depth_stencil_format, framebuffer.width, framebuffer.height, GL_TRUE cast(GLboolean));
                }
                else
                {
                    glBindTexture(GL_TEXTURE_2D, depth_stencil_buffer);
                    glTexImage2D(GL_TEXTURE_2D, 0, framebuffer.depth_stencil_format, framebuffer.width, framebuffer.height, 0, framebuffer.depth_stencil_format, GL_BYTE, null);
                }
            }
            else
            {
                glBindRenderbuffer(GL_RENDERBUFFER, depth_stencil_buffer);

                if framebuffer.sample_count
                    glRenderbufferStorageMultisample(GL_RENDERBUFFER, framebuffer.sample_count, framebuffer.depth_stencil_format, framebuffer.width, framebuffer.height);
                else
                    glRenderbufferStorage(GL_RENDERBUFFER, framebuffer.depth_stencil_format, framebuffer.width, framebuffer.height);
            }
        }

        glBindRenderbuffer(GL_RENDERBUFFER, 0);
        glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, 0);
    }
}


func get_framebuffer_texture(framebuffer gl_framebuffer, texture_handle u32, is_depth_stencil = false) (texture gl_texture)
{
    assert(not is_depth_stencil or not framebuffer.depth_stencil_format);
    
    var format u32;
    if is_depth_stencil
        format = framebuffer.depth_stencil_format;
    else
        format = framebuffer.format;
        
    var texture = { texture_handle, framebuffer.width, framebuffer.height, format } gl_texture;
    return texture;
}

func destroy(gl gl_api ref, framebuffer gl_framebuffer ref, color_buffers u32[], depth_stencil_buffer u32 = 0)
{
    assert(framebuffer.handle);

    glDeleteFramebuffers(1, framebuffer.handle ref);

    loop var i; color_buffers.count
    {
        var handle = color_buffers[i];
        assert(handle);

        if framebuffer.attachment_is_texture_mask bit_and (1 bit_shift_left i)
            glDeleteTextures(1, handle ref);
        else
            glDeleteRenderbuffers(1, handle ref);
    }

    if framebuffer.depth_stencil_format
    {
        var handle = depth_stencil_buffer;
        assert(handle);

        if framebuffer.attachment_is_texture_mask bit_and (1 bit_shift_left 31)
            glDeleteTextures(1, handle ref);
        else
            glDeleteRenderbuffers(1, handle ref);
    }

    framebuffer deref = {} gl_framebuffer;
}

// TODO: remove sample_count since MSAA is not good anyways
func create_framebuffer_begin(gl gl_api ref, width s32, height s32, format u32 = GL_SRGB, sample_count = 0) (framebuffer gl_framebuffer)
{
    assert(not sample_count or not (sample_count bit_and (sample_count - 1)), "sample count must be either 0 or a power of 2");
    assert(sample_count <= gl.max_framebuffer_multi_sample_count);

    var framebuffer gl_framebuffer;
    framebuffer.width        = width;
    framebuffer.height       = height;
    framebuffer.sample_count = sample_count;
    framebuffer.format       = format;
    glGenFramebuffers(1, framebuffer.handle ref);

    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.handle);

    return framebuffer;
}

func create_framebuffer_end(gl gl_api ref, framebuffer gl_framebuffer ref) (ok b8)
{
    var ok = glCheckFramebufferStatus(GL_FRAMEBUFFER) is GL_FRAMEBUFFER_COMPLETE;
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    return ok;
}

func attach_color_texture(gl gl_api ref, framebuffer gl_framebuffer ref, filter u32 = GL_NEAREST, location = get_call_location()) (texture u32)
{
    assert(framebuffer.color_buffer_count < 31, location);
    assert(framebuffer.color_buffer_count < gl.max_framebuffer_color_attachment_count, location);

    var texture u32;
    glGenTextures(1, texture ref);

    if framebuffer.sample_count
    {
        glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, texture);

        glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, framebuffer.sample_count, framebuffer.format, framebuffer.width, framebuffer.height, true cast(GLboolean));

        glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, 0);
    }
    else
    {
        glBindTexture(GL_TEXTURE_2D, texture);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);

        glTexImage2D(GL_TEXTURE_2D, 0, framebuffer.format, framebuffer.width, framebuffer.height, 0, GL_RGBA, GL_BYTE, null);

        glBindTexture(GL_TEXTURE_2D, 0);
    }

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + framebuffer.color_buffer_count, GL_TEXTURE_2D, texture, 0);

    framebuffer.attachment_is_texture_mask bit_or= 1 bit_shift_left framebuffer.color_buffer_count;
    framebuffer.color_buffer_count += 1;

    return texture;
}

func enable_color_texture(gl gl_api ref, framebuffer gl_framebuffer ref, color_attachment_index u32, location = get_call_location())
{
    assert(color_attachment_index < 31, location);
    framebuffer.color_buffer_count = maximum(framebuffer.color_buffer_count, color_attachment_index + 1);

    framebuffer.attachment_is_texture_mask bit_or= 1 bit_shift_left color_attachment_index;
}

func attach_color_cubemap_texture(gl gl_api ref, framebuffer gl_framebuffer ref, filter u32 = GL_NEAREST, location = get_call_location()) (texture u32)
{
    assert(framebuffer.color_buffer_count < 31, location);
    assert(framebuffer.color_buffer_count < gl.max_framebuffer_color_attachment_count, location);

    var texture u32;
    glGenTextures(1, texture ref);

    assert(not framebuffer.sample_count);

    glBindTexture(GL_TEXTURE_CUBE_MAP, texture);

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, filter);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, filter);

    loop var i u32; 6
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, framebuffer.format, framebuffer.width, framebuffer.height, 0, GL_RGB, GL_BYTE, null);

    glBindTexture(GL_TEXTURE_2D, 0);

    framebuffer.attachment_is_texture_mask bit_or= 1 bit_shift_left framebuffer.color_buffer_count;
    framebuffer.color_buffer_count += 1;

    return texture;
}

func attach_color_buffer(gl gl_api ref, framebuffer gl_framebuffer ref, location = get_call_location()) (buffer u32)
{
    // use textures instead of buffers, so we can better inspect intermidate results in renderdoc
    if gl_util_debug
    {
        return attach_color_texture(gl, framebuffer, location);
    }

    assert(framebuffer.color_buffer_count < 31, location);
    assert(framebuffer.color_buffer_count < gl.max_framebuffer_color_attachment_count, location);

    var buffer u32;
    glGenRenderbuffers(1, buffer ref);
    glBindRenderbuffer(GL_RENDERBUFFER, buffer);

    glRenderbufferStorageMultisample(GL_RENDERBUFFER, framebuffer.sample_count, framebuffer.format, framebuffer.width, framebuffer.height);

    glBindRenderbuffer(GL_RENDERBUFFER, 0);

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + framebuffer.color_buffer_count, GL_RENDERBUFFER, buffer);

    framebuffer.color_buffer_count += 1;

    return buffer;
}

func attach_depth_stencil_texture(gl gl_api ref, framebuffer gl_framebuffer ref, depth_stencil_format u32 = GL_DEPTH_STENCIL, with_stencil = false, location = get_call_location()) (texture u32)
{
    assert(not framebuffer.depth_stencil_format, "framebuffer can only have one depth stencil attachment", location);
    var texture u32;
    glGenTextures(1, texture ref);

    if framebuffer.sample_count
    {
        glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, texture);
        glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, framebuffer.sample_count, depth_stencil_format, framebuffer.width, framebuffer.height, true cast(GLboolean));
        glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, 0);
    }
    else
    {
        glBindTexture(GL_TEXTURE_2D, texture);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        var result = gl_get_texture_color_format(depth_stencil_format);
        glTexImage2D(GL_TEXTURE_2D, 0, result.internal_color_format, framebuffer.width, framebuffer.height, 0, result.color_format, GL_FLOAT, null);
        depth_stencil_format = result.color_format;

        glBindTexture(GL_TEXTURE_2D, 0);
    }

    def attachments = [ GL_DEPTH_ATTACHMENT, GL_DEPTH_STENCIL_ATTACHMENT ] u32[];
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachments[with_stencil], GL_TEXTURE_2D, texture, 0);

    framebuffer.attachment_is_texture_mask bit_or= 1 bit_shift_left 31;
    framebuffer.depth_stencil_format = depth_stencil_format;

    return texture;
}

func attach_depth_stencil_buffer(gl gl_api ref, framebuffer gl_framebuffer ref, depth_stencil_format = GL_DEPTH24_STENCIL8, with_stencil = false, location = get_call_location()) (buffer u32)
{
    assert(not framebuffer.depth_stencil_format, "framebuffer can only have one depth stencil attachment", location);

    var buffer u32;
    glGenRenderbuffers(1, buffer ref);
    glBindRenderbuffer(GL_RENDERBUFFER, buffer);

    glRenderbufferStorageMultisample(GL_RENDERBUFFER, framebuffer.sample_count, depth_stencil_format, framebuffer.width, framebuffer.height);

    glBindRenderbuffer(GL_RENDERBUFFER, 0);

    def attachments = [ GL_DEPTH_ATTACHMENT, GL_DEPTH_STENCIL_ATTACHMENT ] u32[];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachments[with_stencil], GL_RENDERBUFFER, buffer);

    framebuffer.depth_stencil_format = depth_stencil_format;

    return buffer;
}

func bind(gl gl_api ref, framebuffer gl_framebuffer) (previous u32)
{
    return bind_framebuffer(gl, framebuffer.handle);
}

func bind_framebuffer(gl gl_api ref, framebuffer_handle u32) (previous u32)
{
    var previous = gl.draw_framebuffer_handle;
    if gl.draw_framebuffer_handle is_not framebuffer_handle
    {
        gl.draw_framebuffer_handle = framebuffer_handle;
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer_handle);
    }

    return previous;
}

func default_framebuffer_is_srgb(gl gl_api ref) (ok b8)
{
    return framebuffer_attachment_is_srgb(gl, 0, 0);
}

func framebuffer_attachment_is_srgb(gl gl_api ref, framebuffer_handle u32, color_attachment_index u32) (ok b8)
{
    assert(color_attachment_index < gl.max_framebuffer_color_attachment_count);

    var previous_framebuffer_handle = bind_framebuffer(gl, framebuffer_handle);

    var attachment = GL_COLOR_ATTACHMENT0 + color_attachment_index;

    // default framebuffer has other names for attachments
    if not framebuffer_handle
    {
        assert(color_attachment_index is 0);
        attachment = GL_FRONT_LEFT;
    }

    var result s32;
    glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment, GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING, result ref);

    bind_framebuffer(gl, previous_framebuffer_handle);

    return (result is GL_SRGB);
}

func load_wavefront_mesh(gl gl_api ref, tmemory memory_arena ref, object_name = "", attribute_enumeration_type lang_type_info, default_vertex lang_typed_value, text string) (buffer gl_vertex_buffer)
{
    var data = load_wavefront(tmemory, object_name, default_vertex, text);

    var buffer gl_vertex_buffer;
    resize_buffer(gl, buffer ref, attribute_enumeration_type, default_vertex.type, data.count, data.base);
    free(tmemory, data.base);

    return buffer;
}

func gl_load_texture(tmemory memory_arena ref, source u8[]) (texture gl_texture)
{
    var width s32;
    var height s32;
    var channel_count s32;

    // load first pixel to bottom left, not top left
    stbi_set_flip_vertically_on_load(true cast(s32));

    if not stbi_info_from_memory(source.base, source.count cast(s32), width ref, height ref, channel_count ref)
        return {} gl_texture;

    var pixels rgba8[];
    reallocate_array(tmemory, pixels ref, (width * height) cast(usize));

    // we would love to write into our buffer directly, but stb_image does not support that and uses malloc internally
    var data rgba8[];
    data.count = pixels.count;
    data.base = stbi_load_from_memory(source.base, source.count cast(s32), width ref, height ref, channel_count ref, 4);

    copy_array(pixels, data);

    stbi_image_free(data.base);

    var texture = gl_create_texture_2d(width, height, to_u8_array(pixels));

    free(tmemory, pixels.base);

    return texture;
}

struct gl_buffer
{
    handle     u32;
    byte_count u32;
}

func create_buffer(gl gl_api ref, target GLenum, count usize, base u8 ref = null) (buffer gl_buffer)
{
    assert(count);

    var buffer gl_buffer;
    buffer.byte_count = count cast(u32);

    def is_dynamic =
    [
        GL_STATIC_DRAW,
        GL_DYNAMIC_DRAW
    ] GLenum[];

    glGenBuffers(1, buffer.handle ref);
    glBindBuffer(target, buffer.handle);

    glBufferData(target, count, base, is_dynamic[base is null]);

    glBindBuffer(target, 0);

    return buffer;
}

func resize_buffer(gl gl_api ref, target GLenum, buffer gl_buffer ref, count usize, base u8 ref = null, double_byte_count_on_create = true, max_double_byte_count usize = 1 bit_shift_left 29) (was_recreated b8)
{
    if not count
        return false;

    var was_recreated = false;

    if buffer.byte_count < count
    {
        if buffer.handle
            glDeleteBuffers(1, buffer.handle ref);

        if double_byte_count_on_create
            buffer deref = create_buffer(gl, target, minimum(max_double_byte_count, count * 2), null);
        else
            buffer deref = create_buffer(gl, target, count, base);

        was_recreated = true;
    }

    if not was_recreated or double_byte_count_on_create
    {
        glBindBuffer(target, buffer.handle);
        glBufferSubData(target, 0, count, base);
        glBindBuffer(target, 0);
    }

    return was_recreated;
}

struct gl_vertex_buffer
{
    vertex_array    u32;
    vertex_buffer   u32;
    item_byte_count u32;
    vertex_count    u32;
}

func resize_buffer(gl gl_api ref, vertex_buffer gl_vertex_buffer ref, attribute_enumeration_type lang_type_info, vertex_type lang_type_info, vertex_count usize, vertices u8 ref = null)
{
    assert(attribute_enumeration_type.type_type is lang_type_info_type.enumeration);
    assert(vertex_type.type_type is lang_type_info_type.compound);

    var enumeration = attribute_enumeration_type.enumeration_type deref;

    var base_buffer gl_buffer;
    base_buffer.handle     = vertex_buffer.vertex_buffer;
    base_buffer.byte_count = vertex_buffer.vertex_count * vertex_type.byte_count cast(u32);
    var byte_count = vertex_count * vertex_type.byte_count;
    var was_recreated = resize_buffer(gl, GL_ARRAY_BUFFER, base_buffer ref, byte_count, vertices);
    
    // type may have changed
    was_recreated or= base_buffer.handle and (vertex_buffer.item_byte_count is_not vertex_type.byte_count cast(u32));

    vertex_buffer.vertex_buffer   = base_buffer.handle;
    vertex_buffer.vertex_count    = vertex_count cast(u32);
    vertex_buffer.item_byte_count = vertex_type.byte_count cast(u32);

    if was_recreated
    {
        if not vertex_buffer.vertex_array
            glGenVertexArrays(1, vertex_buffer.vertex_array ref);

        glBindVertexArray(vertex_buffer.vertex_array);
        glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer.vertex_buffer);

        def type_map =
        [
            GL_UNSIGNED_BYTE,
            GL_UNSIGNED_SHORT,
            GL_UNSIGNED_INT,
            GL_INVALID_ENUM, // there is no 64bit number type in gl

            GL_BYTE,
            GL_SHORT,
            GL_INT,
            GL_INVALID_ENUM, // there is no 64bit number type in gl

            GL_FLOAT,
            GL_DOUBLE,
        ] GLenum[];

        var used_fields_mask u32 = 0;
        var compound = vertex_type.compound_type deref;
        loop var i u32; compound.fields.count
        {
            var field = compound.fields[i];

            var item_count s32 = 1;
            var do_normalize = false;

            var number_type lang_type_info_number_type;

            switch field.type.type_type
            case lang_type_info_type.number
            {
                number_type = field.type.number_type.number_type;
            }
            case lang_type_info_type.array
            {
                var array = field.type.array_type deref;
                item_count = array.item_count cast(s32);

                assert(array.item_type.type_type is lang_type_info_type.number);
                number_type = array.item_type.number_type.number_type;
            }
            case lang_type_info_type.union
            {
                if field.type.union_type is get_type_info(rgba8).union_type
                {
                    do_normalize = true;
                    number_type = lang_type_info_number_type.u8;
                    item_count = 4;
                    break;
                }

                var union_type = field.type.union_type deref;

                // search for an array field in the union, like vec3 etc.
                var found = false;
                loop var i u32; union_type.fields.count
                {
                    if union_type.fields[i].type.type_type is lang_type_info_type.array
                    {
                        var array_type = union_type.fields[i].type.array_type deref;
                        item_count = array_type.item_count cast(s32);

                        assert(array_type.item_type.type_type is lang_type_info_type.number);
                        number_type = array_type.item_type.number_type.number_type;
                        found = true;
                        break;
                    }
                }

                assert(found);
            }
            else
            {
                assert(0);
            }

            var gl_type = type_map[number_type];

            var attribute_index = -1 cast(u32);
            loop var i u32; enumeration.items.count
            {
                if enumeration.items[i].name is field.name
                {
                    attribute_index = i;
                    break;
                }
            }

            if attribute_index is -1 cast(u32)
                continue;

            assert((used_fields_mask bit_and (1 bit_shift_left attribute_index)) is 0);
            used_fields_mask = used_fields_mask bit_or (1 bit_shift_left attribute_index);

            glEnableVertexAttribArray(attribute_index);

            if do_normalize or (number_type >= lang_type_info_number_type.f32)
                glVertexAttribPointer(attribute_index, item_count, gl_type, do_normalize cast(GLboolean), compound.byte_count cast(u32), field.byte_offset cast(u8 ref));
            else
                glVertexAttribIPointer(attribute_index, item_count, gl_type, compound.byte_count cast(u32), field.byte_offset cast(u8 ref));
        }

        glBindVertexArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
}

struct gl_index_buffer
{
    handle u32;
    count  u32;
}

func resize_buffer(gl gl_api ref, index_buffer gl_index_buffer ref, index_type lang_type_info, index_count usize, indices u8 ref = null)
{
    assert(index_type.type_type is lang_type_info_type.number);

    var base_buffer gl_buffer;
    base_buffer.handle     = index_buffer.handle;
    base_buffer.byte_count = index_buffer.count * index_type.byte_count cast(u32);
    var byte_count = index_count * index_type.byte_count;
    resize_buffer(gl, GL_ELEMENT_ARRAY_BUFFER, base_buffer ref, byte_count, indices);

    index_buffer.handle = base_buffer.handle;
    index_buffer.count  = index_count cast(u32);
}

struct gl_uniform_buffer
{
    handle          u32;
    bind_index      u32;
    item_byte_count u32;
    item_count      u32;
}

// if you want to offset into the uniform buffer, items need to be aligned a certain way
// for that tmemory is required to copy the items to an intermediate buffer with the required alignment
func resize_buffer_items(gl gl_api ref, uniform_buffer gl_uniform_buffer ref, bind_index u32, item_type lang_type_info, item_count usize = 1, data = {} u8[], tmemory memory_arena ref = null)
{
    var item_byte_count = item_type.byte_count cast(u32);
    if tmemory
        item_byte_count = aligned_uniform_buffer_item_byte_count(gl, item_type.byte_count cast(u32));

    var byte_count = item_count * item_byte_count;

    {
        var buffer gl_buffer;
        buffer.handle     = uniform_buffer.handle;
        buffer.byte_count = uniform_buffer.item_count * item_byte_count;

        if item_byte_count is_not item_type.byte_count
        {
            var temp_data u8[];

            reallocate_array(tmemory, temp_data ref, byte_count);

            loop var i usize; item_count
            {
                var to   = { item_type.byte_count, temp_data.base + (item_byte_count * i)      } u8[];
                var from = { item_type.byte_count, data.base      + (item_type.byte_count * i) } u8[];
                copy_array(to, from);
            }

            resize_buffer(gl, GL_UNIFORM_BUFFER, buffer ref, temp_data.count, temp_data.base);

            reallocate_array(tmemory, temp_data ref, 0);
        }
        else
        {
            resize_buffer(gl, GL_UNIFORM_BUFFER, buffer ref, data.count, data.base);
        }

        uniform_buffer.handle     = buffer.handle;
        uniform_buffer.item_count = buffer.byte_count / item_byte_count;
    }

    uniform_buffer.bind_index      = bind_index;
    uniform_buffer.item_count      = item_count cast(u32);
    uniform_buffer.item_byte_count = item_byte_count;
}

func resize_buffer(gl gl_api ref, uniform_buffer gl_uniform_buffer ref, bind_index u32, typed_value lang_typed_value, tmemory memory_arena ref = null)
{
    if typed_value.type.type_type is lang_type_info_type.array
    {
        var array_type = typed_value.type.array_type;
        var base_array = typed_value.base_array;

        var data u8[];
        data.count = array_type.item_type.byte_count * base_array.count;
        data.base  = base_array.base;
        resize_buffer_items(gl, uniform_buffer, bind_index, array_type.item_type, base_array.count, data, tmemory);
    }
    else
    {
        var data u8[];
        data.count = typed_value.type.byte_count;
        data.base  = typed_value.base;
        resize_buffer_items(gl, uniform_buffer, bind_index, typed_value.type, 1, data, tmemory);
    }
}

func bind_uniform_buffer(buffer gl_uniform_buffer, item_offset u32 = 0, item_count u32 = 0)
{
    if item_offset is_not 0
    {
        assert(item_offset < buffer.item_count);

        if item_count is 0
            item_count = buffer.item_count - item_offset;

        assert(item_offset + item_count <= buffer.item_count);

        glBindBufferRange(GL_UNIFORM_BUFFER, buffer.bind_index, buffer.handle, buffer.item_byte_count * item_offset, buffer.item_byte_count * item_count);
    }
    else
        glBindBufferBase(GL_UNIFORM_BUFFER, buffer.bind_index, buffer.handle);
}

func aligned_uniform_buffer_item_byte_count(gl gl_api ref, item_byte_count u32) (result u32)
{
    var alignment_mask = gl.uniform_buffer_offset_alignment - 1;
    assert((alignment_mask bit_and gl.uniform_buffer_offset_alignment) is 0); // power of 2

    item_byte_count = (item_byte_count + alignment_mask) bit_and bit_not alignment_mask;
    return item_byte_count;
}

// from GL_TEXTURE_CUBE_MAP_POSITIVE_X to GL_TEXTURE_CUBE_MAP_POSITIVE_X + 5
def gl_cubemap_face_rotations =
[
    quat_axis_angle([ 0, 0, 1 ] vec3, pi32) * quat_axis_angle([ 0, 1, 0 ] vec3, pi32 * -0.5), // gl x+ (our x+)
    quat_axis_angle([ 0, 0, 1 ] vec3, pi32) * quat_axis_angle([ 0, 1, 0 ] vec3, pi32 *  0.5), // gl x- (out x-)
    quat_axis_angle([ 1, 0, 0 ] vec3, pi32 *  0.5),                                           // gl y+ (our y+)
    quat_axis_angle([ 1, 0, 0 ] vec3, pi32 * -0.5),                                           // gl y- (our y-)
    quat_axis_angle([ 0, 0, 1 ] vec3, pi32) * quat_axis_angle([ 0, 1, 0 ] vec3, pi32),        // gl z+ (our z-)
    quat_axis_angle([ 0, 0, 1 ] vec3, pi32) * quat_axis_angle([ 0, 1, 0 ] vec3, 0),           // gl z- (our z+)
] quat[];