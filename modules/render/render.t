import stb_image;
import math;
import gl;
import tk_format;

struct render_system
{
    camera_uniform_buffer    gl_uniform_buffer;
    transform_uniform_buffer gl_uniform_buffer;
    shadow_uniform_buffer    gl_uniform_buffer;
    lighting_uniform_buffer  gl_uniform_buffer;
    material_uniform_buffer  gl_uniform_buffer;
    sky_uniform_buffer       gl_uniform_buffer;

    default_shader                       render_shader;
    default_hdr_shader                   render_shader;
    debug_reflection_probe_shader        render_shader;
    environment_to_irradiance_map_shader render_environment_to_irradiance_map_shader;
    pbr_intgrate_brdf_shader             render_pbr_intgrate_brdf_shader;
    pbr_prefilter_environment_shader     render_pbr_prefilter_environment_shader;
    equirectangular_to_cube_map_shader   render_equirectangular_to_cube_map_shader;
    sky_shader                           render_sky_shader;

    lighting    render_lighting_buffer;
    light_count u32;

    shadow     render_shadow_buffer;
    shadow_map gl_texture;

    reflection_probe_framebuffer struct
    {
        framebuffer  gl_framebuffer;
        depth_buffer u32;
    };

    white_texture      gl_texture;
    default_normal_map gl_texture;

    integrated_brdf_environment_map gl_texture;

    buffer render_buffer;

    empty_mesh render_mesh;

    default_framebuffer gl_framebuffer_color_and_depth;

    sun_time f32;
}

struct render_smaa
{
    edge_detection_shader render_shader_smaa_edge_detection;

    edge_framebuffer         gl_framebuffer_color_and_depth;
    blend_weight_framebuffer gl_framebuffer_color_and_depth;

    metrics vec4;
}

func reload(smaa render_smaa ref, gl gl_api ref, tmemory memory_arena ref)
{
multiline_comment
{
    var result = reload_shader(gl, smaa.edge_detection_shader ref, "smaa edge detection", get_type_info(render_vertex_attribute), get_type_info(render_uniform_buffer_binding),
    shader_source_vertex_smaa_config, shader_source_basic_smaa, shader_source_vertex_smaa_edge_detection, false,
    shader_source_fragment_smaa_config, shader_source_basic_smaa, shader_source_fragment_smaa_edge_detection, tmemory);

    if not result.ok
        print(result.error_messages);
}



}

func resize(smaa render_smaa ref, framebuffer_size vec2s, gl gl_api ref)
{
    if not smaa.edge_framebuffer.handle
    {
        smaa.edge_framebuffer.base = create_framebuffer_begin(gl, framebuffer_size.width, framebuffer_size.height, GL_RG);
        smaa.edge_framebuffer.color_buffer         = attach_color_buffer(gl, smaa.edge_framebuffer.base ref);
        smaa.edge_framebuffer.depth_stencil_buffer = attach_depth_stencil_buffer(gl, smaa.edge_framebuffer.base ref);
        create_framebuffer_end(gl, smaa.edge_framebuffer.base ref);
    }

    resize_framebuffer(gl, smaa.edge_framebuffer.base ref, framebuffer_size.width, framebuffer_size.height, { 1, smaa.edge_framebuffer.color_buffer ref } u32[], smaa.edge_framebuffer.depth_stencil_buffer);

    smaa.metrics = [ 1.0 / framebuffer_size.width, 1.0 / framebuffer_size.height, framebuffer_size.width, framebuffer_size.height ] vec4;
}

enum render_vertex_attribute
{
    position;
    normal;
    tangent;
    uv;
    color;
    blend_weights;
    blend_indices;
}

enum render_uniform_buffer_binding
{
    camera_buffer;
    transform_buffer;
    lighting_buffer;
    shadow_buffer;
    material_buffer;
    sky_buffer;
    bloom_buffer;
    sphere_buffer;
}

struct render_camera_buffer
{
    world_to_clip_projection mat4;
    clip_to_world_projection mat4;
    camera_world_position    vec3;
    near f32;
    far  f32;
}

struct render_sky_buffer
{
    top_color     vec4;
    middle_color  vec4;
    bottom_color  vec4;
    sun_direction vec4;
}

def render_max_light_count = 8;

struct render_light
{
    parameters vec4;
    color_and_attenuation vec4;
}

struct render_lighting_buffer
{
    lights render_light[render_max_light_count];
}

struct render_shadow_buffer
{
    world_to_shadow_projection mat4;
    shadow_light_index         u32;
}

struct render_material
{
    albedo   vec4;

    roughness f32;
    metallic  f32;
    user_vec2 vec2;

    emission vec3;
    user_f32 f32;
};

struct render_mesh
{
    vertex_buffer gl_vertex_buffer;
    index_buffer  gl_index_buffer;
}

struct render_mesh_static_scene
{
    expand base render_mesh;

    draw_commands render_mesh_draw_command[];
}

struct render_mesh_draw_command
{
    mesh_to_node      mat_transform;
    bounding_box      box3; // transformed
    gl_primitive_type u32;
    vertex_offset     u32;
    vertex_count      u32;
}

struct render_mesh_animated
{
    expand base render_mesh;

    nodes tk_mesh_animation_nodes;
}

struct render_reflection_probe
{
    environment_map             gl_texture_cube;
    irradiance_map              gl_texture_cube;
    prefiltered_environment_map gl_texture_cube;
    position vec3;
    mip_map_level_count u32;
}

struct render_shader
{
    handle u32;

    albedo_map                      s32;
    normal_map                      s32;
    shadow_map                      s32;
    material_map                    s32;
    irradiance_map                  s32;
    prefiltered_environment_map     s32;
    integrated_brdf_environment_map s32;

    // need to rework reload_shader in gl_util to make this work
    multiline_comment
    {
    expand tag union
    {
        expand names render_shader_uniforms;

        uniforms s32[6];
    };
    }
}

// we separate this out to make it easier to iterate over the type info
struct render_shader_uniforms
{
    albedo_map                      s32;
    normal_map                      s32;
    material_map                    s32;
    irradiance_map                  s32;
    prefiltered_environment_map     s32;
    integrated_brdf_environment_map s32;
}

struct render_environment_to_irradiance_map_shader
{
    handle          u32;

    clip_to_world_projection s32;
    environment_map          s32;
}

struct render_pbr_intgrate_brdf_shader
{
    handle u32;
}

struct render_equirectangular_to_cube_map_shader
{
    handle u32;

    clip_to_world_projection s32;
    equirectangular_map      s32;
}

struct render_pbr_prefilter_environment_shader
{
    handle u32;

    clip_to_world_projection s32;
    environment_map s32;
    roughness       s32;
}

struct render_shader_smaa_edge_detection
{
    handle u32;

    metrics   s32;
    color_map s32;
}

struct render_sky_shader
{
    handle u32;

    clip_to_world_projection s32;
}

def shader_source_fragment_debug_reflection_probe        = import_text_file("shaders/debug_reflection_probe.frag.glsl");
def shader_source_fragment_default                       = import_text_file("shaders/default.frag.glsl");
def shader_source_vertex_default                         = import_text_file("shaders/default.vert.glsl");
def shader_source_vertex_default_animated                = import_text_file("shaders/default_animated.vert.glsl");
def shader_source_fragment_environment_to_irradiance_map = import_text_file("shaders/environment_to_irradiance_map.frag.glsl");
def shader_source_fragment_equirectangular_to_cube_face  = import_text_file("shaders/equirectangular_to_cube_face.frag.glsl");
def shader_source_vertex_fill_viewport                   = import_text_file("shaders/fill_viewport.vert.glsl");
def shader_source_pbr                                    = import_text_file("shaders/pbr.glsl");
def shader_source_fragment_pbr_integrate_brdf            = import_text_file("shaders/pbr_integrate_brdf.frag.glsl");
def shader_source_fragment_pbr_prefilter_environment     = import_text_file("shaders/pbr_prefilter_environment.frag.glsl");
def shader_source_fragment_sky                           = import_text_file("shaders/sky.frag.glsl");
def shader_source_basic                                  = import_text_file("shaders/basic.glsl");

// def shader_source_basic_smaa           = import_text_file("shaders/smaa/smaa.hlsl");
// def shader_source_vertex_smaa_config   = import_text_file("shaders/smaa/smaa_config.vert.glsl");
// def shader_source_fragment_smaa_config = import_text_file("shaders/smaa/smaa_config.frag.glsl");

// def shader_source_vertex_smaa_edge_detection   = import_text_file("shaders/smaa/smaa_edge_detection.vert.glsl");
// def shader_source_fragment_smaa_edge_detection = import_text_file("shaders/smaa/smaa_edge_detection.frag.glsl");

// def shader_source_vertex_smaa_blend_weight_calculation   = import_text_file("shaders/smaa/smaa_blend_weight_calculation.vert.glsl");
// def shader_source_fragment_smaa_blend_weight_calculation = import_text_file("shaders/smaa/smaa_blend_weight_calculation.frag.glsl");

// def shader_source_vertex_smaa_neighborhood_blending   = import_text_file("shaders/smaa/smaa_neighborhood_blending.vert.glsl");
// def shader_source_fragment_smaa_neighborhood_blending = import_text_file("shaders/smaa/smaa_neighborhood_blending.frag.glsl");

func frame(render render_system ref, gl gl_api ref, window_size vec2s)
{
    if not render.default_framebuffer.handle
    {
        var framebuffer = render.default_framebuffer ref;
        framebuffer.base = create_framebuffer_begin(gl, window_size.width, window_size.height);
        framebuffer.color_buffer         = attach_color_texture(gl, framebuffer.base ref);
        framebuffer.depth_stencil_buffer = attach_depth_stencil_texture(gl, framebuffer.base ref);

        require(create_framebuffer_end(gl, framebuffer.base ref));
    }

    resize_framebuffer(gl, render.default_framebuffer.base ref, window_size.width, window_size.height, { 1, render.default_framebuffer.color_buffer ref } u32[], render.default_framebuffer.depth_stencil_buffer);
}

func reload(render render_system ref, platform platform_api ref, gl gl_api ref, tmemory memory_arena ref)
{
    if not render.reflection_probe_framebuffer.framebuffer.handle
    {
        var framebuffer = create_framebuffer_begin(gl, 512, 512, GL_RGB);
        enable_color_texture(gl, framebuffer ref, 0);
        var depth_buffer = attach_depth_stencil_buffer(gl, framebuffer ref);
        var ok = create_framebuffer_end(gl, framebuffer ref);
        assert(ok);

        render.reflection_probe_framebuffer.framebuffer = framebuffer;
        render.reflection_probe_framebuffer.depth_buffer = depth_buffer;
    }

    reload_shader(render.default_shader ref, "default", platform, gl,
        shader_source_basic,
        shader_source_vertex_default_animated,
        //shader_source_default,
        false,
        shader_source_basic,
        shader_source_pbr,
        shader_source_fragment_default,
        tmemory);

    reload_shader(render.default_hdr_shader ref, "default hdr", platform, gl, true, true,
        shader_source_basic,
        //shader_source_default_animated,
        shader_source_vertex_default,
        false,
        shader_source_basic,
        shader_source_pbr,
        shader_source_fragment_default,
        tmemory);

    reload_shader(render.debug_reflection_probe_shader ref, "debug reflection probe", platform, gl,
        shader_source_basic,
        shader_source_vertex_default,
        false,
        shader_source_basic,
        shader_source_fragment_debug_reflection_probe,
        tmemory);

    reload_shader(render.environment_to_irradiance_map_shader ref, "environment to irradiance map", platform, gl, false,
        shader_source_vertex_fill_viewport,
        false,
        shader_source_fragment_environment_to_irradiance_map,
        tmemory);

    reload_shader(render.pbr_intgrate_brdf_shader ref, "pbr intgrate brdf", platform, gl, false,
        shader_source_vertex_fill_viewport,
        false,
        shader_source_fragment_pbr_integrate_brdf,
        tmemory);

    reload_shader(render.pbr_prefilter_environment_shader ref, "pbr prefilter environment", platform, gl, false,
        shader_source_vertex_fill_viewport,
        false,
        shader_source_fragment_pbr_prefilter_environment,
        tmemory);

    reload_shader(render.equirectangular_to_cube_map_shader ref, "equirectangular to cube map", platform, gl, false, true,
        shader_source_vertex_fill_viewport,
        false,
        shader_source_fragment_equirectangular_to_cube_face,
        tmemory);

    reload_shader(render.sky_shader ref, "sky", platform, gl, false,
        shader_source_vertex_fill_viewport,
        false,
        shader_source_fragment_sky,
        tmemory);

    if not render.empty_mesh.vertex_buffer.vertex_array
    {
        glGenVertexArrays(1, render.empty_mesh.vertex_buffer.vertex_array ref);

        render.empty_mesh.vertex_buffer.vertex_count = 3;
    }

    if not render.white_texture.handle
    {
       render.white_texture = gl_create_texture_2d(1, 1, value_to_u8_array(rgba8_white), GL_RGBA);
    }

    if not render.default_normal_map.handle
    {
       // we push rgba8 since we have a converted and gl want's pixels to be 4 byte aligned per row
       // common normal maps use z as up, while we typically use y as up, but the shaders will fix this
       var up_color = to_rgba8(vec4_expand([ 0, 0, 1 ] vec3 * 0.5 + 0.5, 1));
       render.default_normal_map = gl_create_texture_2d(1, 1, value_to_u8_array(up_color), GL_RGB);
    }

    multiline_comment
    {
        var data = platform_read_entire_file(platform, tmemory, "assets/textures/newport_loft.hdr");

        stbi_set_flip_vertically_on_load(1);

        var probe = render.reflection_probe2 ref;

        var width s32;
        var height s32;
        var channel_count s32;
        var pixels = stbi_loadf_from_memory(data.base, data.count cast(s32), width ref, height ref, channel_count ref, 3);

        //if (state.render_probe2.environment_map)

        var texture = gl_create_texture_2d(width, height, true, { (width * height) cast(usize) * 3 * 4, pixels cast(u8 ref) } u8[], GL_RGB32F, GL_FLOAT);

        {
            var camera_to_clip = mat4_perspective_projection_fov(pi32 * 0.5, 1);
            var clip_to_camera = mat4_inverse_perspective_projection(camera_to_clip);

            var framebuffer = render.reflection_probe_framebuffer ref;

            assert(probe.environment_map.width <= framebuffer.framebuffer.width);
            assert(probe.environment_map.height <= framebuffer.framebuffer.height);
            bind(gl, framebuffer.framebuffer);

            glDisable(GL_DEPTH_TEST);
            glDisable(GL_BLEND);

            glViewport(0, 0, probe.environment_map.width, probe.environment_map.height);

            glUseProgram(render.equirectangular_to_cube_map_shader.handle);
            glUniform1i(render.equirectangular_to_cube_map_shader.equirectangular_map, 0);

            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, texture.handle);

            glBindVertexArray(render.empty_vertex_array);

            loop var i u32; 6
            {
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, probe.environment_map.handle, 0);

                glClear(GL_COLOR_BUFFER_BIT);

                var camera_to_world = mat4_transform(gl_cubemap_face_rotations[i], probe.position);

                var world_to_clip = camera_to_clip * mat4_inverse_transform_unscaled(camera_to_world);
                var clip_to_world = camera_to_world * clip_to_camera;

                glUniformMatrix4fv(render.equirectangular_to_cube_map_shader.clip_to_world_projection, 1, GL_FALSE, clip_to_world.values.base);

                glDrawArrays(GL_TRIANGLES, 0, 3);
            }

            glBindVertexArray(0);

            glUseProgram(0);

            bind_framebuffer(gl, 0);

            glDeleteTextures(1, texture.handle ref);
        }

        free(tmemory, data.base);

        update_reflection_probe(render, gl, probe);
    }

    if not render.integrated_brdf_environment_map.handle
    {
        render.integrated_brdf_environment_map = gl_create_texture_2d(512, 512, {} u8[], GL_RG);

        glViewport(0, 0, render.integrated_brdf_environment_map.width, render.integrated_brdf_environment_map.height);

        bind(gl, render.reflection_probe_framebuffer.framebuffer);

        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, render.integrated_brdf_environment_map.handle, 0);

        glUseProgram(render.pbr_intgrate_brdf_shader.handle);

        glBindVertexArray(render.empty_mesh.vertex_buffer.vertex_array);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glBindVertexArray(0);

        glUseProgram(0);

        bind_framebuffer(gl, 0);
    }

    if not render.shadow_map.handle
    {
       render.shadow_map = gl_create_texture_2d(2048, 2048, {} u8[], GL_DEPTH_COMPONENT);
       glBindTexture(GL_TEXTURE_2D, render.shadow_map.handle);
       glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_REF_TO_TEXTURE);

       glBindTexture(GL_TEXTURE_2D, 0);
    }
}

func reload_shader(shader lang_typed_value, name string, platform platform_api ref, gl gl_api ref, add_version = true, is_hdr = false, expand vertex_files string[], separator b8, expand fragment_files string[], tmemory memory_arena ref) (ok b8, error_messages string)
{
    var vertex_sources string[];
    reallocate_array(tmemory, vertex_sources ref, vertex_files.count + 1);

    var fragment_sources string[];
    reallocate_array(tmemory, fragment_sources ref, fragment_files.count + 1);

    var version_string string;
    if is_hdr
        version_string = "#version 330\n#define max_light_count 8\n#define is_hdr 1\n#define prefiltered_environment_map_max_lod 9\n";
    else
        version_string = "#version 330\n#define max_light_count 8\n#define is_hdr 0\n#define prefiltered_environment_map_max_lod 9\n";

    if add_version
        vertex_sources[0] = version_string;
    else
        vertex_sources[0] = "";

    loop var i; vertex_files.count
        vertex_sources[i + 1] = vertex_files[i]; // platform_read_entire_file(platform, tmemory, vertex_files[i]);

    if add_version
        fragment_sources[0] = version_string;
    else
        fragment_sources[0] = "";

    loop var i; fragment_files.count
        fragment_sources[i + 1] = fragment_files[i]; // platform_read_entire_file(platform, tmemory, fragment_files[i]);

    var result = reload_shader(gl, shader, name, get_type_info(render_vertex_attribute), get_type_info(render_uniform_buffer_binding), vertex_sources, false,
    fragment_sources, tmemory);

    if not result.ok
        print(result.error_messages);

    return result;
}

func init(probe render_reflection_probe ref, render render_system ref, gl gl_api ref)
{
    probe.mip_map_level_count = 9;
    probe.environment_map = gl_create_texture_cube(1 bit_shift_left probe.mip_map_level_count, 1 bit_shift_left probe.mip_map_level_count, GL_RGB16F);
    probe.prefiltered_environment_map = gl_create_texture_cube(probe.environment_map.width, probe.environment_map.height, GL_RGB16F);

    probe.irradiance_map = gl_create_texture_cube(32, 32, GL_RGB16F);

    glBindTexture(GL_TEXTURE_CUBE_MAP, probe.environment_map.handle);
    //glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
    //glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

    glBindTexture(GL_TEXTURE_CUBE_MAP, probe.prefiltered_environment_map.handle);
    glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

    //glBindTexture(GL_TEXTURE_CUBE_MAP, probe.irradiance_map.handle);
    //glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
    //glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
}

func push_light_point(render render_system ref, position vec3, color vec3, attenuation = 1.0)
{
    assert(render.light_count < render.lighting.lights.count);
    var light = render.lighting.lights[render.light_count] ref;
    render.light_count += 1;

    light.parameters.xyz = position;
    light.parameters.w = 1.0; // is point light
    light.color_and_attenuation.xyz = color;
    light.color_and_attenuation.w   = attenuation;
}

func push_light_direction(render render_system ref, direction vec3, color vec3)
{
    assert(render.light_count < render.lighting.lights.count);
    var light = render.lighting.lights[render.light_count] ref;
    render.light_count += 1;

    light.parameters.xyz = direction;
    light.parameters.w = 0.0; // is directional ligtht
    light.color_and_attenuation.xyz = color;
    light.color_and_attenuation.w   = 0;
}

struct render_shader_override
{
    from_shader_handle u32;
    to_shader_handle   u32;
}

func capture(render render_system ref, gl gl_api ref, probe render_reflection_probe ref, buffer render_buffer ref, tmemory memory_arena ref, face_start = 0, face_count = 6, expand shader_overrides = {} render_shader_override[])
{
    assert(probe.environment_map.handle);

    var camera_to_clip = mat4_perspective_projection_fov(pi32 * 0.5, 1);
    var clip_to_camera = mat4_inverse_perspective_projection(camera_to_clip);

    bind(gl, render.reflection_probe_framebuffer.framebuffer);

    upload_buffers(render, gl, buffer, tmemory);

    glDisable(GL_FRAMEBUFFER_SRGB);
    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    //glFrontFace(GL_CCW);
    glEnable(GL_CULL_FACE);
    //glCullFace()

    glViewport(0, 0, probe.environment_map.width, probe.environment_map.height);

    loop var i u32; shader_overrides.count
    {
        loop var shader_index u32; buffer.shader_count
        {
            assert(buffer.shader_handles[shader_index] deref is_not shader_overrides[i].to_shader_handle);

            if buffer.shader_handles[shader_index] deref is shader_overrides[i].from_shader_handle
                buffer.shader_handles[shader_index] deref = shader_overrides[i].to_shader_handle;
        }
    }

    loop var i = face_start; face_start + face_count
    {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, probe.environment_map.handle, 0);

        glClear(GL_COLOR_BUFFER_BIT bit_or GL_DEPTH_BUFFER_BIT);

        var camera_to_world = mat4_transform(gl_cubemap_face_rotations[i], probe.position);

        var world_to_clip = camera_to_clip * mat4_inverse_transform_unscaled(camera_to_world);
        var clip_to_world = camera_to_world * clip_to_camera;

        var light_count = render.light_count;
        execute(render, gl, buffer, camera_to_world, world_to_clip, clip_to_world);
        render.light_count = light_count;
    }

    loop var i u32; shader_overrides.count
    {
        loop var shader_index u32; buffer.shader_count
        {
            assert(buffer.shader_handles[shader_index] deref is_not shader_overrides[i].from_shader_handle);

            if buffer.shader_handles[shader_index] deref is shader_overrides[i].to_shader_handle
                buffer.shader_handles[shader_index] deref = shader_overrides[i].from_shader_handle;
        }
    }

    bind_framebuffer(gl, 0);
}

func update_reflection_probe(render render_system ref, gl gl_api ref, probe render_reflection_probe ref, update_state u32 ref = null)
{
    assert(probe.environment_map.handle);

    bind(gl, render.reflection_probe_framebuffer.framebuffer);

    var camera_to_clip = mat4_perspective_projection_fov(pi32 * 0.5, 1);
    var clip_to_camera = mat4_inverse_perspective_projection(camera_to_clip);

    var first_face_index = 0;
    var face_count = 6;
    var update_irradiance_map = true;
    var update_prefilter_environment_map = true;

    if update_state
    {
       var state = update_state deref;
       update_prefilter_environment_map = state bit_and 1;
       update_irradiance_map            = not update_prefilter_environment_map;
       first_face_index = state / 2;
       face_count = 1;

       update_state deref = (update_state deref + 1) mod 12;
    }

    if update_irradiance_map
    {
        glDisable(GL_DEPTH_TEST);

        glViewport(0, 0, probe.irradiance_map.width, probe.irradiance_map.height);

        glUseProgram(render.environment_to_irradiance_map_shader.handle);
        glUniform1i(render.environment_to_irradiance_map_shader.environment_map, 0);

        glActiveTexture(GL_TEXTURE0 + 0);
        glBindTexture(GL_TEXTURE_CUBE_MAP, probe.environment_map.handle);

        glBindVertexArray(render.empty_mesh.vertex_buffer.vertex_array);

        loop var i = first_face_index; first_face_index + face_count
        {
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, probe.irradiance_map.handle, 0);

            glClear(GL_COLOR_BUFFER_BIT);

            var camera_to_world = mat4_transform(gl_cubemap_face_rotations[i]);
            var clip_to_world = camera_to_world * clip_to_camera;

            glUniformMatrix4fv(render.environment_to_irradiance_map_shader.clip_to_world_projection, 1, GL_FALSE, clip_to_world.values.base);

            glDrawArrays(GL_TRIANGLES, 0, 3);
        }

        glBindVertexArray(0);

        glUseProgram(0);
    }

    if update_prefilter_environment_map
    {
        glDisable(GL_DEPTH_TEST);

        glUseProgram(render.pbr_prefilter_environment_shader.handle);
        glUniform1i(render.pbr_prefilter_environment_shader.environment_map, 0);

        glActiveTexture(GL_TEXTURE0 + 0);
        glBindTexture(GL_TEXTURE_CUBE_MAP, probe.environment_map.handle);

        glBindVertexArray(render.empty_mesh.vertex_buffer.vertex_array);

        loop var level u32; probe.mip_map_level_count + 1
        {
            glViewport(0, 0, probe.prefiltered_environment_map.width bit_shift_right level, probe.prefiltered_environment_map.height bit_shift_right level);

            var roughness = level cast(f32) / probe.mip_map_level_count;
            glUniform1f(render.pbr_prefilter_environment_shader.roughness, roughness);

            loop var i = first_face_index; first_face_index + face_count
            {
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, probe.prefiltered_environment_map.handle, level);

                glClear(GL_COLOR_BUFFER_BIT);

                var camera_to_world = mat4_transform(gl_cubemap_face_rotations[i]);
                var clip_to_world = camera_to_world * clip_to_camera;

                glUniformMatrix4fv(render.pbr_prefilter_environment_shader.clip_to_world_projection, 1, GL_FALSE, clip_to_world.values.base);

                glDrawArrays(GL_TRIANGLES, 0, 3);
            }
        }

        glBindVertexArray(0);

        glUseProgram(0);
    }

    bind_framebuffer(gl, 0);
}

func capture_shadow(render render_system ref, gl gl_api ref, light_to_world mat4, world_to_clip mat4, clip_to_world mat4, shadow_texture gl_texture, buffer render_buffer ref, tmemory memory_arena ref,
shadow_shader_handle u32 ref, first_pass_index u32 = 0, pass_count u32 = u32_invalid_index) (world_to_shadow mat4)
{
    // same as in execute, but we need pass_count
    assert(first_pass_index < buffer.pass_count);

    if pass_count is u32_invalid_index
        pass_count = buffer.pass_count - first_pass_index;

    //var camera_to_clip = mat4_perspective_projection_fov(pi32 * 0.5, 1);
    //var clip_to_camera = mat4_inverse_perspective_projection(camera_to_clip);

    var tmemory_scope = temporary_begin(tmemory);

    upload_buffers(render, gl, buffer, tmemory);

    //glDisable(GL_FRAMEBUFFER_SRGB);
    //glDisable(GL_BLEND);
    //glEnable(GL_DEPTH_TEST);
    //glFrontFace(GL_CCW);
    //glEnable(GL_CULL_FACE);
    //glCullFace()

    ///glViewport(0, 0, shadow_texture.width, shadow_texture.height);

    var shader_handles u32 ref[];
    reallocate_array(tmemory, shader_handles ref, buffer.shader_count);

    loop var shader_index u32; buffer.shader_count
    {
        shader_handles[shader_index] = buffer.shader_handles[shader_index];
        buffer.shader_handles[shader_index] = shadow_shader_handle;
    }

    var passes render_pass[];
    reallocate_array(tmemory, passes ref, pass_count);

    var shadow_pass render_pass;
    shadow_pass.framebuffer_handle = render.reflection_probe_framebuffer.framebuffer.handle;
    shadow_pass.framebuffer_size   = { shadow_texture.width, shadow_texture.height } vec2s;
    shadow_pass.enable_clear_depth = true;
    shadow_pass.clear_depth = 1;

    loop var i u32; pass_count
    {
        passes[i] = buffer.passes[first_pass_index + i];
        buffer.passes[first_pass_index + i] = shadow_pass;
    }

    //loop var i = face_start; face_start + face_count
    {
        bind(gl, render.reflection_probe_framebuffer.framebuffer);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, shadow_texture.handle, 0);

        //glClear(GL_DEPTH_BUFFER_BIT);

        //var camera_to_world = mat4_transform(gl_cubemap_face_rotations[i], probe.position);

        //var world_to_clip = camera_to_clip * mat4_inverse_transform_unscaled(camera_to_world);
        //var clip_to_world = camera_to_world * clip_to_camera;

        var light_count = render.light_count;
        execute(render, gl, buffer, light_to_world, world_to_clip, clip_to_world, first_pass_index, pass_count);
        render.light_count = light_count;
    }

    // reset original depth buffer
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, render.reflection_probe_framebuffer.depth_buffer);

    loop var i u32; pass_count
    {
        buffer.passes[first_pass_index + i] = passes[i];
    }

    loop var shader_index u32; buffer.shader_count
    {
        buffer.shader_handles[shader_index] = shader_handles[shader_index];
    }

    temporary_end(tmemory, tmemory_scope);

    var world_to_shadow = world_to_clip * mat4_inverse_transform_unscaled(light_to_world);
    return world_to_shadow;
}

enum render_shader_type
{
    default;
    sky;
    custom;
}

struct render_pass
{
    framebuffer_handle u32;
    framebuffer_size   vec2s;

    blit_framebuffer_handle u32;
    blit_framebuffer_size   vec2s;
    //

    clear_color rgbaf32;
    clear_depth f32;

    disable_depth_test  b8;
    disable_depth_write b8;
    enable_blend        b8;
    enable_clear_color  b8;
    enable_clear_depth  b8;
    enable_blit_framebuffer b8;
}

struct render_buffer
{
    passes render_pass[32];

    shader_handles u32 ref[64];
    shader_types   render_shader_type[64];

    textures u32[256];
    texture_types u32[256];

    uniform_locations s32[4096];
    uniform_values    vec4[4096];

    transforms      mat_transform[4096];

    vertex_buffers u32[1024];

    index_buffers u32[1024];

    commands render_command[4096];

    expand counts render_buffer_counts;
}

struct render_buffer_counts
{
    pass_count          u32;
    shader_count        u32;
    texture_count       u32;
    transform_count     u32;
    vertex_buffer_count u32;
    index_buffer_count  u32;
    command_count       u32;
    uniform_count       u32;
}

struct render_command
{
    material render_material;

    pass_index u32;

    transform_offset u32;
    transform_count  u32;

    texture_slots   render_texture_slot[render_texture_slot.count];
    texture_indices u32[render_texture_slot.count];
    texture_count u32;

    shader_index        u32;
    vertex_buffer_index u32;
    index_buffer_index  u32;

    uniform_offset u32;
    uniform_count  u32;

    vertex_offset u32;
    vertex_count  u32;
}

// define:
// enum render_texture_slot render_texture_slot_base {  }
enum render_texture_slot_base
{
    albedo;
    normal;
    shadow;
    material;
    irradiance;
    prefiltered_environment;
    integrated_brdf_environment;
}

func push_pass(buffer render_buffer ref) (pass render_pass ref)
{
    assert(buffer.pass_count < buffer.passes.count);
    var pass = buffer.passes[buffer.pass_count] ref;
    buffer.pass_count += 1;

    pass deref = {} render_pass;

    return pass;
}

func push_pass_with_previous_framebuffer(buffer render_buffer ref) (pass render_pass ref)
{
    assert(buffer.pass_count);
    var previous_pass = buffer.passes[buffer.pass_count - 1];

    var pass = push_pass(buffer);
    pass.framebuffer_handle = previous_pass.framebuffer_handle;
    pass.framebuffer_size   = previous_pass.framebuffer_size;

    return pass;
}

func push(buffer render_buffer ref, location = get_call_location()) (command render_command ref)
{
    assert(buffer.command_count < buffer.commands.count, location);
    var command = buffer.commands[buffer.command_count] ref;
    buffer.command_count += 1;

    command deref = {} render_command;

    return command;
}

func push(buffer render_buffer ref, pass_index u32 = 0, shader_type render_shader_type, shader_handle u32 ref, mesh render_mesh, material render_material, vertex_offset = 0, vertex_count = -1 cast(u32), location = get_call_location()) (command render_command ref)
{
    assert(shader_handle deref, location);
    assert(pass_index < buffer.pass_count, location);

    var command = push(buffer, location);
    command.material   = material;
    command.pass_index = pass_index;

    var shader_index = -1 cast(u32);
    loop var i u32; buffer.shader_count
    {
        if buffer.shader_handles[i] is shader_handle
        {
            assert(buffer.shader_types[i] is shader_type, location);
            shader_index = i;
            break;
        }
    }

    if shader_index is -1 cast(u32)
    {
        assert(buffer.shader_count < buffer.shader_handles.count);
        buffer.shader_handles[buffer.shader_count] = shader_handle;
        buffer.shader_types[buffer.shader_count]   = shader_type;
        shader_index = buffer.shader_count;
        buffer.shader_count += 1;
    }

    var vertex_buffer_index = -1 cast(u32);
    loop var i u32; buffer.vertex_buffer_count
    {
        if buffer.vertex_buffers[i] is mesh.vertex_buffer.vertex_array
        {
            vertex_buffer_index = i;
            break;
        }
    }

    if vertex_buffer_index is -1 cast(u32)
    {
        assert(buffer.vertex_buffer_count < buffer.vertex_buffers.count, location);
        buffer.vertex_buffers[buffer.vertex_buffer_count] = mesh.vertex_buffer.vertex_array;
        vertex_buffer_index = buffer.vertex_buffer_count;
        buffer.vertex_buffer_count += 1;
    }

    var index_buffer_index = -1 cast(u32);
    if mesh.index_buffer.handle
    {
        loop var i u32; buffer.index_buffer_count
        {
            if buffer.index_buffers[i] is mesh.index_buffer.handle
            {
                index_buffer_index = i;
                break;
            }
        }

        if index_buffer_index is -1 cast(u32)
        {
            assert(buffer.index_buffer_count < buffer.index_buffers.count, location);
            buffer.index_buffers[buffer.index_buffer_count] = mesh.index_buffer.handle;
            index_buffer_index = buffer.index_buffer_count;
            buffer.index_buffer_count += 1;
        }
    }

    var total_vertex_count u32;
    if mesh.index_buffer.handle
        total_vertex_count = mesh.index_buffer.count;
    else
        total_vertex_count = mesh.vertex_buffer.vertex_count;

    if vertex_count is -1 cast(u32)
       vertex_count = total_vertex_count - vertex_offset;

    assert(vertex_count);
    assert(vertex_offset < total_vertex_count);
    assert(vertex_offset + vertex_count <= total_vertex_count);

    command.shader_index        = shader_index;
    command.vertex_buffer_index = vertex_buffer_index;
    command.index_buffer_index  = index_buffer_index;
    command.vertex_offset = vertex_offset;
    command.vertex_count  = vertex_count;
    command.texture_count = 0;
    command.transform_offset = buffer.transform_count;
    command.transform_count  = 0;

    return command;
}

func push(buffer render_buffer ref, pass_index u32 = 0, shader render_shader ref, mesh render_mesh, material render_material, vertex_offset = 0, vertex_count = -1 cast(u32), location = get_call_location()) (command render_command ref)
{
    return push(buffer, pass_index, render_shader_type.default, shader.handle ref, mesh, material, vertex_offset, vertex_count, location);
}

func push(buffer render_buffer ref, pass_index u32 = 0, shader render_shader ref, mesh render_mesh, transform mat_transform, material render_material, vertex_offset = 0, vertex_count = -1 cast(u32), location = get_call_location()) (command render_command ref)
{
    var command = push(buffer, pass_index, shader, mesh, material, vertex_offset, vertex_count, location);
    add_transforms(buffer, command, transform);
    return command;
}

func push(buffer render_buffer ref, pass_index u32 = 0, shader render_sky_shader ref, mesh render_mesh, material render_material, vertex_offset = 0, vertex_count = -1 cast(u32), location = get_call_location()) (command render_command ref)
{
    return push(buffer, pass_index, render_shader_type.sky, shader.handle ref, mesh,  material, vertex_offset, vertex_count, location);
}

func push_node(buffer render_buffer ref, pass_index u32 = 0, shader_type render_shader_type, shader_handle u32 ref, scene render_mesh_static_scene, draw_command_index u32, node_to_world mat_transform, material render_material, location = get_call_location()) (command render_command ref)
{
    var draw_command = scene.draw_commands[draw_command_index];
    var command = push(buffer, pass_index, shader_type, shader_handle, scene.base, material, draw_command.vertex_offset, draw_command.vertex_count, location);
    add_transforms(buffer, command, node_to_world * draw_command.mesh_to_node);
    return command;
}

func add_transforms(buffer render_buffer ref, command render_command ref, expand transforms mat_transform[])
{
    assert(buffer.transform_count + transforms.count <= buffer.transforms.count);
    loop var i u32; transforms.count
        buffer.transforms[buffer.transform_count + i] = transforms[i];

    buffer.transform_count  += transforms.count cast(u32);
    command.transform_count += transforms.count cast(u32);
}

func set_texture(buffer render_buffer ref, command render_command ref, slot render_texture_slot, texture_type u32, texture u32, location = get_call_location())
{
    assert(texture, location);
    assert((texture_type is GL_TEXTURE_2D) or (texture_type is GL_TEXTURE_CUBE_MAP), location);

    var texture_index = -1 cast(u32);
    loop var i u32; buffer.texture_count
    {
        if buffer.textures[i] is texture
        {
            assert(buffer.texture_types[i] is texture_type);
            texture_index = i;
            break;
        }
    }

    if texture_index is -1 cast(u32)
    {
        assert(buffer.texture_count < buffer.textures.count, location);
        buffer.textures[buffer.texture_count]      = texture;
        buffer.texture_types[buffer.texture_count] = texture_type;
        texture_index = buffer.texture_count;
        buffer.texture_count += 1;
    }

    command.texture_slots[command.texture_count] = slot;
    command.texture_indices[command.texture_count] = texture_index;
    command.texture_count += 1;
}

func set_texture(buffer render_buffer ref, command render_command ref, slot render_texture_slot, texture gl_texture)
{
    set_texture(buffer, command, slot, GL_TEXTURE_2D, texture.handle);
}

func set_texture(buffer render_buffer ref, command render_command ref, slot render_texture_slot, texture gl_texture_cube)
{
    set_texture(buffer, command, slot, GL_TEXTURE_CUBE_MAP, texture.handle);
}

func add_uniform(buffer render_buffer ref, command render_command ref, location s32) (value vec4 ref)
{
    assert(location is_not -1);

    assert(buffer.uniform_count < buffer.uniform_locations.count);
    buffer.uniform_locations[buffer.uniform_count] = location;
    var value = buffer.uniform_values[buffer.uniform_count] ref;
    buffer.uniform_count += 1;

    command.uniform_count += 1;
    command.uniform_offset = buffer.uniform_count - command.uniform_count;

    return value;
}

func filter_command(command render_command, pass_index u32, shader_index u32, vertex_buffer_index u32) (discard b8)
{
    return (command.pass_index is_not pass_index) or (command.shader_index is_not shader_index) or (command.vertex_buffer_index is_not vertex_buffer_index);
}

func upload_buffers(render render_system ref, gl gl_api ref, buffer render_buffer ref, tmemory memory_arena ref)
{
    var materials render_material[];
    reallocate_array(tmemory, materials ref, buffer.commands.count);

    var material_count u32;
    loop var pass u32; buffer.pass_count
    {
        loop var shader_index u32; buffer.shader_count
        {
            loop var vertex_buffer_index u32; buffer.vertex_buffer_count
            {
                loop var command_index u32; buffer.command_count
                {
                    var command = buffer.commands[command_index];
                    if filter_command(command, pass, shader_index, vertex_buffer_index)
                        continue;

                    materials[material_count] = command.material;
                    material_count += 1;
                }
            }
        }
    }

    resize_buffer(gl, render.transform_uniform_buffer ref,
    render_uniform_buffer_binding.transform_buffer, { buffer.transform_count, buffer.transforms.base } mat_transform[], tmemory);

    resize_buffer(gl, render.material_uniform_buffer ref, render_uniform_buffer_binding.material_buffer, { material_count, materials.base } render_material[], tmemory);

    reallocate_array(tmemory, materials ref, 0);
}

func execute(render render_system ref, gl gl_api ref, buffer render_buffer ref, camera_to_world mat_transform, world_to_clip mat_projection, clip_to_world mat_projection, first_pass_index u32 = 0, pass_count u32 = u32_invalid_index)
{
    assert(first_pass_index < buffer.pass_count);

    if pass_count is u32_invalid_index
        pass_count = buffer.pass_count - first_pass_index;

    {
        var camera render_camera_buffer;
        camera.world_to_clip_projection = world_to_clip;
        camera.clip_to_world_projection = clip_to_world;
        camera.camera_world_position = camera_to_world.translation;
        camera.near = 0.01;
        camera.far  = 1000;
        resize_buffer(gl, render.camera_uniform_buffer ref, render_uniform_buffer_binding.camera_buffer, camera);

        bind_uniform_buffer(render.camera_uniform_buffer);
    }

    var sun_direction = normalize([ 1.5, cos(2 * pi32 * render.sun_time), -sin(2 * pi32 * render.sun_time) ] vec3);

    {
        var sky render_sky_buffer;
        sky.top_color.rgb    = [ 0.22, 0.64, 0.91 ] vec3;
        //sky.top_color.rgb    = [ 0.42, 0.84, 0.91 ] vec3;
        sky.middle_color.rgb = [ 1.0, 1.0, 1.0 ] vec3;
        sky.bottom_color.rgb = [ 0.44, 0.69, 0.00 ] vec3;
        sky.sun_direction.xyz = sun_direction;
        //push_light_direction(render, [ 0,  1, 0 ] vec3, sky.top_color.rgb * 0.5);
        //push_light_direction(render, [ 0, -1, 0 ] vec3, sky.bottom_color.rgb * 0.1);

        resize_buffer(gl, render.sky_uniform_buffer ref, render_uniform_buffer_binding.sky_buffer, sky);

        bind_uniform_buffer(render.sky_uniform_buffer);
    }

    if dot(sun_direction, [ 0, 1, 0] vec3) > 0
    {
        // HACK:
        render.shadow.shadow_light_index = render.light_count;
        push_light_direction(render, sun_direction, [ 3, 3 , 3] vec3);

        resize_buffer(gl, render.lighting_uniform_buffer ref, render_uniform_buffer_binding.lighting_buffer, render.lighting);
        bind_uniform_buffer(render.lighting_uniform_buffer);
    }

    resize_buffer(gl, render.shadow_uniform_buffer ref, render_uniform_buffer_binding.shadow_buffer, render.shadow);
    bind_uniform_buffer(render.shadow_uniform_buffer);

    // default vertex attributes
    {
        glVertexAttrib3f(render_vertex_attribute.normal,  0, 1, 0);
        glVertexAttrib3f(render_vertex_attribute.tangent, 1, 0, 0);
        glVertexAttrib2f(render_vertex_attribute.uv, 0, 0);
        glVertexAttrib4f(render_vertex_attribute.color, 1, 1, 1, 1);
        glVertexAttribI4ui(render_vertex_attribute.blend_indices, 0, 0, 0, 0);
        glVertexAttrib4f(render_vertex_attribute.blend_weights, 1, 0, 0, 0);
    }

    var material_count u32;

    var previous_pass render_pass;
    previous_pass.framebuffer_handle = u32_invalid_index;

    loop var pass_index = first_pass_index; first_pass_index + pass_count
    {
        var pass = buffer.passes[pass_index];

        if pass.framebuffer_handle is_not previous_pass.framebuffer_handle
        {
            bind_framebuffer(gl, pass.framebuffer_handle);
            glViewport(0, 0, pass.framebuffer_size.width, pass.framebuffer_size.height);
        }

       if pass.disable_depth_test
           glDisable(GL_DEPTH_TEST);
       else
           glEnable(GL_DEPTH_TEST);

       if pass.disable_depth_write
           glDepthMask(GL_FALSE);
       else
           glDepthMask(GL_TRUE);

        if pass.enable_blend
        {
           glEnable(GL_BLEND);
           glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        }
        else
        {
           glDisable(GL_BLEND);
        }

        var clear_mask u32;
        if pass.enable_clear_color
        {
            clear_mask bit_or= GL_COLOR_BUFFER_BIT;
            glClearColor(pass.clear_color.r, pass.clear_color.r, pass.clear_color.b, pass.clear_color.a);
        }

        if pass.enable_clear_depth
        {
           clear_mask bit_or= GL_DEPTH_BUFFER_BIT;
           glClearDepthf(pass.clear_depth);
        }

        if clear_mask
           glClear(clear_mask);

        if pass.enable_blit_framebuffer
        {
           glBindFramebuffer(GL_READ_FRAMEBUFFER, pass.blit_framebuffer_handle);
           glBlitFramebuffer(0, 0, pass.framebuffer_size.width, pass.framebuffer_size.height, 0, 0, pass.blit_framebuffer_size.width, pass.blit_framebuffer_size.height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
           glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
        }

        previous_pass = pass;

        loop var shader_index u32; buffer.shader_count
        {
            glUseProgram(buffer.shader_handles[shader_index] deref);

            switch buffer.shader_types[shader_index]
            case render_shader_type.default
            {
                var shader = buffer.shader_handles[shader_index] cast(render_shader ref) deref;

                if shader.albedo_map is_not - 1
                    glUniform1i(shader.albedo_map,   render_texture_slot.albedo);

                if shader.normal_map is_not - 1
                    glUniform1i(shader.normal_map,   render_texture_slot.normal);

                if shader.shadow_map is_not - 1
                    glUniform1i(shader.shadow_map, render_texture_slot.shadow);

                if shader.material_map is_not - 1
                    glUniform1i(shader.material_map, render_texture_slot.material);

                if shader.irradiance_map is_not - 1
                    glUniform1i(shader.irradiance_map, render_texture_slot.irradiance);

                if shader.prefiltered_environment_map is_not - 1
                    glUniform1i(shader.prefiltered_environment_map, render_texture_slot.prefiltered_environment);

                if shader.integrated_brdf_environment_map is_not - 1
                    glUniform1i(shader.integrated_brdf_environment_map, render_texture_slot.integrated_brdf_environment);

                glActiveTexture(GL_TEXTURE0 + render_texture_slot.integrated_brdf_environment);
                glBindTexture(GL_TEXTURE_2D, render.integrated_brdf_environment_map.handle);
            }
            case render_shader_type.sky
            {
                var shader = buffer.shader_handles[shader_index] cast(render_sky_shader ref) deref;

                glUniformMatrix4fv(shader.clip_to_world_projection, 1, GL_FALSE, clip_to_world.values.base);
            }
            case render_shader_type.custom
            {
            }
            else
                assert(0);

            loop var vertex_buffer_index u32; buffer.vertex_buffer_count
            {
                glBindVertexArray(buffer.vertex_buffers[vertex_buffer_index]);

                loop var command_index u32; buffer.command_count
                {
                    var command = buffer.commands[command_index];
                    if filter_command(command, pass_index, shader_index, vertex_buffer_index)
                        continue;

                    if command.transform_count
                        bind_uniform_buffer(render.transform_uniform_buffer, command.transform_offset);

                    bind_uniform_buffer(render.material_uniform_buffer, material_count);
                    material_count += 1;

                    loop var uniform_index u32; command.uniform_count
                    {
                        var location = buffer.uniform_locations[command.uniform_offset + uniform_index];
                        var value    = buffer.uniform_values[command.uniform_offset + uniform_index];
                        glUniform4fv(location, 1, value.base);
                    }

                    loop var texture_index u32; command.texture_count
                    {
                        glActiveTexture(GL_TEXTURE0 + command.texture_slots[texture_index]);
                        glBindTexture(buffer.texture_types[command.texture_indices[texture_index]], buffer.textures[command.texture_indices[texture_index]]);
                    }

                    if command.index_buffer_index is_not -1 cast(u32)
                    {
                        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.index_buffers[command.index_buffer_index]);

                        glDrawElements(GL_TRIANGLES, command.vertex_count, GL_UNSIGNED_INT, (command.vertex_offset * type_byte_count(u32)) cast(u8 ref));
                    }
                    else
                    {
                        glDrawArrays(GL_TRIANGLES, command.vertex_offset, command.vertex_count);
                    }
                }
            }
        }
    }

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    glUseProgram(0);
}

func reload(texture gl_texture ref, platform platform_api ref, path string, tmemory memory_arena ref)
{
    var data = platform_read_entire_file(platform, tmemory, path);

    stbi_set_flip_vertically_on_load(1);
    var width s32;
    var height s32;
    var channel_count s32;
    var pixels = stbi_load_from_memory(data.base, data.count cast(s32), width ref, height ref, channel_count ref, 4);

    if texture.handle
        glDeleteTextures(1, texture.handle ref);

    texture deref = gl_create_texture_2d(width, height, true, { (width * height) cast(usize) * type_byte_count(u8) * 4, pixels cast(u8 ref) } u8[], GL_RGBA, GL_UNSIGNED_BYTE);
}