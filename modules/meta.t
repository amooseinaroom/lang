
module meta;

import platform;
import memory;
import string;

func save_data(memory memory_arena ref, typed_value lang_typed_value) (data u8[])
{
    var type = typed_value.type;
    assert(not type.indirection_count);
    
    var alignment = allocate_type(memory, get_type_info(usize)) cast(usize ref);
    alignment deref = type.byte_alignment;
    
    save_data_item(memory, typed_value);
    
    var data u8[];
    data.base  = alignment cast(u8 ref);
    data.count = (memory.base + memory.used_byte_count - data.base) cast(usize);
    return data;
}

func save_data_item(memory memory_arena ref, typed_value lang_typed_value)
{
    var type = typed_value.type;
    assert(not type.indirection_count);
    
    if type.type_type is lang_type_info_type.array
    {
        var base_array lang_base_array;
    
        // store count for dynamic array
        if not type.array_type.item_count
        {
            base_array = typed_value.base_array deref;
            var count  = allocate_type(memory, get_type_info(usize)) cast(usize ref);
            count deref = base_array.count;
        }
        else
        {
            base_array.count = type.array_type.item_count;
            base_array.base  = typed_value.base;
        }
        
        loop var i usize; base_array.count
        {
            var item_typed_value lang_typed_value;
            item_typed_value.type = type.array_type.item_type;
            item_typed_value.base = base_array.base + (i * item_typed_value.type.byte_count);
            save_data_item(memory, item_typed_value);
        }
    }
    else if type.type_type is lang_type_info_type.compound
    {
        var compound = type.compound_type deref;
        loop var i; compound.fields.count
        {
            var field = compound.fields[i];
            
            var field_typed_value lang_typed_value;
            field_typed_value.type = field.type;
            field_typed_value.base = typed_value.base + field.byte_offset;
            save_data_item(memory, field_typed_value);
        }
    }
    else
    {
        var items u8[];
        items.count = type.byte_count;
        items.base  = allocate_type(memory, type);
        copy_bytes(items, { items.count, typed_value.base } u8[]);
    }
}

func load_data(memory memory_arena ref, typed_value lang_typed_value, data u8[])
{
    var data_memory memory_arena;
    data_memory.base              = data.base;
    data_memory.commit_byte_count = data.count;
    
    assert(data.count >= type_byte_count(usize));

    var alignment = data_memory.base cast(usize ref) deref;
    assert((data_memory.base cast(usize) bit_and (alignment - 1)) is 0, "data is not properly aligned");
    allocate_type(data_memory ref, get_type_info(usize));    
    
    load_data_item(memory, typed_value, data_memory ref);
    assert(data_memory.used_byte_count is data_memory.commit_byte_count);
}

func load_data_item(memory memory_arena ref, typed_value lang_typed_value, data_memory memory_arena ref)
{
    var type = typed_value.type;
    assert(not type.indirection_count);
    
    if type.type_type is lang_type_info_type.array
    {
        var base_array lang_base_array;
    
        // read count and allocate items for dynamic array
        if not type.array_type.item_count
        {
            var count = allocate_type(data_memory, get_type_info(usize)) cast(usize ref);
            
            base_array.count = count deref;
            base_array.base  = allocate_array(memory, type.array_type.item_type, base_array.count);
            
            typed_value.base_array deref = base_array;
        }
        else
        {
            base_array.count = type.array_type.item_count;
            base_array.base  = typed_value.base;
        }
        
        loop var i usize; base_array.count
        {
            var item_typed_value lang_typed_value;
            item_typed_value.type = type.array_type.item_type;
            item_typed_value.base = base_array.base + (i * item_typed_value.type.byte_count);
            load_data_item(memory, item_typed_value, data_memory);
        }
    }
    else if type.type_type is lang_type_info_type.compound
    {
        var compound = type.compound_type deref;
        loop var i; compound.fields.count
        {
            var field = compound.fields[i];
            
            var field_typed_value lang_typed_value;
            field_typed_value.type = field.type;
            field_typed_value.base = typed_value.base + field.byte_offset;
            load_data_item(memory, field_typed_value, data_memory);
        }
    }
    else
    {
        var items u8[];
        items.count = type.byte_count;
        items.base  = allocate_type(data_memory, type);
        copy_bytes({ items.count, typed_value.base } u8[], items);
    }
}

func get_base_array(array lang_typed_value) (base_array lang_base_array)
{
    var type = array.type;
    assert(type.type_type is lang_type_info_type.array);
    assert(type.indirection_count is 0);

    var base_array lang_base_array;
    if type.array_type.item_count
    {
        base_array.count = type.array_type.item_count;
        base_array.base  = array.base;
    }
    else
    {
        base_array = array.base_array deref;
    }

    return base_array;
}
