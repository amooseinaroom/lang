
struct pbr_values
{
    vec3 camera_direction;
    vec3 normal;
    vec3 albedo;
    vec3 irradiance;
    vec3 f0;    
    f32  metallic;
    f32  normal_dot_camera;
    f32  camera_ggx;
    f32  alpha_squared;
    f32  k;
};

f32 pbr_normal_distirbution(f32 normal_dot_half, f32 alpha_squared)
{
    f32 denominator = (normal_dot_half * normal_dot_half * (alpha_squared - 1) + 1);
    denominator = pi32 * denominator * denominator + 0.00001;
    
    f32 distribution = alpha_squared / denominator;
    return distribution;
}

f32 pbr_geometry(f32 normal_dot_light, f32 k)
{
    f32 ggx = normal_dot_light  / (normal_dot_light * (1 - k) + k + 0.0001);
    return ggx;
}

f32 pbr_camera_ggx(f32 normal_dot_camera, f32 k)
{
    // ggx might get 0 on smoothed normals on silhouette, while fragments are still visible
    // so we add a small value to prevent black outline
    f32 ggx = pbr_geometry(normal_dot_camera, k) + 0.0001;
    return ggx;
}

vec3 pbr_reflection(vec3 f0, f32 camera_dot_half)
{    
    vec3 reflection = f0 + (1 - f0) * max(0, pow(1 - camera_dot_half, 5));
    //vec3 reflection = f0 + (1 - f0) * pow(clamp(1 - camera_dot_half, 0, 1), 5);
    return reflection;
}

pbr_values pbr_init(vec3 camera_direction, vec3 albedo, vec3 normal, f32 roughness, f32 metallic, vec3 irradiance)
{
    roughness = lerp(0.05, 1, roughness);    
    f32 alpha = roughness * roughness;
    f32 alpha_squared = alpha * alpha;
    
    f32 k = (alpha + 1);
    k = k * k / 8;
    
    vec3 f0 = lerp(vec3(0.04), albedo, metallic);
    
    f32 normal_dot_camera = intensity(normal, camera_direction);
    f32 camera_ggx = pbr_camera_ggx(normal_dot_camera, k);
    
    pbr_values values;
    values.camera_direction  = camera_direction;
    values.normal            = normal;
    values.albedo            = albedo;
    values.irradiance        = irradiance;
    values.f0                = f0;
    values.camera_ggx        = camera_ggx;
    values.normal_dot_camera = normal_dot_camera;
    values.metallic          = metallic;
    values.alpha_squared     = alpha_squared;
    values.k                 = k;
    
    return values;
}

vec3 pbr_light(pbr_values pbr, vec3 light_direction, vec3 light_radiance)
{
    vec3 half_direction  = normalize(pbr.camera_direction + light_direction);
    f32 normal_dot_light = intensity(pbr.normal,           light_direction);
    f32 normal_dot_half  = intensity(pbr.normal,           half_direction);
    f32 camera_dot_half  = intensity(pbr.camera_direction, half_direction);
        
    f32  d = pbr_normal_distirbution(normal_dot_half, pbr.alpha_squared);
    f32  g = pbr_geometry(normal_dot_light, pbr.k) * pbr.camera_ggx;
    vec3 f = pbr_reflection(pbr.f0, camera_dot_half);
    
    vec3 specular = d * g * f / (4 * pbr.normal_dot_camera * normal_dot_light + 0.0001);
    //vec3 specular =  vec3(d) / (4 * pbr.normal_dot_camera * normal_dot_light + 0.0001);
    vec3 diffuse = (1 - f) * (1 - pbr.metallic);

    //return f;// vec3(camera_dot_half);
    
    vec3 value = (diffuse * pbr.albedo * pbr.irradiance / pi32 + specular) * light_radiance * normal_dot_light;
    return value;
}

vec3 pbr_lighting(vec3 camera_direction, vec3 world_position, vec3 albedo, vec3 normal, f32 roughness, f32 metallic, vec3 irradiance, f32 ambient_occlusion)
{    
    pbr_values pbr = pbr_init(camera_direction, albedo, normal, roughness, metallic, irradiance);
    
    vec3 value = vec3(0);
    
    // cap to prevent inf loop if value is not set properly    
    for (int i = 0; i < max_light_count; i++)
    {
        light_data light = lights[i];
        
        // normalize twice to handle precision problems
        vec3 light_direction = lerp(light.world_position_or_direction, normalize(light.world_position_or_direction - world_position), light.is_point_light);
        f32  light_distance  = length(light.world_position_or_direction - world_position);
        f32  attenuation     = 1 / (1 + light.attenuation * light_distance * light_distance);
        //f32  attenuation     = 1 / (light_distance * light_distance);
        vec3 radiance        = light.color * lerp(1, attenuation, light.is_point_light);
    
        value += pbr_light(pbr, light_direction, radiance);        
    }

    value += ambient_occlusion * albedo;
    
    return value;
}

vec4 default_shading2(vec3 world_position, vec3 world_normal, vec2 uv, vec4 albedo)
{    
    vec3 camera_distance = camera_world_position.xyz - world_position;
    vec3 camera_direction = normalize(camera_distance);
    
    vec4 albedo_sample = texture(albedo_map, uv).rgba;
    vec4 material_sample = texture(material_map, uv);

    albedo = lerp(albedo_sample * vec4(vec3(1), albedo.a), albedo_sample * albedo * materials[0].albedo.rgba, material_sample.b);        
    
    // premultiplied alpha ...
    albedo.rgb *= albedo.a;

    f32 roughness = material_sample.r * materials[0].roughness;
    f32 metallic  = material_sample.g * materials[0].metallic;

#if 0
    blinn_phong_input phong_input;
    phong_input.world_position = world_position;
    phong_input.world_normal   = normalize(world_normal);
    phong_input.gloss       = 4095 * pow(1 - roughness, 4) + 1;
    phong_input.specularity = lerp(1.0, 3.0, metallic);
    phong_input.camera_direction = camera_direction;    
    
    vec3 color = phong_shading(phong_input, camera_distance, albedo.rgb);        
#else 
    
    world_normal = normalize(world_normal);
    vec3 irradiance = vec3(0.003); //texture(irradiance_map, world_normal).rgb;
    vec3 color = pbr_lighting(camera_direction, world_position, albedo.rgb, world_normal, roughness, metallic, irradiance, 0);
#endif
    
    color = apply_tone_mapping(color + materials[0].emission);

    // premultiplied alpha
    return vec4(color * albedo.a, albedo.a);
}


// learnopengl.com

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = pi32 * denom * denom;

    return nom / denom;
}
// ----------------------------------------------------------------------------
float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}
// ----------------------------------------------------------------------------
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}
// ----------------------------------------------------------------------------
vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}
// ----------------------------------------------------------------------------
vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness)
{
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}   
// ----------------------------------------------------------------------------
vec4 default_shading(vec3 world_position, vec3 world_normal, vec2 uv, vec4 albedo)
{        
    vec3 camera_distance = camera_world_position.xyz - world_position;
    vec3 N = normalize(world_normal);
    vec3 V = normalize(camera_distance);
    vec3 R = reflect(-V, N); 

    vec4 albedo_sample = texture(albedo_map, uv).rgba;
    vec4 material_sample = texture(material_map, uv);
    
    albedo = lerp(albedo_sample * vec4(vec3(1), albedo.a), albedo_sample * albedo * materials[0].albedo, material_sample.b);        
    
    // premultiplied alpha ...
    // albedo.rgb *= albedo.a;

    f32 roughness = material_sample.r * materials[0].roughness;
    f32 metallic  = material_sample.g * materials[0].metallic;        
    
    //return vec4(materials[0].roughness, 0, 0, 1);
    // return vec4(materials[0].user_f32, 0, 0, 1);

    // calculate reflectance at normal incidence; if dia-electric (like plastic) use F0 
    // of 0.04 and if it's a metal, use the albedo color as F0 (metallic workflow)    
    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, albedo.rgb, metallic);
    
    f32 shadow_influence_per_light[max_light_count]; 
    for(int i = 0; i < max_light_count; ++i) 
        shadow_influence_per_light[i] = 0;
        
    shadow_influence_per_light[shadow_light_index] = 1 - shadowed_brightness(world_position, camera_distance);
    //return vec4(shadow_influence_per_light[shadow_light_index], 0, 0, 1);

    // reflectance equation
    vec3 Lo = vec3(0.0);
    for(int i = 0; i < max_light_count; ++i) 
    {
        light_data light = lights[i];
        
        // calculate per-light radiance
        vec3 L = lerp(light.world_position_or_direction, normalize(light.world_position_or_direction - world_position), light.is_point_light);
        vec3 H = normalize(V + L);
        float distance = length(light.world_position_or_direction - world_position);
        float attenuation = lerp(1, 1.0 / (distance * distance), light.is_point_light);
        vec3 radiance = light.color * attenuation;

        // Cook-Torrance BRDF
        float NDF = DistributionGGX(N, H, roughness);   
        float G   = GeometrySmith(N, V, L, roughness);    
        vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);        
        
        vec3 numerator    = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001; // + 0.0001 to prevent divide by zero
        vec3 specular = numerator / denominator;
        
         // kS is equal to Fresnel
        vec3 kS = F;
        // for energy conservation, the diffuse and specular light can't
        // be above 1.0 (unless the surface emits light); to preserve this
        // relationship the diffuse component (kD) should equal 1.0 - kS.
        vec3 kD = vec3(1.0) - kS;
        // multiply kD by the inverse metalness such that only non-metals 
        // have diffuse lighting, or a linear blend if partly metal (pure metals
        // have no diffuse light).
        kD *= 1.0 - metallic;                   
            
        // scale light by NdotL
        float NdotL = max(dot(N, L), 0.0);        

        f32 shadow = (1 - shadow_influence_per_light[i]);
        // add to outgoing radiance Lo
        Lo += (kD * albedo.rgb / pi32 + specular) * radiance * NdotL * shadow; // note that we already multiplied the BRDF by the Fresnel (kS) so we won't multiply by kS again
        
    }   
    
    // ambient lighting (we now use IBL as the ambient term)
    vec3 F = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness);
    
    vec3 kS = F;
    vec3 kD = 1.0 - kS;
    kD *= 1.0 - metallic;     
    
    vec3 irradiance = texture(irradiance_map, N).rgb;
    vec3 diffuse      = irradiance * albedo.rgb;
        
    // reduce artifacts from sampling
    float prefiltered_environment_mip_map_level = roughness * prefiltered_environment_map_max_lod;
    if (false)
    {
        vec3  H = normalize(V + R);
        float D = DistributionGGX(N, H, roughness);
        float NdotH = max(0, dot(N, H));
        float HdotV = max(0, dot(H, V));
        float pdf = (D * NdotH / (4.0 * HdotV)) + 0.0001; 

        float resolution = 512.0; // resolution of source cubemap (per face)
        float saTexel  = 4.0 * pi32 / (6.0 * resolution * resolution);
        float SAMPLE_COUNT = 1024;
        float saSample = 1.0 / (SAMPLE_COUNT * pdf + 0.0001);

        prefiltered_environment_mip_map_level = roughness == 0.0 ? 0.0 : 0.5 * log2(saSample / saTexel); 
    }
    
    // sample both the pre-filter map and the BRDF lut and combine them together as per the Split-Sum approximation to get the IBL specular part.    
    vec3 prefilteredColor = textureLod(prefiltered_environment_map, R, prefiltered_environment_mip_map_level).rgb;
    vec2 brdf  = texture(integrated_brdf_environment_map, vec2(max(dot(N, V), 0.0), roughness)).rg;
    vec3 specular = prefilteredColor * (F * brdf.x + brdf.y);

    f32 ao = 1;
    vec3 ambient = (kD * diffuse + specular) * ao;
    
    vec3 color = ambient + Lo;

    // HDR tonemapping
    #if !is_hdr
    #if 0
    color = apply_tone_mapping(color);
    #else
    color = color / (color + vec3(1.0));
    #endif
    #endif

    return vec4(color , 1.0);
}