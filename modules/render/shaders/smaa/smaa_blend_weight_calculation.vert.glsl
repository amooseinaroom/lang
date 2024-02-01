
in vec2 vertex_position;
in vec2 vertex_uv;

struct fragment_type
{
    vec2 uv;
    vec4 offset[3];
};

out fragment_type fragment;

void main()
{
    // viewport filling triangle
    vec2 positions[] = vec2[3]
    (
        vec2(-3, -1),
        vec2( 3, -1),
        vec2( 0,  2)
    );

    vec2 vertex_position = positions[gl_VertexID];
    vec2 vertex_uv = vertex_position * 0.5 + 0.5;
    
    vec2 ignored;
    SMAABlendingWeightCalculationVS(vertex_uv, ignored, fragment.offset);
    fragment.uv = vertex_uv;
    
    gl_Position = vec4(vertex_position, 0, 1);
}