
module math;

type box2 union
{
    expand extends struct
    {
        min vec2;
        max vec2;
    };

    expand vectors vec2[2];

    expand values f32[4];
};

func box2_size(expand min vec2, expand size vec2) (result box2)
{
    var box = { min, min + size } box2;
    return box;
}

func box2_center_size(expand center vec2, expand size vec2) (result box2)
{
    var half = (size * 0.5);
    return { center - half , center + half } box2;
}

func merge(a box2, b box2) (result box2)
{
    return { minimum(a.min, b.min), maximum(a.max, b.max) } box2;
}

func merge(box box2, point vec2) (result box2)
{
    return { minimum(box.min, point), maximum(box.max, point) } box2;
}

func cut(a box2, b box2) (result box2)
{
    return { maximum(a.min, b.min), minimum(a.max, b.max) } box2;
}

func get_intersection(a box2, b box2) (ok b8, intersection box2)
{
    var intersection box2;
    intersection.min = maximum(a.min, b.min);
    intersection.max = minimum(a.max, b.max);

    if (intersection.min.x >= intersection.max.x) or (intersection.min.y >= intersection.max.y)
        return false, {} box2;

    return true, intersection;
}

func intersects(a box2, b box2) (result b8)
{
    return not ((a.min.x >= b.max.x) or (b.min.x >= a.max.x) or (a.min.y >= b.max.y) or (b.min.y >= a.max.y));
    // return (a.max.x < b.min.x) and (b.max.x < a.min.x) and (a.max.y < b.min.y) and (b.max.y < a.min.y);
}

func is_contained(point vec2, box box2) (ok b8)
{
    return ((box.min.x <= point.x) and (point.x < box.max.x) and (box.min.y <= point.y) and (point.y < box.max.y));
}

func move(box box2, offset vec2) (result box2)
{
    return { box.min + offset, box.max + offset } box2;
}

func grow(box box2, thickness vec2) (result box2)
{
    return { box.min - (thickness * 0.5), box.max + (thickness * 0.5) } box2;
}

func grow(point vec2, thickness vec2) (result box2)
{
    return { point - (thickness * 0.5), point + (thickness * 0.5) } box2;
}

func grow(point vec2, thickness f32) (result box2)
{
    return { point - (thickness * 0.5), point + (thickness * 0.5) } box2;
}

func grow(box box2, thickness f32) (result box2)
{
    return grow(box, [ thickness, thickness ] vec2);
}

func get_size(box box2) (result vec2)
{
    return box.max - box.min;
}

func get_point(box box2, expand alignment vec2) (point vec2)
{
    var point = box.min + scale(alignment, box.max - box.min);
    return point;
}

func get_corners(box box2) (cornsers vec2[4])
{
    var corners vec2[4];

    loop var i; corners.count
    {
        corners[i] = get_point(box, [ i bit_and 1, (i bit_shift_right 1) bit_and 1 ] vec2);
    }

    return corners;
}

struct box3
{
    min vec3;
    max vec3;
}

func box3_size(expand min vec3, expand size vec3) (result box3)
{
    var result box3;
    result.min = min;
    result.max = min + size;
    return result;
}

func box3_center_size(expand center vec3, expand size vec3) (result box3)
{
    var half = (size * 0.5);
    return { center - half , center + half } box3;
}

func get_size(box box3) (result vec3)
{
    return box.max - box.min;
}

func merge(box box3, point vec3) (result box3)
{
    return { minimum(box.min, point), maximum(box.max, point) } box3;
}

func merge(a box3, b box3) (result box3)
{
    return { minimum(a.min, b.min), maximum(a.max, b.max) } box3;
}

func get_point(box box3, alignment vec3) (point vec3)
{
    var point = scale(box.min, (1 - alignment)) + scale(box.max, alignment);
    return point;
}

func transform_box(box_to_world mat_transform, box box3) (result box3)
{
    var result box3;
    result.min = transform(box_to_world, get_point(box, [0, 0, 0] vec3));
    result.max = result.min;

    loop var i u32 = 1; 8
    {
        var corner = [ i bit_and 1, (i bit_shift_right 1) bit_and 1, (i bit_shift_right 2) bit_and 1 ] vec3;
        var point = transform(box_to_world, get_point(box, corner));
        result.min = minimum(result.min, point);
        result.max = maximum(result.max, point);
    }

    return result;
}

func get_corners(box box3) (cornsers vec3[8])
{
    var corners vec3[8];

    loop var i; corners.count
    {
        corners[i] = get_point(box, [ i bit_and 1, (i bit_shift_right 1) bit_and 1, (i bit_shift_right 2) bit_and 1 ] vec3);
    }

    return corners;
}