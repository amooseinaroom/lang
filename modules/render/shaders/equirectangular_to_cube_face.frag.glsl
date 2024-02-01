#version 330

in vec3 fragment_world_position;

out vec4 out_color;

uniform sampler2D equirectangular_map;

const vec2 inv_atan = vec2(0.1591, 0.3183);
vec2 sample_spherical_map(vec3 direction)
{
    vec2 uv = vec2(atan(direction.z, direction.x), asin(direction.y));
    uv *= inv_atan;
    uv += 0.5;

    return uv;
}

void main()
{		
    vec2 uv = sample_spherical_map(normalize(fragment_world_position)); // make sure to normalize localPos
    vec3 color = texture(equirectangular_map, uv).rgb;
    
    out_color = vec4(color, 1.0);
}