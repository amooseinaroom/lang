
#version 330

in fragment_type
{
    vec2 uv;
    vec4 color;
} fragment;

out vec4 out_color;

uniform sampler2D diffuse_texture;

void main()
{
    vec4 sample = texture(diffuse_texture, fragment.uv);
    out_color = sample * fragment.color;
}