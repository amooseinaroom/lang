#version 330

#define pi32 3.14159265358979323846
#define f32  float

in vec3 fragment_world_position;

out vec4 out_color;

uniform samplerCube environment_map;

void main()
{
    vec3 normal = normalize(fragment_world_position);
    
    vec3 irradiance = vec3(0.0);  

    vec3 up    = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, normal));
    up         = normalize(cross(normal, right));
    
    const int phi_count = 256;
    f32 delta = 2 * pi32 / f32(phi_count);

    const int theta_count = phi_count / 4;

    for (int phi_index = 0; phi_index < phi_count; phi_index++)
    {
        f32 phi = f32(phi_index) * delta;        
    
        for (int theta_index = 0; theta_index < theta_count; theta_index++)
        {
            f32 theta = f32(theta_index) * delta;

            // spherical to cartesian (in tangent space)
            vec3 tangentSample = vec3(sin(theta) * cos(phi),  sin(theta) * sin(phi), cos(theta));
            // tangent space to world
            vec3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * normal; 

            irradiance += texture(environment_map, sampleVec).rgb * cos(theta) * sin(theta);            
        }
    }
    irradiance = pi32 * irradiance * (1.0 / f32(phi_count * theta_count));

    out_color = vec4(irradiance, 1.0);
    //out_color = vec4(normal * 0.5 + 0.5, 1);    
}