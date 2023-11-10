
module math;

type quat union
{
    expand wxyz   struct { w f32; x f32; y f32; z f32; };
    expand values f32[4];
};

def quat_identity = { 1, 0, 0, 0 } quat;

func quat_axis_cos_sin(normalized_rotation_axis vec3, cos_value f32, sin_value f32) (result quat)
{
    //assert(are_close(length(normalized_rotation_axis), (f32)1));
        
    var result =
    {
        cos_value,
        normalized_rotation_axis[0] * sin_value,
        normalized_rotation_axis[1] * sin_value,
        normalized_rotation_axis[2] * sin_value,
    } quat;
    
    return result;
}

func quat_axis_angle(normalized_rotation_axis vec3, angle radians_f32) (result quat)
{
    angle = angle * 0.5;
    var cos_value = cos(angle cast(f32));
    var sin_value = sin(angle cast(f32));
    
    return quat_axis_cos_sin(normalized_rotation_axis, cos_value, sin_value);
}

func quat_between_normals(from_normal vec3, to_normal vec3) (result quat)
{
    var normalized_rotation_axis = cross(from_normal, to_normal);
    var angle = acos(dot(from_normal, to_normal));
    //var cos_value =  * 0.5;
    //var sin_value = sqrt(1 - (cos_value * cos_value));
    //return quat_axis_cos_sin(normalized_rotation_axis, cos_value, sin_value);
    
    return quat_axis_angle(normalized_rotation_axis, angle);
}

func negate(value quat) (result quat)
{
    var result quat = value;
    result.w = -result.w;
    
    return result;
}

func multiply(second quat, first quat) (result quat)
{
    var result = 
    {
        (first.w * second.w) - (first.x * second.x) - (first.y * second.y) - (first.z * second.z),
        (first.w * second.x) + (first.x * second.w) + (first.y * second.z) - (first.z * second.y),
        (first.w * second.y) - (first.x * second.z) + (first.y * second.w) + (first.z * second.x),
        (first.w * second.z) + (first.x * second.y) - (first.y * second.x) + (first.z * second.w)
    } quat;
    
    return result;
}

func inverse(value quat) (result quat)
{
    var inverse_length_squared = -1.0 / (value.w * value.w + value.x * value.x + value.y * value.y + value.z * value.z);
    
    var result =
    {
        value.w * inverse_length_squared,
        value.x * inverse_length_squared,
        value.y * inverse_length_squared,
        value.z * inverse_length_squared,
    } quat;
    
    return result;
}

// fast lerp, instead of accurate slerp
func lerp_and_normalize(a quat, b quat, ratio f32) (result quat)
{
    // cast to vec4 so we can use vec4 operators
    var a_vec4 = a ref cast(vec4 ref) deref;
    var b_vec4 = b ref cast(vec4 ref) deref;
    
    var result_vec4 = normalize(lerp(a_vec4, b_vec4, ratio));
    var result = result_vec4 ref cast(quat ref) deref;
    
    return result;
}
