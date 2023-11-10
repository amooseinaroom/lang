module random;

import platform;

type random_pcg u64;

func rotate_right(value u32, amount u32) (result u32)
{
    var result = (value bit_shift_left amount) bit_or (value bit_shift_right (32 - amount));
    return result;
}

func random_u32(random random_pcg ref) (result u32)
{
    var state = random deref;
    
    // LCG for internal state advance
    random deref = state * 6364136223846793005 + 1; // + 1 could be any odd random number
    
    // rotated xorshift for result
    var result = rotate_right(((state bit_xor (state bit_shift_left 18)) bit_shift_right 27) cast(u32), (state bit_shift_right 59) cast(u32));
    return result;
}

func random_index(random random_pcg ref, count u32) (result u32)
{
    var index = random_u32(random);
    index = index mod count;
    
    return index;
}

func random_f32_zero_to_one(random random_pcg ref) (result f32)
{
    var result = random_u32(random) cast(f32) / 0xFFFFFFFF;
    return result;
}

func random_f32_minus_one_to_plus_one(random random_pcg ref) (result f32)
{
    var result = (random_f32_zero_to_one(random) * 2.0) - 1.0;
    return result;
}

func random_f32_range(random random_pcg ref, min f32, max f32) (result f32)
{
    assert(max >= min);
    var result = random_f32_zero_to_one(random) * (max - min) + min;
    return result;
}
