
in fragment_type
{
    vec3 world_position;
    vec3 world_normal;
    vec3 world_tangent;
    vec4 color;
    vec2 uv;
} fragment;

out vec4 out_color;

void main()
{
    // out_color = fragment.color; return;
    // out_color = vec4(fragment.world_normal * 0.5 + 0.5, 1); return;
    
    // swizzle yz
    vec3 normal_sample = texture(normal_map, fragment.uv).xzy * 2 - 1;
    
    mat3 tangent_to_world;
    tangent_to_world[0] = normalize(fragment.world_tangent),
    tangent_to_world[1] = normalize(fragment.world_normal),
    tangent_to_world[2] = cross(tangent_to_world[1], tangent_to_world[0]);
                
    vec3 world_normal = tangent_to_world * normal_sample;    
    // vec3 world_normal = fragment.world_normal;
    // out_color = vec4(world_normal * 0.5 + 0.5, 1); return;
    out_color = default_shading(fragment.world_position, world_normal, fragment.uv, fragment.color);
}