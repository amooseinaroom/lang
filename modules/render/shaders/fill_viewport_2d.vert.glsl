#version 330

out vec2 fragment_uv;

void main()
{
    // viewport filling triangle
    vec2 positions[] = vec2[3]
    (
        vec2(-3, -1),
        vec2( 3, -1),
        vec2( 0,  2)
    );

    vec4 clip_position = vec4(positions[gl_VertexID], 0.999, 1);
        
    fragment_uv = clip_position.xy * 0.5 + 0.5;
    
    gl_Position = clip_position;
}