
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

    // should be optimized to use multiply add by the compiler
    fragment.offset[0] = (metrics.xyxy * vec4(-1, 0, 0, -1.0)) + vertex_uv.xyxy;
    fragment.offset[1] = (metrics.xyxy * vec4( 1, 0, 0,  1.0)) + vertex_uv.xyxy;
    fragment.offset[2] = (metrics.xyxy * vec4(-2, 0, 0, -2.0)) + vertex_uv.xyxy;

    fragment.uv = vertex_uv;

    // assumes vertex in clip space
    gl_Position = vec4(vertex_position, 0, 1);
}