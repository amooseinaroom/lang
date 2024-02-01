
in vec3  vertex_position;
in vec3  vertex_normal;
in vec3  vertex_tangent;
in vec2  vertex_uv;
in vec4  vertex_color;
in vec4  vertex_blend_weights;
in uvec4 vertex_blend_indices;

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
    vec4 normal   = vec4(vertex_normal,   0);
    vec4 tangent  = vec4(vertex_tangent,  0);
    
    vec3 world_position = vec3(0);
    vec3 world_normal   = vec3(0);
    vec3 world_tangent  = vec3(0);

    // some debugging
// #define DEBUG_BONES
#if defined DEBUG_BONES
    vec3 bone_colors[] = vec3[4]
    (
        vec3(0.99, 0.41, 0.18),
        vec3(0.96, 0.43, 0.02),
        vec3(0.87, 0.28, 0.24),
        vec3(0.01, 0.63, 0.29)
    );    

    vec3 bone_color = vec3(0);
#endif
    
    // assuming vertex.blend_weights add up to 1
    for (s32 i = 0; i < 4; i++)
    {
        u32 blend_index  = vertex_blend_indices[i];
        f32 blend_weight = vertex_blend_weights[i];

    #if defined DEBUG_BONES
        bone_color += bone_colors[blend_index] * blend_weight;
    #endif
        
        mat4 to_world = object_to_world_transforms[blend_index];
        //vec4 world_position4 = to_world * position;
        //world_position += world_position4.xyz / world_position4.w * blend_weight;
        world_position += (to_world * position).xyz * blend_weight;
        world_normal   += (to_world * normal).xyz   * blend_weight;
        world_tangent  += (to_world * tangent).xyz  * blend_weight;
    }
        
    fragment.world_position = world_position;
    fragment.world_normal   = world_normal;
    fragment.world_tangent  = world_tangent;

#if defined DEBUG_BONES
    fragment.color          = vertex_color * vec4(bone_color, 1);
#else
    fragment.color          = vertex_color;
#endif
    fragment.uv             = vertex_uv;    
    
    gl_Position = world_to_clip_projection * vec4(world_position, 1);
}