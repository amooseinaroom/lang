
module tk_format;

import memory;
import math;
import string;

def tk_mesh_version = 2;

struct tk_mesh
{   
    // in order of allocation

    nodes          tk_mesh_node[];
    all_node_names string; // every node.name is substring of all_node_names
    draw_commands  tk_mesh_draw_command[];

    vertex_type   lang_type_info;
    compound_type lang_type_info_compound;
    
    blend_node_indices u32[];

    vertices      lang_base_array;
    indices       u32[];
}

struct tk_mesh_node
{
    node_to_parent mat_transform;
    mesh_to_bone   mat_transform;

    name string;

    parent_index u32; // -1 is no parent
    depth        u32;
    blend_index  u32;

    draw_command_offset u32;
    draw_command_count  u32;
}

struct tk_mesh_draw_command
{
    primitive    tk_draw_primitve;
    index_offset u32;
    index_count  u32;    
}

enum tk_draw_primitve u32
{
    points;
    lines;
    triangles;
}

enum tk_vertex_attribute u32
{
    invalid = -1 cast(u32);
    position;
    normal;
    tangent;
    uv;
    blend_indices;
    blend_weights;
    color;
}


struct tk_mesh_result
{
    ok b8;
    error_line string;
    error_line_number u32;
    error_column u32;
}

func tk_mesh_error(source string, iterator string ref) (result tk_mesh_result)
{
    var it = source;
    var line_count u32;
    var line string;
    while it.count
    {
        line = try_skip_until(it ref, "\n");
        if (line.base + line.count) > iterator.base
            break;

        line_count += 1;
    }
    
    return { false, line, line_count + 1, (iterator.base - line.base) cast(u32) } tk_mesh_result;
}

// NOTE: mesh.vertex_type points to mesh.compound_type, so make sure to always pass a persistant reference
func tk_mesh_load(mesh tk_mesh ref, source string, memory memory_arena ref) (result tk_mesh_result)
{
    var _test_memory = memory deref;
    var test_memory = _test_memory ref;

    var _iterator = source;
    var iterator = _iterator ref;
    
    mesh deref = {} tk_mesh;
    
    tk_mesh_skip_space(iterator);
    if not try_skip(iterator, "version")
        return tk_mesh_error(source, iterator);
    
    tk_mesh_skip_space(iterator);
    var version u32;
    if not try_parse_u32(version ref, iterator)
        return tk_mesh_error(source, iterator);
    
    if version is_not tk_mesh_version
        return tk_mesh_error(source, iterator);
    
    var nodes tk_mesh_node[];
    var all_node_names string;
    var draw_commands tk_mesh_draw_command[];

    {
        tk_mesh_skip_space(iterator);
        if not try_skip(iterator, "nodes")
            return tk_mesh_error(source, iterator);
        
        tk_mesh_skip_space(iterator);
        var max_node_depth u32;
        if not try_parse_u32(max_node_depth ref, iterator)
            return tk_mesh_error(source, iterator);

        tk_mesh_skip_space(iterator);
        var total_draw_command_count u32;
        if not try_parse_u32(total_draw_command_count ref, iterator)
            return tk_mesh_error(source, iterator);

        tk_mesh_skip_space(iterator);
        var all_names_byte_count u32;
        if not try_parse_u32(all_names_byte_count ref, iterator)
            return tk_mesh_error(source, iterator);
        
        tk_mesh_skip_space(iterator);
                    
        var array_info = tk_mesh_try_parse_array_open(iterator);
        if not array_info.ok
            return tk_mesh_error(source, iterator);

        var node_count = array_info.count;
        var node_index u32;
        var scope_was_closed = false;
        
        reallocate_array(test_memory, nodes ref, node_count);    
        reallocate_array(test_memory, all_node_names ref, all_names_byte_count);        
        reallocate_array(test_memory, draw_commands ref, total_draw_command_count);

        var names_builder = string_builder_from_buffer(all_node_names);
        
        var draw_command_offset u32;

        while iterator.count
        {
            tk_mesh_skip_space(iterator);
            
            if try_skip(iterator, "}")
            {
                scope_was_closed = true;
                break;
            }
        
            var name string;
            if not try_parse_quoated_string(name ref, iterator)
                return tk_mesh_error(source, iterator);
            
            tk_mesh_skip_space(iterator);
            var parent_index s32;
            if not try_parse_s32(parent_index ref, iterator)
                return tk_mesh_error(source, iterator);
            
            tk_mesh_skip_space(iterator);
            var depth u32;
            if not try_parse_u32(depth ref, iterator)
                return tk_mesh_error(source, iterator);
            
            var node_to_parent_transform mat_transform;
            if not try_parse_transform(node_to_parent_transform ref, iterator)
                return tk_mesh_error(source, iterator);
            
            tk_mesh_skip_space(iterator);
            var blend_index u32;
            var mesh_to_bone_transform = mat_transform_identity;
            if try_skip(iterator, "mesh_to_bone")
            {
                tk_mesh_skip_space(iterator);
                if not try_parse_u32(blend_index ref, iterator)
                    return tk_mesh_error(source, iterator);
                
                tk_mesh_skip_space(iterator);
                if not try_parse_transform(mesh_to_bone_transform ref, iterator)
                    return tk_mesh_error(source, iterator);
            }
                        
            var draw_command_count u32;
            var sphere_or_circle_radius f32;
            
            tk_mesh_skip_space(iterator);
            if try_skip(iterator, "draw_commands")
            {
                var array_info = tk_mesh_try_parse_array_open(iterator);
                if not array_info.ok
                    return tk_mesh_error(source, iterator);

                draw_command_count = array_info.count;
                var draw_command_index u32;
                
                var scope_was_closed = false;
                while iterator.count
                {
                    tk_mesh_skip_space(iterator);
                    
                    if try_skip(iterator, "}")
                    {
                        scope_was_closed = true;
                        break;
                    }
                    
                    var draw_primitive tk_draw_primitve;
                    if try_skip(iterator, "triangles")
                        draw_primitive = tk_draw_primitve.triangles;
                    else if try_skip(iterator, "lines")
                        draw_primitive = tk_draw_primitve.lines;
                    else if try_skip(iterator, "points")
                        draw_primitive = tk_draw_primitve.points;
                    else
                        return tk_mesh_error(source, iterator);
                    
                    tk_mesh_skip_space(iterator);
                    var index_offset u32;
                    if not try_parse_u32(index_offset ref, iterator)
                        return tk_mesh_error(source, iterator);
                    
                    tk_mesh_skip_space(iterator);
                    var index_count u32;
                    if not try_parse_u32(index_count ref, iterator)
                        return tk_mesh_error(source, iterator);

                    var command = draw_commands[draw_command_offset + draw_command_index] ref;
                    command.primitive = draw_primitive;
                    command.index_offset = index_offset;
                    command.index_count  = index_count;
                    
                    draw_command_index += 1;
                
                    if draw_command_index > draw_command_count
                        return tk_mesh_error(source, iterator);
                }
                
                if not scope_was_closed or (draw_command_index is_not draw_command_count)
                    return tk_mesh_error(source, iterator);
            }
            else if try_skip(iterator, "sphere") or try_skip(iterator, "circle")
            {
                tk_mesh_skip_space(iterator);
                if not try_parse_f32(sphere_or_circle_radius ref, iterator)
                    return tk_mesh_error(source, iterator);
            }

            var node = nodes[node_index] ref;
            node.name = write(names_builder ref, name);
            node.node_to_parent = node_to_parent_transform;
            node.mesh_to_bone = mesh_to_bone_transform;
            node.depth = depth;
            node.blend_index = blend_index;
            node.parent_index = parent_index cast(u32);
            node.draw_command_offset = draw_command_offset;
            node.draw_command_count = draw_command_count;
            draw_command_offset += draw_command_count;
                        
            node_index += 1;
            
            if node_index > node_count
                return tk_mesh_error(source, iterator);
        }
        
        if not scope_was_closed or (node_index is_not node_count)
            return tk_mesh_error(source, iterator);
    }

    var blend_node_indices u32[];    
    {
        tk_mesh_skip_space(iterator);
        if not try_skip(iterator, "blend_node_indices")
            return tk_mesh_error(source, iterator);
        
        tk_mesh_skip_space(iterator);

        var array_info = tk_mesh_try_parse_array_open(iterator);
        if not array_info.ok
            return tk_mesh_error(source, iterator);

        var blend_node_count = array_info.count;
        var blend_node_index u32;
        
        reallocate_array(test_memory, blend_node_indices ref, blend_node_count);
        
        var scope_was_closed = false;
        while iterator.count
        {
            tk_mesh_skip_space(iterator);
            
            if try_skip(iterator, "}")
            {
                scope_was_closed = true;
                break;
            }
            
            tk_mesh_skip_space(iterator);
            var index u32;
            if not try_parse_u32(index ref, iterator)
                return tk_mesh_error(source, iterator);

            blend_node_indices[blend_node_index] = index;            
            blend_node_index += 1;
            
            if blend_node_index > blend_node_count
                return tk_mesh_error(source, iterator);
        }
        
        if not scope_was_closed or (blend_node_index is_not blend_node_count)
            return tk_mesh_error(source, iterator);
    }
    
    {
        tk_mesh_skip_space(iterator);
        if not try_skip(iterator, "vertices")
            return tk_mesh_error(source, iterator);
        
        tk_mesh_skip_space(iterator);        
        
        var array_info = tk_mesh_try_parse_array_open(iterator);
        if not array_info.ok
            return tk_mesh_error(source, iterator);

        var attribute_count = array_info.count;
        var attribute_index u32;
            
        var attributes  = get_type_info(tk_vertex_attribute).enumeration_type.items;
        var number_types = get_type_info(lang_type_info_number_type).enumeration_type.items;
        
        var compound_type lang_type_info_compound;
        compound_type.byte_alignment = 1;
        reallocate_array(test_memory, compound_type.fields ref, attribute_count);
        
        // each attribute is a fixed array of a number type
        var fields_arrays lang_type_info_array[];        
        
        var scope_was_closed = false;
        while iterator.count
        {
            tk_mesh_skip_space(iterator);
            
            if try_skip(iterator, "}")
            {
                scope_was_closed = true;
                break;
            }
            
            var attribute = tk_vertex_attribute.invalid;
            {
                tk_mesh_skip_space(iterator);
                loop var i u32; attributes.count
                {
                    if try_skip(iterator, attributes[i].name)
                    {
                        attribute = i;
                        break;
                    }
                }
                
                if attribute is tk_vertex_attribute.invalid
                    return tk_mesh_error(source, iterator);
            }
            
            var field = compound_type.fields[attribute_index] ref;

            tk_mesh_skip_space(iterator);

            if try_skip(iterator, "rgba8")
            {                   
                field.type = get_type_info(rgba8);
            }
            else
            {
                var item_count u32;
                {                    
                    if not try_skip(iterator, "v")
                        return tk_mesh_error(source, iterator);
                    
                    if not try_parse_u32(item_count ref, iterator)
                        return tk_mesh_error(source, iterator);
                }
            
                var number_type = -1 cast(u32) cast(lang_type_info_number_type);
                {
                    tk_mesh_skip_space(iterator);
                    loop var i u32; number_types.count
                    {
                        if try_skip(iterator, number_types[i].name)
                        {
                            number_type = i;
                            break;
                        }
                    }
                    
                    if number_type is -1 cast(u32) cast(lang_type_info_number_type)
                        return tk_mesh_error(source, iterator);
                }
                
                reallocate_array(test_memory, fields_arrays ref, fields_arrays.count + 1);

                var array_type = fields_arrays[fields_arrays.count - 1] ref;
                array_type.item_type.type_type      = lang_type_info_type.number;
                array_type.item_type.number_type    = lang_type_table.number_types[number_type] ref;
                array_type.item_type.byte_count     = array_type.item_type.number_type.byte_count_and_alignment;
                array_type.item_type.byte_alignment = array_type.item_type.number_type.byte_count_and_alignment;

                array_type.item_count = item_count;
                array_type.byte_count = array_type.item_count * array_type.item_type.byte_count;
            
                field.type.type_type      = lang_type_info_type.array;
                field.type.array_type     = array_type;
                field.type.byte_count     = array_type.byte_count;
                field.type.byte_alignment = array_type.item_type.byte_alignment;
            }
                                    
            field.name        = attributes[attribute].name;
            field.byte_offset = compound_type.byte_count;
            compound_type.byte_count += field.type.byte_count;
            
            attribute_index += 1;
            
            if attribute_index > attribute_count
                return tk_mesh_error(source, iterator);
        }
        
        if not scope_was_closed or (attribute_index is_not attribute_count)
            return tk_mesh_error(source, iterator);
        
        mesh.nodes = nodes;
        mesh.draw_commands = draw_commands;
        mesh.all_node_names = all_node_names;
        mesh.blend_node_indices = blend_node_indices;
        mesh.compound_type = compound_type;
        mesh.vertex_type.type_type      = lang_type_info_type.compound;
        mesh.vertex_type.compound_type  = mesh.compound_type ref;
        mesh.vertex_type.byte_count     = mesh.compound_type.byte_count;
        mesh.vertex_type.byte_alignment = mesh.compound_type.byte_alignment;
        
        {
            tk_mesh_skip_space(iterator);

            var array_info = tk_mesh_try_parse_array_open(iterator);
            if not array_info.ok
                return tk_mesh_error(source, iterator);

            var vertex_count = array_info.count;
            var vertex_index u32;            
                        
            var vertices u8[];
            reallocate_array(test_memory, vertices ref, vertex_count * compound_type.byte_count);
            
            var value_iterator = vertices.base;
            
            var scope_was_closed = false;
            while iterator.count
            {
                tk_mesh_skip_space(iterator);
                
                if try_skip(iterator, "}")
                {
                    scope_was_closed = true;
                    break;
                }
                
                loop var attribute_index u32; compound_type.fields.count
                {
                    var number_type lang_type_info_number_type;
                    var item_count u32;
                    if compound_type.fields[attribute_index].type.reference is get_type_info(rgba8).reference
                    {
                        number_type = lang_type_info_number_type.u8;
                        item_count  = 4;
                    }
                    else
                    {
                        var array_type = compound_type.fields[attribute_index].type.array_type deref;
                        number_type = array_type.item_type.number_type.number_type;
                        item_count = array_type.item_count cast(u32);
                    }                    
                    
                    switch number_type
                    case lang_type_info_number_type.u8
                    {
                        tk_mesh_skip_space(iterator);
                        if not try_skip(iterator, "u8")
                            return tk_mesh_error(source, iterator);

                        var read_item_count u32;
                        tk_mesh_skip_space(iterator);
                        if not try_parse_u32(read_item_count ref, iterator) or (read_item_count is_not item_count)
                            return tk_mesh_error(source, iterator);
                        
                        loop var index u32; item_count
                        {
                            tk_mesh_skip_space(iterator);
                            var value_u32 u32;
                            if not try_parse_u32(value_u32 ref, iterator)
                                return tk_mesh_error(source, iterator);
                            
                            if value_u32 > 255
                                return tk_mesh_error(source, iterator);
                            
                            value_iterator deref = value_u32 cast(u8);
                            value_iterator += 1;
                        }
                    }
                    case lang_type_info_number_type.f32
                    {
                        var value = value_iterator cast(f32 ref);
                        loop var index u32; item_count
                        {
                            tk_mesh_skip_space(iterator);
                            if not try_parse_f32(value, iterator)
                                return tk_mesh_error(source, iterator);
                            
                            value += 1;
                        }

                        value_iterator = value cast(u8 ref);
                    }
                    else
                        return tk_mesh_error(source, iterator);
                }
                
                vertex_index += 1;
                
                if vertex_index > vertex_count
                    return tk_mesh_error(source, iterator);
            }
            
            if not scope_was_closed or (vertex_index is_not vertex_count)
                return tk_mesh_error(source, iterator);
            
            mesh.vertices.base  = vertices.base;
            mesh.vertices.count = vertex_count;
        }
    }
    
    {
        tk_mesh_skip_space(iterator);
        if not try_skip(iterator, "indices")
            return tk_mesh_error(source, iterator);
        
        tk_mesh_skip_space(iterator);
        var trianlge_index_count u32;
        if not try_parse_u32(trianlge_index_count ref, iterator)
            return tk_mesh_error(source, iterator);
        
        tk_mesh_skip_space(iterator);
        var line_index_count u32;
        if not try_parse_u32(line_index_count ref, iterator)
            return tk_mesh_error(source, iterator);
        
        tk_mesh_skip_space(iterator);
        var point_index_count u32;
        if not try_parse_u32(point_index_count ref, iterator)
            return tk_mesh_error(source, iterator);
        
        tk_mesh_skip_space(iterator);
                
        var array_info = tk_mesh_try_parse_array_open(iterator);
        if not array_info.ok
            return tk_mesh_error(source, iterator);

        var index_count = array_info.count;
        var index u32;
        
        var indices u32[];
        reallocate_array(test_memory, indices ref, index_count);
        
        var scope_was_closed = false;
        while iterator.count
        {
            tk_mesh_skip_space(iterator);
            
            if try_skip(iterator, "}")
            {
                scope_was_closed = true;
                break;
            }
            
            if not try_parse_u32(indices[index] ref, iterator)
                return tk_mesh_error(source, iterator);
            
            index += 1;
            
            if index > index_count
                return tk_mesh_error(source, iterator);
        }
        
        if not scope_was_closed or (index is_not index_count)
            return tk_mesh_error(source, iterator);
            
        mesh.indices = indices;
    }
    
    memory deref = test_memory deref;
    return true, "", 0, 0;
}

struct tk_mesh_array_info
{
    count            u32;
    index            u32;
    ok               b8;
    scope_was_closed b8;    
}

func tk_mesh_try_parse_array_open(iterator string ref) (info tk_mesh_array_info)
{
    var count u32;

    tk_mesh_skip_space(iterator);
    if not try_parse_u32(count ref, iterator)
        return false, 0;
    
    tk_mesh_skip_space(iterator);
    if not try_skip(iterator, "{")
        return { 0, 0, false, false } tk_mesh_array_info;
    
    return { count, 0, true, false } tk_mesh_array_info;
}

func tk_mesh_try_parse_array_close(iterator string ref, info tk_mesh_array_info ref) (ok b8)
{
    tk_mesh_skip_space(iterator);            
    if try_skip(iterator, "}")
    {
        info.scope_was_closed = true;
        return true;
    }

    // will break out of loop and forces tk_mesh_check_array_closed to fail
    if info.index >= info.count
        return true;

    info.index += 1;

    return false;
}

func tk_mesh_check_array_closed(iterator string ref, info tk_mesh_array_info) (ok b8)
{
    return info.scope_was_closed and (info.index is info.count);
}

func try_parse_transform(transform mat_transform ref, iterator string ref) (ok b8)
{
    transform deref = mat_transform_identity;
    loop var column; 4
    {
        loop var row; 3
        {
            tk_mesh_skip_space(iterator);
            if not try_parse_f32(transform[column][row] ref, iterator)
                return false;
        }
    }
    
    return true;
}

func try_parse_quoated_string(out_text string ref, iterator string ref) (ok b8)
{
    var test = iterator deref;
    if not try_skip(test ref, "\"")
        return false;
    
    if not try_skip_until(test ref, "\"").count
        return false;
    
    out_text deref = { iterator.count - test.count - 2, iterator[1] ref } string;
    iterator deref = test;

    return true;
}

func tk_mesh_skip_space(iterator string ref) (ok b8)
{
    var did_skip = false;
    while iterator.count
    {
        if not tk_mesh_skip_white_space(iterator) and not tk_mesh_skip_comment(iterator)
            break;
        
        did_skip = true;
    }
    
    return did_skip;
}

func tk_mesh_skip_white_space(iterator string ref) (ok b8)
{
    return try_skip_set(iterator, " \t\r\n") > 0;
}

func tk_mesh_skip_comment(iterator string ref) (ok b8)
{
    if try_skip(iterator, "#")
    {
        try_skip_until(iterator, "\n");
        
        return true;
    }
    
    return false;
}