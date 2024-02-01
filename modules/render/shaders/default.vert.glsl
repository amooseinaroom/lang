
in vec3 vertex_position;
in vec3 vertex_normal;
in vec3 vertex_tangent;
in vec4 vertex_color;
in vec2 vertex_uv;

out fragment_type
{
    vec3 world_position;
    vec3 world_normal;
    vec3 world_tangent;
    vec4 color;
    vec2 uv;
} fragment;

void main()
{
    vec4 position = vec4(vertex_position, 1);
    vec4 world_position = object_to_world_transforms[0] * position;
    
    vec4 normal = vec4(vertex_normal, 0);
    vec4 world_normal = object_to_world_transforms[0] * normal;

    vec4 tangent = vec4(vertex_tangent, 0);
    vec4 world_tangent = object_to_world_transforms[0] * tangent;
    
    fragment.world_position = world_position.xyz / world_position.w;
    fragment.world_normal   = world_normal.xyz;
    fragment.world_tangent  = world_tangent.xyz;
    fragment.color          = vertex_color;
    fragment.uv             = vertex_uv;
    
    gl_Position = world_to_clip_projection * world_position;
    
    //gl_Position = vec4(vertex_position, 0, 1);
}