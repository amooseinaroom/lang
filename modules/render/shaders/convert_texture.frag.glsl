#version 330

in vec2 fragment_uv;

uniform sampler2D color_map;

uniform float     premultiply_alpha;

out vec4 out_color;

void main()
{    
    var color = texture(color_map, fragment_uv);    
    color.rgb *= mix(1, color.a, premultiply_alpha);
    
    out_color = color;
}