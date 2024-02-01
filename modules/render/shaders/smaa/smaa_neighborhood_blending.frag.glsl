
struct fragment_type
{
    vec2 uv;
    vec4 offset;
};

in fragment_type fragment;

uniform sampler2D albedo;
uniform sampler2D blend_weights_texture;

out vec4 out_color;

void main()
{    
    out_color = SMAANeighborhoodBlendingPS(fragment.uv, fragment.offset, albedo, blend_weights_texture);
}