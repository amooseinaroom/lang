
module memory;

import platform;
import math;

struct memory_arena
{
    used_byte_count   usize;
    commit_byte_count usize;
    total_byte_count  usize;

    base              u8 ref;
}

func init(arena memory_arena ref, total_byte_count = 2 cast(usize) bit_shift_left 30, commit_byte_count = 20 cast(usize) bit_shift_left 20, location = get_call_location())
{
    assert(arena.commit_byte_count <= arena.total_byte_count, location);

    arena.commit_byte_count = commit_byte_count;
    arena.total_byte_count = total_byte_count;
    arena.base = platform_memory_reserve(total_byte_count, location);
    platform_memory_commit(arena.base, arena.commit_byte_count, location);
}

func clear(arena memory_arena ref)
{
    arena.used_byte_count = 0;
}

func free(arena memory_arena ref, location = get_call_location())
{
    platform_memory_free(arena.base, location);
}

func allocate_type(arena memory_arena ref, type_info lang_type_info, location = get_call_location()) (result u8 ref)
{
    if type_info.indirection_count
    {
        type_info.byte_count     = 8;
        type_info.byte_alignment = 8;
    }
    
    return allocate(arena, type_info.byte_count, type_info.byte_alignment, location);
}

func allocate(arena memory_arena ref, typed_value lang_typed_value, location = get_call_location())
{
    assert(typed_value.type.indirection_count >= 2, "passed value needs to be a ref ref");

    typed_value.type.indirection_count -= 2;
    typed_value.base cast(u8 ref ref) deref = allocate_type(arena, typed_value.type, location);
}

func allocate_array(arena memory_arena ref, type_info lang_type_info, count usize, location = get_call_location()) (result u8 ref)
{    
    if type_info.indirection_count
    {
        type_info.byte_count     = 8;
        type_info.byte_alignment = 8;
    }
    
    return allocate(arena, type_info.byte_count * count, type_info.byte_alignment, location);
}

func allocate(arena memory_arena ref, byte_byte_count usize, byte_alignment u32, location = get_call_location()) (result u8 ref)
{
    var alignment_mask = (byte_alignment - 1) cast(usize);
    assert((alignment_mask bit_and byte_alignment cast(usize)) is 0, location);

    if not byte_byte_count
        return null;

    var base = ((arena.base cast(usize) + arena.used_byte_count + alignment_mask) bit_and bit_not alignment_mask) cast(u8 ref);
    //var padding = (base - arena.base - arena.used_byte_count) cast(usize);
    arena.used_byte_count = (base - arena.base) cast(usize) + byte_byte_count;

    if arena.used_byte_count > arena.commit_byte_count
    {
        require(arena.used_byte_count <= arena.total_byte_count, location);

        var commit_byte_count = minimum(arena.total_byte_count, maximum(arena.used_byte_count, arena.commit_byte_count) bit_shift_left 1);

        platform_memory_commit(arena.base + arena.commit_byte_count, commit_byte_count - arena.commit_byte_count, location);
        arena.commit_byte_count = commit_byte_count;
    }

    return base;
}

func free(arena memory_arena ref, base u8 ref, location = get_call_location())
{
    if not base
        return;

    assert((arena.base <= base) and (base <= (arena.base + arena.used_byte_count)));

    arena.used_byte_count = (base - arena.base) cast(usize);
    assert(arena.used_byte_count <= arena.commit_byte_count);
}

func reallocate_array(arena memory_arena ref, typed_value lang_typed_value, new_count usize, location = get_call_location())
{
    assert((typed_value.type.indirection_count is 1) and (typed_value.type.type_type is lang_type_info_type.array));

    var array_type = typed_value.type.array_type deref;
    assert(array_type.item_count is 0); // is not a fixed size array

    // all arrays have same structure (count, base)
    var base_array = typed_value.base_array;

    free(arena, base_array.base);

    base_array.count = new_count;
    base_array.base  = allocate_array(arena, array_type.item_type, new_count, location);
}

func temporary_begin(arena memory_arena ref) (used_byte_count usize)
{
    return arena.used_byte_count;
}

func temporary_end(arena memory_arena ref, temporary_begin_used_byte_count usize)
{
    arena.used_byte_count = temporary_begin_used_byte_count;
}