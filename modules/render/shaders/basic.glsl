#define pi32  3.14159265358979323846
#define tau32 (pi32 * 2)

#define debug_output1(value)        out_color = vec4(value, 0, 0, 1); return;
#define debug_output2(value)        out_color = vec4(value.x, value.y, 0, 1); return;
#define debug_output3(color3)       out_color = vec4(color3, 1); return;
#define debug_normal_output(normal) out_color = vec4(normal * 0.5 + 0.5, 1); return;

#define is_less(a, b) step(a, b)

#define lerp(a, b, factor) mix(a, b, factor)

#define s32 int
#define u32 uint
#define f32 float

layout (std140) uniform camera_buffer
{
    mat4 world_to_clip_projection; 
    mat4 clip_to_world_projection;
    vec3 camera_world_position;
    f32 near;
    f32 far;
};

struct light_data
{
    // padded to vec4
    vec3 world_position_or_direction; f32 is_point_light;
    vec3 color;                       f32 attenuation;
};

layout (std140) uniform lighting_buffer
{
    light_data lights[max_light_count];
};

struct material
{
    vec4 albedo;
    f32 roughness; f32 metallic; vec2 user_vec2;
    vec3 emission; f32 user_f32;
};

layout (std140) uniform material_buffer
{
    material materials[1];
};

layout (std140, column_major) uniform transform_buffer
{
    mat4 object_to_world_transforms[64]; // size is just for debugging in render doc
};

layout (std140) uniform shadow_buffer
{
    mat4 world_to_shadow_projection;
    u32  shadow_light_index;
    // vec4 color_and_bias;
};

uniform sampler2D albedo_map;
uniform sampler2D material_map;
uniform sampler2D normal_map;
uniform sampler2DShadow shadow_map;
uniform samplerCube environment_map;
uniform samplerCube irradiance_map;
uniform samplerCube prefiltered_environment_map;
uniform sampler2D integrated_brdf_environment_map;

f32 oscillate(f32 frequency, f32 phase, f32 time)
{
    return sin((frequency * time + phase) * tau32);
}

f32 intensity(vec3 a, vec3 b)
{
    return max(0, dot(a, b));
}

struct blinn_phong_input
{    
    vec3 world_position;
    vec3 world_normal;
    
    f32 gloss;
    f32 specularity;
    
    vec3 camera_direction;
};

struct blinn_phong_output
{
    vec3 diffuse;
    vec3 specular;
};

blinn_phong_output blinn_phong(blinn_phong_input data)
{
    blinn_phong_output result;
    result.diffuse  = vec3(0);
    result.specular = vec3(0);
    
    vec3 camera_distance = camera_world_position.xyz - data.world_position;
    f32 camera_distance_squared = dot(camera_distance, camera_distance);

    f32 max_diffuse = 0.5 / (4 * pi32 * camera_distance_squared);

    for (int i = 0; i < max_light_count; i++)
    {
        vec3 light_world_position_or_direction = lights[i].world_position_or_direction;
        f32 is_point_light = lights[i].is_point_light;
        
        vec3 light_distance = light_world_position_or_direction - data.world_position;
        f32 light_distance_squared = dot(light_distance, light_distance);
        
        vec3 light_direction = mix(light_world_position_or_direction, normalize(light_distance), is_point_light);
        vec3 half_direction  = normalize(light_direction + data.camera_direction);
        
        f32 specular = pow(max(0, dot(data.world_normal, half_direction)), data.gloss) * data.specularity;
        f32 diffuse  = max(0, dot(data.world_normal, light_direction)) * (1 - specular);// / (4 * pi32);

        // 
        //f32 scatter = 1.0;
        //diffuse = lerp(diffuse, max_diffuse, scatter) * (1 - specular);
        
        vec3 light_color      = lights[i].color;
        f32 light_attenuation = lights[i].attenuation;
        f32 light_intensity   = lerp(1, 1 / (1 + light_attenuation * light_distance_squared), is_point_light);
        
        result.diffuse  += light_color * (diffuse * light_intensity);
        result.specular += light_color * specular;

        //result.specular = vec3(diffuse);
        //break;
    }
    
    return result;
}

f32 shadowed_brightness(vec3 world_position, vec3 camera_distance)
{
    f32 shadow_bias = -0.01; // -0.0025;
    
    vec2 shadow_texel_scale = vec2(1) / textureSize(shadow_map, 0);
    
    vec4 shadow_position = world_to_shadow_projection * vec4(world_position, 1);
    vec3 shadow_value = shadow_position.xyz * 0.5 / shadow_position.w + 0.5;
    shadow_value.z += shadow_bias;
    
    f32 brightness = 0;
    
    for (int y = -1; y < 2; y++)
    {
        for (int x = -1; x < 2; x++)
        {
            brightness += texture(shadow_map, shadow_value + vec3(vec2(x, y) * shadow_texel_scale, 0));
        }
    }
    brightness *= 1.0 / 9;
    brightness = mix(0.05, 1.0, brightness);
    
    // blend out shadows in the distance to reduce pop-in
    f32 shadow_fadeout = smoothstep(1, 4, dot(camera_distance, camera_distance) / 2500);
    brightness = min(brightness + shadow_fadeout, 1);
    
    return brightness;
}

vec3 phong_shading(blinn_phong_input phong_input, vec3 camera_distance, vec3 albedo)
{
    blinn_phong_output phong_output = blinn_phong(phong_input);
    f32 brighness = 1; //shadowed_brightness(phong_input.position, camera_distance);
    
    f32 ambient = 0.02;
    
    //vec3 color = (albedo * (phong_output.diffuse + ambient + phong_output.specular)) * brighness + materials[0].emission.rgb;
    vec3 color = albedo * ((phong_output.diffuse* brighness) + ambient) + phong_output.specular + materials[0].emission.rgb;    
    
    return color;
}

vec3 apply_tone_mapping(vec3 color)
{
     #if 1
        f32 min_value = min(min(color.r, color.g), color.b);
        vec3 pure_color = color - vec3(min_value);
        color = pure_color * 1.5 + vec3(min_value * 0.5);
    #endif

#if 0
    f32 exposure = 1.5;
    vec3 mapped = vec3(1.0) - exp(-color * exposure);
    return mapped;
#else
    return color / (color + vec3(1));
#endif
}

vec3 revert_tone_mapping(vec3 tone_mapped_color)
{
    // tonemapped_color = c / (1 + c);
    // 1 / tonemapped_color = (1 + c) / c 
    // 1 / tonemapped_color = 1 / c + 1
    // (1 / tonemapped_color - 1) = 1 / c
    // 1 / (1 / tonemapped_color - 1) = c

    return 1 / (1 / tone_mapped_color - 1);
}