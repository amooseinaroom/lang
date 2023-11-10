
#version 330

in vec2  vertex_position;
in vec2  vertex_uv;
in vec4  vertex_color;
in float vertex_saturation;

out fragment_type
{
    vec2  uv;
    vec4  color;
    float saturation;
} fragment;

void main()
{
    fragment.uv         = vertex_uv;
    fragment.color      = vertex_color;
    fragment.saturation = vertex_saturation;
    gl_Position = vec4(vertex_position, 0, 1);
}