
module math;

import platform;

type vec2 union
{
    expand xy     struct { x     f32; y      f32; };
    expand size   struct { width f32; height f32; };
    expand values f32[2];
};

type vec3 union
{
    expand xyz    struct { x   f32; y     f32; z    f32; };
    expand rgb    struct { r   f32; g     f32; b    f32; };
    expand color  struct { red f32; green f32; blue f32; };
    expand values f32[3];

    xy vec2;
    rb vec2;
};

type vec4 union
{
    expand xyzw   struct { x   f32; y     f32; z    f32; w     f32; };
    expand rgba   struct { r   f32; g     f32; b    f32; a     f32; };
    expand color  struct { red f32; green f32; blue f32; alpha f32; };
    expand values f32[4];

    xyz vec3;
    rgb vec3;
};

type rgbaf32 vec4;

func vec4_expand(vector vec3, w = 0.0) (result vec4)
{
    var result = [ vector[0], vector[1], vector[2], w ] vec4;
    return result;
}

func vec3_project(point vec4) (result vec3)
{
    return vec3_cut(point) * (1 / point[3]);
}

func vec3_cut(vector vec4) (result vec3)
{
    var result = [ vector[0], vector[1], vector[2] ] vec3;
    return result;
}

func vec3_expand(vector vec2, z = 0.0) (result vec3)
{
    var result = [ vector[0], vector[1], z ] vec3;
    return result;
}

func v3(x f32, y f32, z f32) (result vec3)
{
    return [ x, y, z ] vec3;
}

func v3(scale f32) (result vec3)
{
    return [ scale, scale, scale ] vec3;
}

func vec3_expand_swizzle(vector vec2, x_index = 0, y_index = 1, z = 0.0) (result vec3)
{
    assert(x_index + y_index <= 3);
    assert(x_index is_not y_index);

    var result vec3;
    result[x_index] = vector[0];
    result[y_index] = vector[1];
    result[3 - y_index - x_index] = z;
    return result;
}

func v2(expand vector vec2s) (result vec2)
{
    return [ vector.x, vector.y ] vec2;
}

func v2(x f32, y f32) (result vec2)
{
    return [ x, y ] vec2;
}

func v2(scale f32) (result vec2)
{
    return [ scale, scale ] vec2;
}

func v2s(expand vector vec2) (result vec2s)
{
    return [ vector.x cast(s32), vector.y cast(s32) ] vec2s;
}

func vec2_cut(vector vec3, x_index = 0, y_index = 1) (result vec2)
{
    var result = [ vector[x_index], vector[y_index] ] vec2;
    return result;
}

func add(a vec2, b f32) (result vec2)
{
    var result vec2;
    loop var i; a.count
    {
        result[i] = a[i] + b;
    }

    return result;
}

func add(a vec2, b vec2) (result vec2)
{
    var result vec2;
    loop var i; a.count
    {
        result[i] = a[i] + b[i];
    }

    return result;
}

func negate(a vec2) (result vec2)
{
    var result vec2;
    loop var i; a.count
    {
        result[i] = -a[i];
    }

    return result;
}

func subtract(a vec2, b vec2) (result vec2)
{
    var result vec2;
    loop var i; a.count
    {
        result[i] = a[i] - b[i];
    }

    return result;
}

func subtract(vector vec2, scalar f32) (result vec2)
{
    var result vec2;
    loop var i; vector.count
    {
        result[i] = vector[i] - scalar;
    }

    return result;
}

func subtract(scalar f32, vector vec2) (result vec2)
{
    var result vec2;
    loop var i; vector.count
    {
        result[i] = scalar - vector[i];
    }

    return result;
}

func multiply(vector vec2, scalar f32) (result vec2)
{
    var result vec2;
    loop var i; vector.count
    {
        result[i] = vector[i] * scalar;
    }

    return result;
}

func divide(scalar f32, vector vec2) (result vec2)
{
    var result vec2;
    loop var i; vector.count
    {
        result[i] = scalar / vector[i];
    }

    return result;
}

func scale(a vec2, b vec2) (result vec2)
{
    var result vec2;
    loop var i; a.count
    {
        result[i] = a[i] * b[i];
    }

    return result;
}

func dot(a vec2, b vec2) (result f32)
{
    var result = a[0] * b[0];
    loop var i = 1; a.count
    {
        result = (a[i] * b[i]) + result;
    }

    return result;
}

func squared_length(vector vec2) (result f32)
{
    var result = dot(vector, vector);
    return result;
}

func length(vector vec2) (result f32)
{
    var result = sqrt(squared_length(vector));
    return result;
}

func normalize(vector vec2) (result vec2)
{
    var inverse_length = 1.0 / length(vector);
    vector[0] = vector[0] * inverse_length;
    vector[1] = vector[1] * inverse_length;

    return vector;
}

func normalize_or_zero(vector vec2) (result vec2)
{
    var vector_squared_length = squared_length(vector);
    if vector_squared_length > 0
        return normalize(vector);
    else
        return {} vec2;
}

func rotate_counter_clockwise(vector vec2) (result vec2)
{
    return [ -vector.y, vector.x ] vec2;
}

func lerp(from vec2, to vec2, ratio vec2) (result vec2)
{
    var one_minus_ratio = 1 - ratio;
    return scale(from, one_minus_ratio) + scale(to, ratio);
}

func lerp(from vec2, to vec2, ratio f32) (result vec2)
{
    return lerp(from, to, [ ratio, ratio ] vec2);
}

func minimum(a vec2, b vec2) (result vec2)
{
    return [ minimum(a[0], b[0]), minimum(a[1], b[1]) ] vec2;
}

func maximum(a vec2, b vec2) (result vec2)
{
    return [ maximum(a[0], b[0]), maximum(a[1], b[1]) ] vec2;
}

func floor(vector vec2) (result vec2)
{
    return [ floor(vector.x), floor(vector.y) ] vec2;
}

func ceil(vector vec2) (result vec2)
{
    return [ ceil(vector.x), ceil(vector.y) ] vec2;
}

// vec3

func add(a vec3, b f32) (result vec3)
{
    var result vec3;
    loop var i; a.count
    {
        result[i] = a[i] + b;
    }

    return result;
}

func add(a vec3, b vec3) (result vec3)
{
    var result vec3;
    loop var i; a.count
    {
        result[i] = a[i] + b[i];
    }

    return result;
}

func negate(a vec3) (result vec3)
{
    var result vec3;
    loop var i; a.count
    {
        result[i] = -a[i];
    }

    return result;
}

func subtract(a vec3, b vec3) (result vec3)
{
    var result vec3;
    loop var i; a.count
    {
        result[i] = a[i] - b[i];
    }

    return result;
}

func subtract(scalar f32, vector vec3) (result vec3)
{
    var result vec3;
    loop var i; vector.count
    {
        result[i] = scalar - vector[i];
    }

    return result;
}

func subtract(vector vec3, scalar f32) (result vec3)
{
    var result vec3;
    loop var i; vector.count
    {
        result[i] = vector[i] - scalar;
    }

    return result;
}

func multiply(vector vec3, scalar f32) (result vec3)
{
    var result vec3;
    loop var i; vector.count
    {
        result[i] = vector[i] * scalar;
    }

    return result;
}

func divide(a vec3, b vec3) (result vec3)
{
    var result vec3;
    loop var i; a.count
    {
        result[i] = a[i] / b[i];
    }

    return result;
}

// maybe a bad name, since lots of things are called scale
func scale(a vec3, b vec3) (result vec3)
{
    var result vec3;
    loop var i; a.count
    {
        result[i] = a[i] * b[i];
    }

    return result;
}

func dot(a vec3, b vec3) (result f32)
{
    var result = a[0] * b[0];
    loop var i = 1; a.count
    {
        result = (a[i] * b[i]) + result;
    }

    return result;
}

// using right hand rule
func cross(right_thumb vec3, right_index vec3) (right_middle vec3)
{
    var right_middle =
    [
        (right_thumb[1] * right_index[2]) - (right_thumb[2] * right_index[1]),
        (right_thumb[2] * right_index[0]) - (right_thumb[0] * right_index[2]),
        (right_thumb[0] * right_index[1]) - (right_thumb[1] * right_index[0]),
    ] vec3;

    return right_middle;
}

func squared_length(vector vec3) (result f32)
{
    var result = dot(vector, vector);
    return result;
}

func length(vector vec3) (result f32)
{
    var result = sqrt(squared_length(vector));
    return result;
}

func normalize(vector vec3) (result vec3)
{
    var inverse_length = 1.0 / length(vector);
    vector[0] = vector[0] * inverse_length;
    vector[1] = vector[1] * inverse_length;
    vector[2] = vector[2] * inverse_length;

    return vector;
}


func normalize_or_zero(vector vec3) (result vec3)
{
    var vector_squared_length = squared_length(vector);
    if vector_squared_length > 0
        return normalize(vector);
    else
        return {} vec3;
}

func minimum(a vec3, b vec3) (result vec3)
{
    return [ minimum(a[0], b[0]), minimum(a[1], b[1]), minimum(a[2], b[2]) ] vec3;
}

func maximum(a vec3, b vec3) (result vec3)
{
    return [ maximum(a[0], b[0]), maximum(a[1], b[1]), maximum(a[2], b[2]) ] vec3;
}

func lerp(from vec3, to vec3, ratio vec3) (result vec3)
{
    var one_minus_ratio = 1 - ratio;
    return scale(from, one_minus_ratio) + scale(to, ratio);
}

func lerp(from vec3, to vec3, ratio f32) (result vec3)
{
    var one_minus_ratio = 1 - ratio;
    return (from * one_minus_ratio) + (to * ratio);
}

func reflect(normal vec3, in_direction vec3) (out_direction vec3)
{
    var out_direction = in_direction - (normal * (dot(normal, in_direction) * 2));
    return out_direction;
}

// vec4

func to_rgba8(color vec4) (result rgba8)
{
    return [ (color.r * 255) cast(u8), (color.g * 255) cast(u8), (color.b * 255) cast(u8), (color.a * 255) cast(u8) ] rgba8;
}

func to_premultiplied_rgba8(color vec4) (result rgba8)
{
    return [ (color.r * color.a * 255) cast(u8), (color.g * color.a * 255) cast(u8), (color.b * color.a * 255) cast(u8), (color.a * 255) cast(u8) ] rgba8;
}

func to_vec4(color rgba8) (result vec4)
{
    return [ color.r / 255.0, color.g / 255.0, color.b / 255.0, color.a / 255.0 ] vec4;
}

func negate(a vec4) (result vec4)
{
    var result vec4;
    loop var i; a.count
    {
        result[i] = -a[i];
    }

    return result;
}

func add(a vec4, b vec4) (result vec4)
{
    var result vec4;
    loop var i; a.count
    {
        result[i] = a[i] + b[i];
    }

    return result;
}

func subtract(a vec4, b vec4) (result vec4)
{
    var result vec4;
    loop var i; a.count
    {
        result[i] = a[i] - b[i];
    }

    return result;
}

func subtract(vector vec4, scalar f32) (result vec4)
{
    var result vec4;
    loop var i; vector.count
    {
        result[i] = vector[i] - scalar;
    }

    return result;
}

func multiply(vector vec4, scalar f32) (result vec4)
{
    var result vec4;
    loop var i; vector.count
    {
        result[i] = vector[i] * scalar;
    }

    return result;
}

func dot(a vec4, b vec4) (result f32)
{
    var result = a[0] * b[0];
    loop var i = 1; a.count
    {
        result = (a[i] * b[i]) + result;
    }

    return result;
}

func length(vector vec4) (result f32)
{
    var result = sqrt(dot(vector, vector));
    return result;
}

func normalize(vector vec4) (result vec4)
{
    var inverse_length = 1.0 / length(vector);
    vector[0] = vector[0] * inverse_length;
    vector[1] = vector[1] * inverse_length;
    vector[2] = vector[2] * inverse_length;
    vector[3] = vector[3] * inverse_length;

    return vector;
}

func lerp(from vec4, to vec4, ratio f32) (result vec4)
{
    var one_minus_ratio = 1 - ratio;
    var result =
    [
        (from[0] * one_minus_ratio) + (to[0] * ratio),
        (from[1] * one_minus_ratio) + (to[1] * ratio),
        (from[2] * one_minus_ratio) + (to[2] * ratio),
        (from[3] * one_minus_ratio) + (to[3] * ratio),
    ] vec4;

    return result;
}

// using right hand rule
func cross(right_thumb vec4, right_index vec4) (right_middle vec4)
{
    var right_middle =
    [
        (right_thumb[1] * right_index[2]) - (right_thumb[2] * right_index[1]),
        (right_thumb[2] * right_index[3]) - (right_thumb[3] * right_index[2]),
        (right_thumb[3] * right_index[0]) - (right_thumb[0] * right_index[3]),
        (right_thumb[0] * right_index[1]) - (right_thumb[1] * right_index[0]),
    ] vec4;

    return right_middle;
}