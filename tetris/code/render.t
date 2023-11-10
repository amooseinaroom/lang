
import math;
import gl;
import platform;
import memory;
import string;
import wavefront;

def vertex_shader_source   = import_text_file("../shaders/default.vert.glsl");
def fragment_shader_source = import_text_file("../shaders/default.frag.glsl");

def brick_mesh_source = import_text_file("../assets/brick.obj");

struct default_vertex
{
    position vec3;
    normal   vec3;
    color    rgba8;
}

struct camera_buffer
{
    world_to_clip_projection mat4;
    camera_world_position    vec4;
};

struct render_material
{
    albedo vec4;
}

def max_light_count = 8;

struct lighting_buffer
{
    parameters vec4[max_light_count];
    colors     vec4[max_light_count];
};

struct render_quad
{
    box   box2;
    color rgba8;
}

struct render_light
{
    position vec3;
    color    vec3;
}

enum uniform_buffer_binding u32
{
    camera_buffer;
    transform_buffer;
    material_buffer;
    lighting_buffer;
}

struct render_command
{
    object_to_world mat_transform;
    color           vec4;
}

struct render_api
{
    window platform_window;
    
    quads render_quad[1024];
    quad_count u32;
    
    commands      render_command[256];
    command_count u32;
    
    lights render_light[8];
    light_count u32;
    
    gl gl_api;
    
    camera_to_world mat_transform;
    world_to_camera mat_transform;
    
    default_shader default_shader_type;
    
    framebuffer                      gl_framebuffer;
    framebuffer_color_buffer         u32;
    framebuffer_depth_stencil_buffer u32;
    
    camera_buffer    gl_uniform_buffer;
    transform_buffer gl_uniform_buffer;
    lighting_buffer  gl_uniform_buffer;
    material_buffer  gl_uniform_buffer;
    
    quad_buffer gl_vertex_buffer;
    brick_mesh  gl_vertex_buffer;
}

enum vertex_attribute u32
{
    position;
    normal;
    color;
}

func init(renderer render_api ref, platform platform_api ref, tmemory memory_arena ref)
{
    gl_init(renderer.gl ref, platform);
    
    platform_window_init(platform, renderer.window ref, "tetris", 1280, 720);
    gl_window_init(platform, renderer.gl ref, renderer.window ref);
    
    renderer.framebuffer = create_framebuffer_begin(renderer.gl ref, 1280, 720, GL_SRGB, 2);
    renderer.framebuffer_color_buffer         = attach_color_buffer(renderer.gl ref, renderer.framebuffer ref);
    renderer.framebuffer_depth_stencil_buffer = attach_depth_stencil_buffer(renderer.gl ref, renderer.framebuffer ref);
    require(create_framebuffer_end(renderer.gl ref, renderer.framebuffer ref));
    
    reload_shader(renderer.gl ref, renderer.default_shader, "default", get_type_info(vertex_attribute), get_type_info(uniform_buffer_binding), vertex_shader_source, false, fragment_shader_source);
    
    {
        var vertex default_vertex;
        vertex.color = [ 255, 255, 255, 255 ] rgba8;
        renderer.brick_mesh = load_wavefront_mesh(renderer.gl ref, tmemory, get_type_info(vertex_attribute), vertex, brick_mesh_source);
    }
    
    //renderer.quad_buffer = gl_create_vertex_buffer(get_type_info(vertex_attribute), get_type_info(default_vertex), 6 * renderer.quads.count);
    resize_buffer(renderer.gl ref, renderer.quad_buffer ref, get_type_info(vertex_attribute), get_type_info(default_vertex), 6 * renderer.quads.count);
    
    renderer.camera_to_world = mat4_camera_to_world_look_at([ 4.5, 12, 50 ] vec3, [ 4.5, 12, 0 ] vec3, [ 0, 1, 0 ] vec3);
    renderer.world_to_camera = mat4_inverse_transform_unscaled(renderer.camera_to_world);
}

func present(platform platform_api ref, renderer render_api ref, jiggle f32, tmemory memory_arena ref) (window_size vec2s)
{
    var gl = renderer.gl ref;
    
    var window_size = renderer.window.size;
    var window_width_over_height = window_size.x cast(f32) / window_size.y;
    
    //var camera_to_clip = mat4_perspective_projection_fov(pi32 * 0.4, window_width_over_height);
    var camera_to_clip = mat4_perspective_projection_fov(0.6, window_width_over_height);

    resize_framebuffer(renderer.gl ref, renderer.framebuffer ref, window_size.x, window_size.y, [ renderer.framebuffer_color_buffer ] u32[], renderer.framebuffer_depth_stencil_buffer);

    var vertices default_vertex[renderer.quads.count * 6];
    var vertex_count;
    
    loop var i; renderer.quad_count
    {
        var quad = renderer.quads[i];        
        
        var box box2 = quad.box;
        var min = box.min;
        var max = box.max;
        
        assert(vertex_count + 6 <= vertices.count);
        var quad_vertices = (vertices.base + vertex_count) cast(default_vertex[6] ref);
        vertex_count = vertex_count + 6;
        
        // 1st triangle
        
        var normal = [ 0, 0, 1 ] vec3;
        var depth = -10;
        
        quad_vertices[0].color = quad.color;
        quad_vertices[0].normal = normal;
        quad_vertices[0].position[0] = min[0];
        quad_vertices[0].position[1] = min[1];
        quad_vertices[0].position[2] = depth;
        
        quad_vertices[1].color = quad.color;
        quad_vertices[1].normal = normal;
        quad_vertices[1].position[0] = max[0];
        quad_vertices[1].position[1] = min[1];
        quad_vertices[1].position[2] = depth;
        
        quad_vertices[2].color = quad.color;
        quad_vertices[2].normal = normal;
        quad_vertices[2].position[0] = max[0];
        quad_vertices[2].position[1] = max[1];
        quad_vertices[2].position[2] = depth;
        
        // 2nd triangle
        
        quad_vertices[3] = quad_vertices[0];
        quad_vertices[4] = quad_vertices[2];
        
        quad_vertices[5].color = quad.color;
        quad_vertices[5].normal = normal;
        quad_vertices[5].position[0] = min[0];
        quad_vertices[5].position[1] = max[1];
        quad_vertices[5].position[2] = depth;
    }
    
    // upload
    
    glBindBuffer(GL_ARRAY_BUFFER, renderer.quad_buffer.vertex_buffer);
    glBufferSubData(GL_ARRAY_BUFFER, 0, type_byte_count(default_vertex) * vertex_count, vertices.base);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    var jiggle_transform = mat4_transform(quat_axis_angle([ 0, 1, 0 ] vec3, 0)); //jiggle)); makes you sick :(
    var world_to_camera = mat4_inverse_transform_unscaled(jiggle_transform * renderer.camera_to_world );
    
    {
        var camera camera_buffer;
        camera.camera_world_position    = renderer.camera_to_world[3];
        camera.world_to_clip_projection = camera_to_clip * world_to_camera;
        resize_buffer(gl, renderer.camera_buffer ref, uniform_buffer_binding.camera_buffer, camera);
    }
    
    {
        var transforms mat_transform[];
        var colors     vec4[];
        
        reallocate_array(tmemory, transforms ref, renderer.command_count);
        reallocate_array(tmemory, colors ref,     renderer.command_count);
    
        loop var i; renderer.command_count
        {
            transforms[i] = renderer.commands[i].object_to_world;
            colors[i]     = renderer.commands[i].color;
        }
        
        resize_buffer(gl, renderer.transform_buffer ref, uniform_buffer_binding.transform_buffer, transforms, tmemory);
        resize_buffer(gl, renderer.material_buffer ref,  uniform_buffer_binding.material_buffer,  colors,     tmemory);
        
        reallocate_array(tmemory, colors ref,     0);
        reallocate_array(tmemory, transforms ref, 0);
    }
    
    {
        var lighting lighting_buffer;
        loop var i; renderer.light_count
        {
            lighting.parameters[i] = vec4_expand(renderer.lights[i].position);
            lighting.colors[i]     = vec4_expand(renderer.lights[i].color);
        }
        
        resize_buffer(gl, renderer.lighting_buffer ref, uniform_buffer_binding.lighting_buffer, lighting);
    }
    
    // render
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, renderer.framebuffer.handle);
    
    glEnable(GL_FRAMEBUFFER_SRGB);

    glViewport(0, 0, window_size.x cast(u32), window_size.y cast(u32));
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT bit_or GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    glUseProgram(renderer.default_shader.handle);
    
    glVertexAttrib3f(vertex_attribute.normal, 1, 0, 0);
    glVertexAttrib4f(vertex_attribute.color, 1, 1, 1, 1);
    
    bind_uniform_buffer(renderer.camera_buffer);
    bind_uniform_buffer(renderer.transform_buffer);
    bind_uniform_buffer(renderer.lighting_buffer);
    bind_uniform_buffer(renderer.material_buffer);
    
    if (0)
    {
        glBindVertexArray(renderer.quad_buffer.vertex_array);
        glDrawArrays(GL_TRIANGLES, 0, vertex_count);
    }
    
    {
        glBindVertexArray(renderer.brick_mesh.vertex_array);
        //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, renderer.brick_mesh.index_buffer);
        
        loop var i = 1; renderer.command_count
        {
            bind_uniform_buffer(renderer.transform_buffer, i);
            bind_uniform_buffer(renderer.material_buffer, i);
            
            //glDrawElements(GL_TRIANGLES, renderer.brick_mesh.index_count, GL_UNSIGNED_INT, null);
            glDrawArrays(GL_TRIANGLES, 0, renderer.brick_mesh.vertex_count);
        }
        
        //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
    
    glBindVertexArray(0);
    glUseProgram(0);
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER, renderer.framebuffer.handle);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glBlitFramebuffer(0, 0, window_size.x, window_size.y, 0, 0, window_size.x, window_size.y, GL_COLOR_BUFFER_BIT bit_or GL_DEPTH_BUFFER_BIT, GL_NEAREST); 
    
    renderer.quad_count  = 0;
    renderer.light_count = 0;
    renderer.command_count = 0;
    
    push_command(renderer, mat4_identity, [ 1, 1, 1, 1 ] vec4);
    
    return window_size;
}

func push_command(renderer render_api ref, object_to_world mat_transform, color vec4, location = get_call_location())
{
    assert(renderer.command_count < renderer.commands.count, location);
    var command = renderer.commands[renderer.command_count] ref;
    renderer.command_count = renderer.command_count + 1;
    command.object_to_world = object_to_world;
    command.color           = color;
}

func push_quad(renderer render_api ref, box box2, color rgba8, location = get_call_location())
{
    assert(renderer.quad_count < renderer.quads.count, location);
    renderer.quads[renderer.quad_count].box   = box;
    renderer.quads[renderer.quad_count].color = color;
    renderer.quad_count = renderer.quad_count + 1;
}

func push_light(renderer render_api ref, position vec3, color vec3, location = get_call_location())
{
    assert(renderer.light_count < renderer.lights.count, location);
    renderer.lights[renderer.light_count].position = position;
    renderer.lights[renderer.light_count].color    = color;
    renderer.light_count = renderer.light_count + 1;
}

struct default_shader_type
{
    handle u32;
}