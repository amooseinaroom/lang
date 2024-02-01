
in fragment_type
{
    vec3 world_position;
    vec3 world_normal;
    vec4 color;
    vec2 uv;
} fragment;

out vec4 out_color;

void main()
{   
    out_color = texture(environment_map, normalize(fragment.world_normal));

    //out_color = vec4(normalize(fragment.world_normal) * 0.5 + 0.5, 1);
}