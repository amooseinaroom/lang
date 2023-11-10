module meta;

func to_u8_array(array lang_typed_value) (data u8[])
{
    assert((array.type.type_type is lang_type_info_type.array) and (not array.type.indirection_count));
    
    var item_byte_count = array.type.array_type.item_type.byte_count;
    
    var base_array = array.base_array deref;
    
    var data u8[];
    data.count = item_byte_count * base_array.count;
    data.base  = base_array.base;
    
    return data;
}

func value_to_u8_array(typed_value lang_typed_value) (data u8[])
{
    assert((typed_value.type.type_type is_not lang_type_info_type.array) and (not typed_value.type.indirection_count));
    
    var data u8[];
    data.count = typed_value.type.byte_count;
    data.base  = typed_value.base;
    
    return data;
}

func sub_array(location = get_call_location(), array lang_typed_value, offset usize, count = -1 cast(usize)) (sub_array lang_base_array)
{
    assert(not array.type.array_type.item_count, "array must be a dynamic array", location);

    var sub_array = array.base_array deref;
    assert(offset <= sub_array.count);

    if count is -1 cast(usize)
        count = sub_array.count - offset;
    
    assert(offset + count <= sub_array.count);        
    sub_array.base += array.type.array_type.item_type.byte_count * offset;
    sub_array.count = count;
    
    return sub_array;
}

multiline_comment
{ 
    broken!!
    
    // HACK:
    func sub_array(array lang_typed_value, offset usize, count usize = -1 cast(usize)) (value lang_typed_value)
    {
        assert((array.type.type_type is lang_type_info_type.array) and (not array.type.indirection_count));
        
        var item_byte_count = array.type.array_type.item_type.byte_count;
        
        var value = array.array;
        assert(offset <= value.count); // support sub array of count 0
        
        if count is (-1 cast(usize))
            count = value.count - offset;
        
        assert(offset + count <= value.count);
        
        value.count = count;
        value.base  += item_byte_count * offset;
        
        return array;
    }
    
    func insert(lang_typed_value buffer, used_count usize, insert_offset usize, expand items = {} lang_typed_value[]) (new_used_count usize)
    {
        assert(buffer.type_type is lang_type_info_type.array);
        var base_buffer = buffer.base_array deref;

        assert(used_count < base_buffer.count);
        assert(insert_offset <= used_count);
        assert((used_count + items.count) < base_buffer.count);

        copy_array()
    }

    func insert(memory memory_arena ref, a lang_typed_value, index usize, b lang_typed_value)
{
    assert((a.type.type_type is lang_type_info_type.array) and (a.type.indirection_count));
    assert((b.type.type_type is lang_type_info_type.array) and (not b.type.indirection_count));
    assert(a.type.reference is b.type.reference);

    var item_byte_count = a.type.array_type.item_type.byte_count;

    var a_base_array = a.base_array deref;
    var b_base_array = b.base_array deref;
    assert(index <= a_base_array.count);
    
    reallocate_array(memory, a, a_base_array.count + b_base_array.count);
    
    {
        var from = { (a_base_array.count - index) * item_byte_count, a_base_array.base + (index * item_byte_count) } u8[];
        var to   = { from.count, a_base_array.base + ((index + b_base_array.count) * item_byte_count) } u8[];
        copy_bytes(to, from);
    }
    
    {
        var from = { b_base_array.count * item_byte_count, b_base_array.base } u8[];
        var to   = { from.count, a_base_array.base + (index * item_byte_count) } u8[];
        copy_bytes(to, from);
    }
}


func remove(memory memory_arena ref, array lang_typed_value, index usize, count usize)
{
    assert((array.type.type_type is lang_type_info_type.array) and (array.type.indirection_count));

    var item_byte_count = array.type.array_type.item_type.byte_count;
    
    var base_array = array.base_array deref;
    assert(index <= base_array.count);
    assert(index + count <= base_array.count);
    
    {
        var to = { (base_array.count - count - index) * item_byte_count, base_array.base + (index * item_byte_count) } u8[];
        var from = { from.count, base_array.base + ((index + count) * item_byte_count) } u8[];
        copy_bytes(to, from);
    }

    reallocate_array(memory, array, base_array.count - count);
}


}

// HACK:
func copy_array(to lang_typed_value, from lang_typed_value)
{
    assert((to.type.type_type is lang_type_info_type.array) and (not to.type.indirection_count));
    assert(to.type.reference is from.type.reference);
    
    copy_bytes(to_u8_array(to), to_u8_array(from));
}

func move_array(array lang_typed_value, offset usize, count = -1 cast(usize))
{
    assert((array.type.type_type is lang_type_info_type.array) and (not array.type.indirection_count));
    
    var base_array = array.base_array deref;
    
    assert(offset <= base_array.count); // support sub array of count 0
    
    if count is -1 cast(usize)
        count = base_array.count - offset;
        
    assert(offset + count <= base_array.count);
        
    var item_byte_count = array.type.array_type.item_type.byte_count;
    
    var to u8[];
    to.count = (base_array.count - count - offset) * item_byte_count;
    to.base  = base_array.base + (offset * item_byte_count);
    
    var from = to;
    from.base += count * item_byte_count;
    
    copy_bytes(to, from);
}

func insert(buffer lang_typed_value, used_count_ref u32 ref, index usize, insert_count usize, location = get_call_location())
{
    var used_count usize = used_count_ref deref;
    insert(buffer, used_count ref, index, insert_count, location);
    used_count_ref deref = used_count cast(u32);
}

func insert(buffer lang_typed_value, used_count_ref usize ref, index usize, insert_count usize, location = get_call_location())
{
    assert((buffer.type.type_type is lang_type_info_type.array) and (not buffer.type.indirection_count), location);

    var item_byte_count = buffer.type.array_type.item_type.byte_count;    
    
    var base_array lang_base_array;
    if buffer.type.array_type.item_count
    {
        base_array.count = buffer.type.array_type.item_count;
        base_array.base  = buffer.base;
    }
    else
    {
        base_array = buffer.base_array deref;
    }

    var used_count = used_count_ref deref;
    assert(used_count <= base_array.count, location);
    assert(index <= used_count, location);
    assert(used_count + insert_count <= base_array.count, location);

    var from = { ( used_count - index ) * item_byte_count, base_array.base + (index * item_byte_count) } u8[];
    var to   = { from.count,                               base_array.base + ((index + insert_count) * item_byte_count) } u8[];
    copy_bytes(to, from);
    
    used_count_ref deref = used_count + insert_count;
}

func insert(memory memory_arena ref, buffer lang_typed_value, index usize, insert_count usize, location = get_call_location())
{
    assert((buffer.type.type_type is lang_type_info_type.array) and buffer.type.indirection_count, location);
    assert(not buffer.type.array_type.item_count, "buffer must be a dynamic array", location);
    
    var used_count = buffer.base_array.count;
    reallocate_array(memory, buffer, used_count + insert_count);
    var buffer_deref = buffer;
    buffer_deref.type.indirection_count -= 1;
    insert(buffer_deref, used_count ref, index, insert_count, location);
}

func remove(buffer lang_typed_value, used_count_ref u32 ref, index usize, remove_count usize, location = get_call_location())
{
    var used_count usize = used_count_ref deref;
    remove(buffer, used_count ref, index, remove_count, location);
    used_count_ref deref = used_count cast(u32);
}

func remove(buffer lang_typed_value, used_count_ref usize ref, index usize, remove_count usize, location = get_call_location())
{
    assert((buffer.type.type_type is lang_type_info_type.array) and (not buffer.type.indirection_count), location);

    var item_byte_count = buffer.type.array_type.item_type.byte_count;

    var base_array lang_base_array;
    if buffer.type.array_type.item_count
    {
        base_array.count = buffer.type.array_type.item_count;
        base_array.base  = buffer.base;
    }
    else
    {
        base_array = buffer.base_array deref;
    }    
    
    var used_count = used_count_ref deref;
    assert(used_count <= base_array.count, location);
    assert(index <= used_count, location);
    assert(used_count - index >= remove_count, location);

    var from = { ( used_count - index - remove_count) * item_byte_count, base_array.base + ((index + remove_count) * item_byte_count) } u8[];
    var to   = { from.count,                                             base_array.base + (index * item_byte_count) } u8[];
    copy_bytes(to, from);

    used_count_ref deref = used_count - remove_count;
}

func remove(memory memory_arena ref, buffer lang_typed_value, index usize, remove_count usize, location = get_call_location())
{
    assert((buffer.type.type_type is lang_type_info_type.array) and buffer.type.indirection_count, location);
    assert(not buffer.type.array_type.item_count, "buffer must be a dynamic array", location);
    
    var used_count = buffer.base_array.count;
    
    var buffer_deref = buffer;
    buffer_deref.type.indirection_count -= 1;
    remove(buffer_deref, used_count ref, index, remove_count, location);

    reallocate_array(memory, buffer, used_count);    
}

func copy_bytes(to u8 ref, from u8 ref, byte_count usize)
{
    var to_array   = { byte_count, to }   u8[];
    var from_array = { byte_count, from } u8[];
    copy_bytes(to_array, from_array);
}

// SLOW:
func copy_bytes(to u8[], from u8[])
{
    assert(to.count is from.count);
    
    if to.base > from.base
    {
        loop var i usize; to.count
        {
            var reverse_i = to.count - 1 - i;
            // skip array bounds check
            (to.base + reverse_i) deref = (from.base + reverse_i) deref;
        }
    }
    else
    {
        loop var i usize; to.count
        {
            // skip array bounds check
            (to.base + i) deref = (from.base + i) deref;
        }
    }
}

// TODO: all arrays convert to u8[], so we get default byte comparison

func is(left u8[], right u8[]) (result b8)
{
    if left.count is_not right.count
        return false;
        
    loop var i; left.count
    {
        if left[i] is_not right[i]
            return false;
    }
    
    return true;
}

func is_not(left u8[], right u8[]) (result b8)
{
    return not (left is right);
}

func clear(data u8[], value u8 = 0)
{
    loop var i usize; data.count
        data[i] = value;
}

func clear_value(typed_value lang_typed_value)
{
    assert(typed_value.type.indirection_count is 1);
    
    var data u8[];
    data.base  = typed_value.base;
    data.count = typed_value.type.byte_count;

    clear(data);
}