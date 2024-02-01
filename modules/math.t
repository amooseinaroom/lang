
module math;

def pi32  = 3.14159265358979323846;
def tau32 = 6.28318530717958647692;

type seconds_f32 f32;
type radians_f32 f32;

func sqrt(_X f64) (result f64)       calling_convention "__cdecl" extern_binding("kernel32", false);
func sin(_X f64) (result f64)        calling_convention "__cdecl" extern_binding("kernel32", false);
func cos(_X f64) (result f64)        calling_convention "__cdecl" extern_binding("kernel32", false);
func tan(_X f64) (result f64)        calling_convention "__cdecl" extern_binding("kernel32", false);
func fmod(a f64, b f64) (result f64) calling_convention "__cdecl" extern_binding("kernel32", false);
func pow(a f64, b f64) (result f64)  calling_convention "__cdecl" extern_binding("kernel32", false);

func asin(_X f64) (result f64)       calling_convention "__cdecl" extern_binding("kernel32", false);
func acos(_X f64) (result f64)       calling_convention "__cdecl" extern_binding("kernel32", false);
func atan2(_Y f64, _X f64) (result f64) calling_convention "__cdecl" extern_binding("kernel32", false);

func floor(_X f64) (result f64) calling_convention "__cdecl" extern_binding("kernel32", false);
func ceil(_X f64)  (result f64) calling_convention "__cdecl" extern_binding("kernel32", false);

func floorf(_X f32) (result f32) calling_convention "__cdecl" extern_binding("kernel32", false);
func ceilf(_X f32)  (result f32) calling_convention "__cdecl" extern_binding("kernel32", false);

func sqrt(_X f32) (result f32)
{
    return sqrt(_X cast(f64)) cast(f32);
}

func sin(_X f32) (result f32)
{
    return sin(_X cast(f64)) cast(f32);
}

func cos(_X f32) (result f32)
{
    return cos(_X cast(f64)) cast(f32);
}

func tan(_X f32) (result f32)
{
    return tan(_X cast(f64)) cast(f32);
}

func fmod(a f32, b f32) (result f32)
{
    return fmod(a cast(f64), b cast(f64)) cast(f32);
}

func pow(a f32, b f32) (result f32)
{
    return pow(a cast(f64), b cast(f64)) cast(f32);
}

func asin(_X f32) (result f32)
{
    return asin(_X cast(f64)) cast(f32);
}

func acos(_X f32) (result f32)
{
    return acos(_X cast(f64)) cast(f32);
}

func atan2(_Y f32, _X f32) (result f32)
{
    return atan2(_Y cast(f64), _X cast(f64)) cast(f32);
}

func absolute(value f32) (result f32)
{
    if value < 0
        return -value;
    else
        return value;
}

func sign(value f32) (result f32)
{
    if value < 0
        return -1.0;
    else
        return 1.0;
}

func sign_or_zero(value f32) (result f32)
{
    if value is 0.0
        return 0.0;

    return sign(value);
}

func absolute(value f64) (result f64)
{
    if value < 0
        return -value;
    else
        return value;
}

func minimum(a f32, b f32) (result f32)
{
    if a <= b
        return a;
    else
        return b;
}

func maximum(a f32, b f32) (result f32)
{
    if a > b
        return a;
    else
        return b;
}

func clamp(a f32, min f32, max f32) (result f32)
{
    if a < min
        return min;
    else if a > max
        return max;
    else
        return a;
}

func floor(value f32) (result f32)
{
    return floorf(value);
}

func ceil(value f32) (result f32)
{
    return ceilf(value);
}

func lerp(from f32, to f32, ratio f32) (result f32)
{
    return (from * (1 - ratio)) + (to * ratio);
}

func minimum(a s32, b s32) (result s32)
{
    if a <= b
        return a;
    else
        return b;
}

func maximum(a s32, b s32) (result s32)
{
    if a > b
        return a;
    else
        return b;
}

func absolute(value s32) (result s32)
{
    if value < 0
        return -value;
    else
        return value;
}

func sign(value s32) (result s32)
{
    if value < 0
        return -1.0;
    else
        return 1.0;
}

func clamp(a s32, min s32, max s32) (result s32)
{
    if a < min
        return min;
    else if a > max
        return max;
    else
        return a;
}

func minimum(a u32, b u32) (result u32)
{
    if a <= b
        return a;
    else
        return b;
}

func maximum(a u32, b u32) (result u32)
{
    if a > b
        return a;
    else
        return b;
}

func minimum(a usize, b usize) (result usize)
{
    if a <= b
        return a;
    else
        return b;
}

func maximum(a usize, b usize) (result usize)
{
    if a > b
        return a;
    else
        return b;
}

// TODO: move somewhere sane?

type rgba8 union
{
    expand rgba struct
    {
        r u8;
        g u8;
        b u8;
        a u8;
    };

    expand rgba_alias struct
    {
        red   u8;
        green u8;
        blue  u8;
        alpha u8;
    };

    expand values u8[4];
};

def rgba8_black = [ 0, 0, 0, 255 ] rgba8;
def rgba8_white = [ 255, 255, 255, 255 ] rgba8;

func lerp(from rgba8, to rgba8, factor f32) (result rgba8)
{
    var one_minus_factor = 1 - factor;
    loop var i; from.count
        from[i] = ((from[i] * one_minus_factor) + (to[i] * factor)) cast(u8);

    return from;
}

func fast_in_slow_out(ratio f32) (result f32)
{
    assert((0 <= ratio) and (ratio <= 1));
    return sqrt(ratio);
}

func slow_in_fast_out(ratio f32) (result f32)
{
    assert((0 <= ratio) and (ratio <= 1));
    return ratio * ratio;
}

func apply_spring(current f32, target f32, strength f32, delta_seconds f32) (next f32)
{
    var delta = target - current;
    current += delta * (strength * 0.5 * delta_seconds * delta_seconds);
    return current;
}

func apply_spring(current vec2, target vec2, strength f32, delta_seconds f32) (next vec2)
{
    var delta = target - current;
    current += delta * (strength * 0.5 * delta_seconds * delta_seconds);
    return current;
}

func apply_spring(current vec3, target vec3, strength f32, delta_seconds f32) (next vec3)
{
    var delta = target - current;
    current += delta * (strength * 0.5 * delta_seconds * delta_seconds);
    return current;
}