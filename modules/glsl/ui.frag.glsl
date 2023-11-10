
#version 330

in fragment_type
{
    vec2  uv;
    vec4  color;
    float saturation;
} fragment;

out vec4 out_color;

uniform sampler2D diffuse_texture;

void main()
{
    vec4 sample = texture(diffuse_texture, fragment.uv);
    vec4 color = sample * fragment.color;

    color.rgb = mix(vec3((color.r + color.g + color.b) / 3), color.rgb, fragment.saturation);

    out_color = color;
}