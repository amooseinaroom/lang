
struct fragment_type
{
    vec2 uv;
    vec4 offset[3];
};

in fragment_type fragment;

uniform sampler2D edges_texture;
uniform sampler2D area_texture;
uniform sampler2D search_texture;

out vec4 out_color;

void main()
{    
    out_color = SMAABlendingWeightCalculationPS(fragment.uv, gl_FragCoord.xy, fragment.offset, edges_texture, area_texture, search_texture, vec4(0));        
}