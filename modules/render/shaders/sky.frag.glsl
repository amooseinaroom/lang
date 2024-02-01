#version 330
#define f32 float

#define is_less(a, b) step(a, b)
#define lerp(a, b, factor) mix(a, b, factor)

in vec3 fragment_world_position;

layout (std140) uniform sky_buffer
{
    vec4 top_color;
    vec4 middle_color;
    vec4 bottom_color;    
    vec4 sun_direction;
};

out vec4 out_color;

void main()
{
    vec3 normal = normalize(fragment_world_position);

    vec3 world_up = vec3(0, 1, 0);
    f32 blend = dot(normal, world_up);
    f32 is_top = 1 - is_less(blend, 0);
    
    f32 brightness = max(0, sun_direction.y) * 2;    
    f32 is_sun    = pow(max(0, dot(normal, sun_direction.xyz)), 2048);
    f32 is_corona = pow(max(0, dot(normal, sun_direction.xyz)), lerp(32, 2048, pow(brightness * 0.5, 2)));
    
    vec3 sun_tint = vec3(1, 0.4, 0.1);
    vec3 sun_color = lerp(sun_tint * 1, sun_tint * 5, is_sun);

    vec3 sky_color = lerp(middle_color.rgb , top_color.rgb, pow(abs(blend), 0.5)) * brightness;
    sky_color = sky_color + sun_color * is_corona;    
    
    //vec3 camera_direction = -normal;
    //vec3 half_direction = normalize(-normal + sun_direction.xyz);
    //f32 specular = max(0, dot(vec3(0, 1, 0), half_direction));

    vec3 ground_color = bottom_color.rgb; //lerp(bottom_color.rgb, sun_tint * 5, pow(specular, 1024));

    vec3 color = lerp(
            lerp(middle_color.rgb, ground_color, pow(abs(blend), 0.25)) * brightness,
            sky_color, //lerp(middle_color.rgb * brightness, sky_color, pow(abs(blend), 0.4)),
            is_top);            
    
    
    //color *= brighness;

    //color *= 0.5;// color / (vec3(1) + color);

    //color = texture(environment_texture, normal).rgb;
        
    out_color = vec4(color, 1);
}