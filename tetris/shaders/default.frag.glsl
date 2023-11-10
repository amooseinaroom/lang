
#version 330

in fragment_type
{
    vec3 world_position;
    vec3 world_normal;
    vec4 color;
} fragment;

out vec4 out_color;

#define max_light_count 8

layout (std140) uniform camera_buffer
{
    mat4 world_to_clip_projection;
    vec4 camera_world_position;
};

layout (std140) uniform lighting_buffer
{
    vec4 lighting_parameters[max_light_count];
    vec4 lighting_colors[max_light_count];
};

void main()
{
    vec3 world_position = fragment.world_position;
    vec3 normal = normalize(fragment.world_normal);
    
    vec3 camera_direction = normalize(camera_world_position.xyz - world_position);
    
    vec3 diffuse_color  = vec3(0);
    vec3 specular_color = vec3(0);
    
    for (int i = 0; i < max_light_count; i++)
    {
        vec3 light_world_position = lighting_parameters[i].xyz;
        vec3 light_distance = light_world_position - world_position;
        float light_distance_squared = dot(light_distance, light_distance);
        
        vec3 light_direction = normalize(light_distance);
        vec3 half_direction  = normalize(light_direction + camera_direction);
        
        float gloss = 0.8 * 4096;
        float specular = pow(max(0, dot(normal, half_direction)), gloss);
        
        float diffuse = max(dot(normal, light_direction), 0);
        
        diffuse_color  += lighting_colors[i].rgb * (diffuse / (1 + light_distance_squared));
        specular_color += lighting_colors[i].rgb * specular;
    }

    vec3 color = diffuse_color * fragment.color.rgb + specular_color;
    
    // simple tone mapping
    color = color / (color + 1);
    
    //out_color = vec4(gl_FragCoord.z, 0, 0, fragment.color.a);
    //out_color = vec4(normal * 0.5 + 0.5, fragment.color.a);
    
    out_color = vec4(color, fragment.color.a);
}