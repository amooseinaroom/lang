
struct fragment_type
{
    vec2 uv;
    vec4 offset[3];
};

in fragment_type fragment;

out vec2 out_color;

uniform sampler2D color_map;

void main()
{
    out_color = SMAALumaEdgeDetectionPS(fragment.uv, fragment.offset, color_map);
}