
#version 330

in vec3 vertex_position;
in vec2 vertex_uv;
in vec4 vertex_color;

out fragment_type
{
    vec2 uv;
    vec4 color;
} fragment;

layout (std140, column_major) uniform camera_buffer
{
    mat4 world_to_clip_projection;
    vec4 camera_world_position;
};

void main()
{
    vec4 world_position = vec4(vertex_position, 1);
    
    //vec4 normal = vec4(vertex_normal, 0);
    //vec4 world_normal = object_to_world_transforms[0] * normal;
    
    //fragment.world_position = world_position.xyz / world_position.w;
    //fragment.world_normal   = world_normal.xyz;
    //fragment.color          = vertex_color * material_albedo[0];

    fragment.uv    = vertex_uv;
    fragment.color = vertex_color;
    
    gl_Position = world_to_clip_projection * world_position;
}