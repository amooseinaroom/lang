module math;

type mat_projection mat4;
type mat_transform  mat4;

type mat4 union
{    
    expand transform_columns struct
    {
        right_column       vec4;
        up_column          vec4;
        forward_column     vec4;
        translation_column vec4;
    };
            
    expand transform struct
    {
        right       vec3; right_w       f32;
        up          vec3; up_w          f32;
        forward     vec3; forward_w     f32;
        translation vec3; translation_w f32;
    };

    expand columns vec4[4];

    values f32[16];
};

type mat4x3 union
{
    expand transform struct
    {
        right       vec3;
        up          vec3;
        forward     vec3;
        translation vec3;
    };
    
    expand columns vec3[4];
    
    values f32[12];
};

def mat4_identity =
[
    [ 1, 0, 0, 0 ] vec4,
    [ 0, 1, 0, 0 ] vec4,
    [ 0, 0, 1, 0 ] vec4,
    [ 0, 0, 0, 1 ] vec4,
] mat4;

def mat_projection_identity = mat4_identity;
def mat_transform_identity  = mat4_identity;

def mat4x3_identity =
[
    [ 1, 0, 0 ] vec3,
    [ 0, 1, 0 ] vec3,
    [ 0, 0, 1 ] vec3,
    [ 0, 0, 0 ] vec3,
] mat4x3;

func multiply(transform mat4, vector vec4) (result vec4)
{
    var result = transform[0] * vector[0];
    loop var column = 1; transform.count
    {
        result = result + (transform[column] * vector[column]);
    }
    
    return result;
}

func transform(transformation mat4, vector vec3, w = 1.0) (result vec3)
{
    return vec3_cut(transformation * vec4_expand(vector, w));
}

func project(projection mat4, position vec3) (result vec3)
{
    return vec3_project(projection * vec4_expand(position, 1));
}

func multiply(second mat4, first mat4) (result mat4)
{
    var result mat4;
    loop var column; first.count
    {
        result[column] = second * first[column];
    }
    
    return result;
}

// order: scale, rotate and then translate
func mat4_transform(rotation = quat_identity, translation = {} vec3, scale = [ 1, 1, 1 ] vec3) (transform mat4)
{
    var result mat4;
    var xx = rotation.x * rotation.x;
    var xy = rotation.x * rotation.y;
    var xz = rotation.x * rotation.z;
    
    var yy = rotation.y * rotation.y;
    var yz = rotation.y * rotation.z;
    
    var zz = rotation.z * rotation.z;
    
    var wx = rotation.w * rotation.x;
    var wy = rotation.w * rotation.y;
    var wz = rotation.w * rotation.z;
    
    result[0][0] = (1 - (2 * (yy + zz)))  * scale[0];
    result[1][0] =       2 * (xy - wz) 	  * scale[1];
    result[2][0] =       2 * (xz + wy)	  * scale[2];
    
    result[0][1] =       2 * (xy + wz)	  * scale[0];
    result[1][1] = (1 - (2 * (xx + zz)))  * scale[1];
    result[2][1] =       2 * (yz - wx)	  * scale[2];
    
    result[0][2] =       2 * (xz - wy)	  * scale[0];
    result[1][2] =       2 * (yz + wx)	  * scale[1];
    result[2][2] = (1 - (2 * (xx + yy))	) * scale[2];
    
    result[3] = vec4_expand(translation, 1);
    
    return result;
}

// order: scale, rotate and then translate
func mat4_transform(rotation_axis vec3, rotation_angle radians_f32, translation = {} vec3, scale = [ 1, 1, 1 ] vec3) (transform mat4)
{
    var rotation = quat_axis_angle(rotation_axis, rotation_angle);
    var result = mat4_transform(rotation, translation, scale);
    return result;
}

func mat4_camera_to_world_look_at(center vec3, target vec3, relative_up vec3) (transform mat4)
{
    // camera forward points in opposite to the camera view direction
    var forward = normalize(center - target); // is flipped
    var right   = normalize(cross(relative_up, forward));
    var up      = cross(forward, right);
    
    var result =
    [
        vec4_expand(right),
        vec4_expand(up),
        vec4_expand(forward),
        vec4_expand(center, 1)
    ] mat4;
    return result;
}

func mat4_camera_to_world_orbit(target vec3, view_direction vec3, distance f32, relative_up vec3) (transform mat4)
{
    var forward     = normalize(view_direction);
    var right       = normalize(cross(relative_up, forward));
    var up          = cross(forward, right);
    var translation = target + (forward * distance);
    
    var result =
    [
        vec4_expand(right),
        vec4_expand(up),
        vec4_expand(forward),
        vec4_expand(translation, 1)
    ] mat4;
    
    return result;
}

func mat4_inverse_transform(transform mat4) (inverse mat4)
{
    var inverse_scale vec3;
    loop var i; 3
    {
        var column = [ transform[i][0], transform[i][1], transform[i][2] ] vec3;
        inverse_scale[i] = 1.0 / length(column);
    }
        
    var result mat4;
    loop var x; 3
    {
        loop var y; 3
        {
            result[x][y] = transform[y][x] * inverse_scale[y];
        }
    }
    
    result[3][3] = 1;
    result[3] = result * vec4_expand(-vec3_cut(transform[3]), 1);
    return result;
}

func mat4_inverse_transform_unscaled(transform mat4) (inverse mat4)
{
    var result mat4;
    loop var x; 3
    {
        loop var y; 3
        {
            result[x][y] = transform[y][x];
        }
    }
    
    result[3][3] = 1;
    result[3] = result * vec4_expand(-vec3_cut(transform[3]), 1);
    return result;
}

// projection matrix
// a | 0 | 0 | 0
// 0 | b | 0 | 0
// 0 | 0 | c | d
// 0 | 0 | e | 0
func mat4_perspective_projection(a f32, b f32, c f32, d f32, e f32) (projection mat4)
{
    var result mat4;
    result[0][0] = a;
    result[1][1] = b;
    result[2][2] = c;
    result[3][2] = d;
    result[2][3] = e;
    
    return result;
}

func mat4_perspective_projection(width f32, height f32, near_plane = 0.01, far_plane = 1000.0) (projection mat4)
{
    var a = 2 * near_plane / width;
    var b = 2 * near_plane / height;
    var c = -    (far_plane + near_plane) / (far_plane - near_plane);
    var d = - 2 * far_plane * near_plane  / (far_plane - near_plane);
    var e = -1;
    
    return mat4_perspective_projection(a, b, c, d, e);
}

func mat4_perspective_projection_fov(fov_y f32, width_over_height f32, near_plane = 0.01, far_plane = 1000.0) (projection mat4)
{
    var height = 2 * near_plane * tan(fov_y * 0.5);
    var width = width_over_height * height;
    return mat4_perspective_projection(width, height, near_plane, far_plane);
}

// inverse projection matrix
// 1 / a |     0 |     0 |            0
// 0     | 1 / b |     0 |            0
// 0     |     0 |     0 |        1 / e
// 0     |     0 | 1 / d | -c / (d * e)
func mat4_inverse_perspective_projection(a f32, b f32, c f32, d f32, e f32) (inverse_projection mat4)
{
    var result mat4;
    result[0][0] = 1 / a;
    result[1][1] = 1 / b;
    result[2][3] = 1 / d;
    result[3][2] = 1 / e;
    result[3][3] = -c / (d * e);
    
    return result;
}

func mat4_inverse_perspective_projection(projection mat4) (inverse_projection mat4)
{
    return mat4_inverse_perspective_projection(projection[0][0], projection[1][1], projection[2][2], projection[3][2], projection[2][3]);
}

func mat4_orthographic_projection(width f32, height f32, near_plane = 0.01, far_plane = 100.0) (projection mat4)
{
    var result mat4;
    result[0][0] = 2.0 / width;
    result[1][1] = 2.0 / height;
    result[2][2] = 2.0 / (near_plane - far_plane);
    result[3][2] = (near_plane + far_plane) / (near_plane - far_plane);
    result[3][3] = 1.0;
    
    return result;
}

func mat4_inverse_orthographic_projection(orthographic_projection mat4) (inverse_projection mat4)
{
    var result mat4;
    result[0][0] = 1.0 / orthographic_projection[0][0];
    result[1][1] = 1.0 / orthographic_projection[1][1];
    result[2][2] = 1.0 / orthographic_projection[2][2];
    result[3][2] = orthographic_projection[3][2] / -orthographic_projection[2][2];
    result[3][3] = 1.0;
    
    return result;
}
