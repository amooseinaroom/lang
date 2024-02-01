#version 330

out vec3 fragment_world_position;
out vec2 fragment_uv;

uniform mat4 clip_to_world_projection;

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
    
    vec4 wolrd_position = clip_to_world_projection * clip_position;
    fragment_world_position = wolrd_position.xyz / wolrd_position.w;

    fragment_uv = clip_position.xy * 0.5 + 0.5;
    
    gl_Position = vec4(clip_position.xyz, 1);
}