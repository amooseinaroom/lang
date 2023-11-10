  
module wavefront;

import platform;
import memory;
import math;
import string;
import meta;

struct wavefront_object
{
    name string;
    
    triangle_index_offset u32;
    triangle_index_count  u32;
    
    line_index_offset u32;
    line_index_count  u32;
}

struct wavefront_scene
{
    // in order of allocation
    objects  wavefront_object[];
    indices  u32[];
    vertices lang_base_array;
    
    // indices.count is (triangle_index_count + line_index_count)
    triangle_index_count u32;
    line_index_count     u32;
}

func load_wavefront(memory memory_arena ref, object_name = "", default_vertex lang_typed_value, text string) (vertices u8[])
{
    var vertex_type = default_vertex.type;
    assert(vertex_type.type_type is lang_type_info_type.compound);

    // prepass collect counts
    var position_count u32;
    var normal_count   u32;
    var uv_count       u32;
    var vertex_count   u32;
    
    // offset relative to the object, since indices are not relative per object
    var position_offset u32;
    var normal_offset   u32;
    var uv_offset       u32;
    
    if object_name.count
    {
        var found_object_name = false;
        while text.count
        {
            var line = try_skip_until(text ref, "\n");
            if try_skip(line ref, "o ")
            {
                var name = line;
                try_skip_until(line ref, "\n", false);
                name.count = (line.base - name.base) cast(usize);
                
                if name is object_name
                {
                    found_object_name = true;
                    break;
                }
            }
            else if try_skip(line ref, "v ")
                position_offset += 1;
            else if try_skip(line ref, "vt ")
                uv_offset += 1;
            else if try_skip(line ref, "vn ")
                normal_offset += 1;
        }
        
        assert(found_object_name);
        
        var end = text;
        while end.count
        {
            var line = try_skip_until(end ref, "\n");
            if try_skip(line ref, "o ")
                break;
        }
        
        text.count = (end.base - text.base) cast(usize);
    }
    
    {
        var iterator = text;
        while iterator.count
        {
            var line = try_skip_until(iterator ref, "\n");
            if not line.count
            {
                line = iterator;
                advance(iterator ref, iterator.count);
            }
            
            if try_skip(line ref, "v ")
                position_count += 1;
            else if try_skip(line ref, "vt ")
                uv_count += 1;
            else if try_skip(line ref, "vn ")
                normal_count += 1;
            else if try_skip(line ref, "f ")
                vertex_count += 3;
            else if try_skip(line ref, "l ")
                vertex_count += 2;
        }
    }
    
    var vertices u8[];
    vertices.count = vertex_count;
    vertices.base  = allocate_array(memory, vertex_type, vertices.count);
    
    var default_vertex_data = { vertex_type.byte_count, default_vertex.base } u8[];
    
    loop var i usize; vertex_count
    {
        var vertex = { vertex_type.byte_count, vertices.base + (i * vertex_type.byte_count) } u8[];
        copy_array(vertex, default_vertex_data);
    }
    
    vertex_count = 0;
    
    // these are temporary
    
    var positions vec3[];
    positions.count = position_count + 1;
    positions.base  = allocate_array(memory, get_type_info(vec3), positions.count);
    position_count  = 1;
    positions[0] = [ 0, 0, 0 ] vec3;
    
    var uvs vec2[];
    uvs.count = uv_count + 1;
    uvs.base  = allocate_array(memory, get_type_info(vec2), uvs.count);
    uv_count  = 1;
    uvs[0] = [ 0, 0 ] vec2;
    
    var normals vec3[];
    normals.count = normal_count + 1;
    normals.base  = allocate_array(memory, get_type_info(vec3), normals.count);
    normal_count  = 1;
    normals[0] = [ 0, 0, 1 ] vec3;
    
    var vertex_positions u8 ref;
    var vertex_uvs       u8 ref;
    var vertex_normals   u8 ref;
    var vertex_colors    u8 ref;
    
    var compound = vertex_type.compound_type deref;
    loop var i; compound.fields.count
    {
        if compound.fields[i].name is "position"
            vertex_positions = vertices.base + compound.fields[i].byte_offset;
        else if compound.fields[i].name is "uv"
            vertex_uvs = vertices.base + compound.fields[i].byte_offset;
        else if compound.fields[i].name is "normal"
            vertex_normals = vertices.base + compound.fields[i].byte_offset;
        else if compound.fields[i].name is "color"
            vertex_colors = vertices.base + compound.fields[i].byte_offset;
    }
    
    assert(vertex_positions, "vertex type needs to have at least a position vec3 field");
    
    while text.count
    {
        var line = try_skip_until(text ref, "\n");
        if not line.count
        {
            line = text;
            advance(text ref, text.count);
        }
        
        if try_skip(line ref, "v ")
        {
            var position = positions[position_count] ref;
            position_count = position_count + 1;
            
            var number_text = try_skip_until(line ref, " ");
            require(try_parse_f32(position[0] ref, number_text ref));
            
            number_text = try_skip_until(line ref, " ");
            require(try_parse_f32(position[1] ref, number_text ref));
            
            number_text = line;
            require(try_parse_f32(position[2] ref, number_text ref));
        }
        else if try_skip(line ref, "vt ")
        {
            var uv = uvs[uv_count] ref;
            uv_count = uv_count + 1;
            
            var number_text = try_skip_until(line ref, " ");
            require(try_parse_f32(uv[0] ref, number_text ref));
            
            number_text = line;
            require(try_parse_f32(uv[1] ref, number_text ref));
        }
        else if try_skip(line ref, "vn ")
        {
            var normal = normals[normal_count] ref;
            normal_count = normal_count + 1;
            
            var number_text = try_skip_until(line ref, " ");
            require(try_parse_f32(normal[0] ref, number_text ref));
            
            number_text = try_skip_until(line ref, " ");
            require(try_parse_f32(normal[1] ref, number_text ref));
            
            number_text = line;
            require(try_parse_f32(normal[2] ref, number_text ref));
        }
        else if try_skip(line ref, "f ")
        {
            loop var i; 3
            {
                parse_vertex(line ref, vertex_count ref, vertex_type, positions, normals, uvs , position_offset, normal_offset, uv_offset, vertex_positions, vertex_uvs, vertex_normals);
            }
        }
        else if try_skip(line ref, "l ")
        {
            loop var i; 2
            {
                parse_vertex(line ref, vertex_count ref, vertex_type, positions, normals, uvs , position_offset, normal_offset, uv_offset, vertex_positions, vertex_uvs, vertex_normals);
            }
        }
    }
    
    free(memory, normals.base);
    free(memory, uvs.base);
    free(memory, positions.base);
    
    return vertices;
}

func parse_vertex(line string ref, vertex_count u32 ref, vertex_type lang_type_info, positions vec3[], normals vec3[], uvs vec2[], position_offset u32, normal_offset u32, uv_offset u32, vertex_positions u8 ref, vertex_uvs u8 ref, vertex_normals u8 ref)
{
    var position_index u64;
    var uv_index u64;
    var normal_index u64;
    
    require(try_parse_u64(position_index ref, line));
    position_index -= position_offset;
    
    if try_skip(line, "/")
    {
        if try_parse_u64(uv_index ref, line)
            uv_index -= uv_offset;
    
        if try_skip(line, "/")
        {
            if try_parse_u64(normal_index ref, line)
                normal_index -= normal_offset;
        }
    }
    
    // actually indices are - 1, but we store default value at index 0, if not all attributes are available
    
    // HACK: expression parsing is bad :P
    (vertex_positions + (vertex_count deref * vertex_type.byte_count)) cast(vec3 ref) deref = positions[position_index];
        
    if vertex_uvs
    {
        (vertex_uvs + (vertex_count deref * vertex_type.byte_count)) cast(vec2 ref) deref = uvs[uv_index];
    }
    
    if vertex_normals
    {
        (vertex_normals + (vertex_count deref * vertex_type.byte_count)) cast(vec3 ref) deref = normals[normal_index];
    }
    
    vertex_count deref += 1;
    
    try_skip(line, " ");
}

func parse_unique_index(line string ref, memory memory_arena ref, unique_indices wavefront_unique_index[] ref, position_offset u32 = 0, normal_offset u32 = 0, uv_offset u32 = 0) (result u32)
{
    var unique_index wavefront_unique_index;
    
    require(try_parse_u32(unique_index.position ref, line));
    unique_index.position -= position_offset;
    
    if try_skip(line, "/")
    {
        if try_parse_u32(unique_index.uv ref, line)
            unique_index.uv -= uv_offset;
    
        if try_skip(line, "/")
        {
            if try_parse_u32(unique_index.normal ref, line)
                unique_index.normal -= normal_offset;
        }
    }
    
    try_skip(line, " ");
    
    loop var i; unique_indices.count
    {
        if (unique_indices[i].position is unique_index.position) and
            (unique_indices[i].uv is unique_index.uv) and
            (unique_indices[i].normal is unique_index.normal)
            return i;
    }
    
    reallocate_array(memory, unique_indices, unique_indices.count + 1);
    unique_indices[unique_indices.count - 1] = unique_index;
    
    return unique_indices.count - 1;
    
    // actually indices are - 1, but we store default value at index 0, if not all attributes are available
    
    // HACK: expression parsing is bad :P
    //(vertex_uvs + (vertex_count deref * vertex_type.byte_count)) cast(vec3 ref) deref = positions[position_index];
        
    //if vertex_uvs
    {
        //(vertex_uvs + (vertex_count deref * vertex_type.byte_count)) cast(vec2 ref) deref = uvs[uv_index];
    }
    
    //if vertex_normals
    {
        //(vertex_normals + (vertex_count deref * vertex_type.byte_count)) cast(vec3 ref) deref = normals[normal_index];
    }
    
    //vertex_count deref += 1;
}

struct wavefront_unique_index
{
    position u32;
    normal   u32;
    uv       u32;
}

func load_wavefront_scene(memory memory_arena ref, tmemory memory_arena ref, default_vertex lang_typed_value, source string) (scene wavefront_scene)
{
    var tmemory_used_count = tmemory.used_byte_count;
    
    var vertex_type = default_vertex.type;
    assert(vertex_type.type_type is lang_type_info_type.compound);

    var position_count u32;
    var normal_count   u32;
    var uv_count       u32;
    
    var triangle_count u32;
    var line_count     u32;
    var object_count   u32;
    
    // prepass collect counts
    {
        var text = source;
        while text.count
        {
            var line = try_skip_until(text ref, "\n");
            if not line.count
            {
                line = text;
                advance(text ref, text.count);
            }
                
            if try_skip(line ref, "o ")
                object_count += 1;
            else if try_skip(line ref, "v ")
                position_count += 1;
            else if try_skip(line ref, "vt ")
                uv_count += 1;
            else if try_skip(line ref, "vn ")
                normal_count += 1;
             else if try_skip(line ref, "f ")
                triangle_count += 1;
            else if try_skip(line ref, "l ")
                line_count += 1;
        }
    }
    
    var scene wavefront_scene;
    
    var objects wavefront_object[];
    reallocate_array(memory, objects ref, object_count);
    
    var indices u32[];
    reallocate_array(memory, indices ref, (triangle_count * 3) + (line_count * 2));
    
    var positions vec3[];
    positions.count = position_count + 1;
    positions.base  = allocate_array(tmemory, get_type_info(vec3), positions.count);
    position_count  = 1;
    positions[0] = [ 0, 0, 0 ] vec3;
    
    var uvs vec2[];
    uvs.count = uv_count + 1;
    uvs.base  = allocate_array(tmemory, get_type_info(vec2), uvs.count);
    uv_count  = 1;
    uvs[0] = [ 0, 0 ] vec2;
    
    var normals vec3[];
    normals.count = normal_count + 1;
    normals.base  = allocate_array(tmemory, get_type_info(vec3), normals.count);
    normal_count  = 1;
    normals[0] = [ 0, 0, 1 ] vec3;
    
    {
        var object_count = 0;
        
        var text = source;
        while text.count
        {
            var line = try_skip_until(text ref, "\n");
            if not line.count
            {
                line = text;
                advance(text ref, text.count);
            }
            
            if try_skip(line ref, "o ")
            {
                var name = line;
                if try_skip_until(line ref, "\n", false).count
                    name.count = (line.base - name.base) cast(usize);
                
                objects[object_count].name = name;
                object_count += 1;
            }
            else if try_skip(line ref, "v ")
            {
                var position = positions[position_count] ref;
                position_count = position_count + 1;
                
                var number_text = try_skip_until(line ref, " ");
                require(try_parse_f32(position[0] ref, number_text ref));
                
                number_text = try_skip_until(line ref, " ");
                require(try_parse_f32(position[1] ref, number_text ref));
                
                number_text = line;
                require(try_parse_f32(position[2] ref, number_text ref));
            }
            else if try_skip(line ref, "vt ")
            {
                var uv = uvs[uv_count] ref;
                uv_count = uv_count + 1;
                
                var number_text = try_skip_until(line ref, " ");
                require(try_parse_f32(uv[0] ref, number_text ref));
                
                number_text = line;
                require(try_parse_f32(uv[1] ref, number_text ref));
            }
            else if try_skip(line ref, "vn ")
            {
                var normal = normals[normal_count] ref;
                normal_count = normal_count + 1;
                
                var number_text = try_skip_until(line ref, " ");
                require(try_parse_f32(normal[0] ref, number_text ref));
                
                number_text = try_skip_until(line ref, " ");
                require(try_parse_f32(normal[1] ref, number_text ref));
                
                number_text = line;
                require(try_parse_f32(normal[2] ref, number_text ref));
            }
        }
    }
    
    // collect unique vertices
    var unique_indices wavefront_unique_index[];
    
    // parse all triangles
    {
        var object_count = 0;
        
        var text = source;
        while text.count
        {
            var line = try_skip_until(text ref, "\n");
            if not line.count
            {
                line = text;
                advance(text ref, text.count);
            }
            
            if try_skip(line ref, "o ")
            {
                if object_count
                {
                    objects[object_count - 1].triangle_index_count = scene.triangle_index_count - objects[object_count - 1].triangle_index_offset;
                }
                
                objects[object_count].triangle_index_offset = scene.triangle_index_count;
                
                object_count += 1;
            }
            else if try_skip(line ref, "f ")
            {
                loop var i; 3
                {
                    var index = parse_unique_index(line ref, tmemory, unique_indices ref);
                    indices[scene.triangle_index_count] = index;
                    scene.triangle_index_count += 1;
                }
            }
        }
    }
    
    if objects.count
    {
        objects[objects.count - 1].triangle_index_count = scene.triangle_index_count - objects[objects.count - 1].triangle_index_offset;
    }
    
    // parse all lines
    {
        object_count = 0;
        
        var text = source;
        while text.count
        {
            var line = try_skip_until(text ref, "\n");
            if not line.count
            {
                line = text;
                advance(text ref, text.count);
            }
            
             if try_skip(line ref, "o ")
            {
                if object_count
                {
                    objects[object_count - 1].line_index_count = scene.triangle_index_count + scene.line_index_count - objects[object_count - 1].line_index_offset;
                }
                
                objects[object_count].line_index_offset = scene.line_index_count + scene.triangle_index_count;
                object_count += 1;
            }
            else if try_skip(line ref, "l ")
            {
                loop var i; 2
                {
                    var index = parse_unique_index(line ref, tmemory, unique_indices ref);
                    indices[scene.triangle_index_count + scene.line_index_count] = index;
                    scene.line_index_count += 1;
                }
            }
        }
    }
    
    if objects.count
    {
        objects[objects.count - 1].line_index_count = scene.triangle_index_count + scene.line_index_count - objects[objects.count - 1].line_index_offset;
    }
    
    var vertices lang_base_array;
    vertices.count = unique_indices.count;
    vertices.base  = allocate_array(memory, vertex_type, vertices.count);
    
    var vertex_positions u8 ref;
    var vertex_uvs       u8 ref;
    var vertex_normals   u8 ref;
    //var vertex_colors   u8 ref;
    
    var compound = vertex_type.compound_type deref;
    loop var i; compound.fields.count
    {
        if compound.fields[i].name is "position"
            vertex_positions = vertices.base + compound.fields[i].byte_offset;
        else if compound.fields[i].name is "uv"
            vertex_uvs = vertices.base + compound.fields[i].byte_offset;
        else if compound.fields[i].name is "normal"
            vertex_normals = vertices.base + compound.fields[i].byte_offset;
        //else if compound.fields[i].name is "color"
            //vertex_colors = vertices.base + compound.fields[i].byte_offset;
    }
    
    assert(vertex_positions, "vertex type needs to have at least a position vec3 field");
    
    var default_vertex_data = { vertex_type.byte_count, default_vertex.base } u8[];
    
    // 
    loop var i usize; vertices.count
    {
        var vertex = { vertex_type.byte_count, vertices.base + (i * vertex_type.byte_count) } u8[];
        
        // set to default vertex
        copy_array(vertex, default_vertex_data);
        
        var index = unique_indices[i];
        
        // HACK: expression parsing is bad :P
        (vertex_positions + (i * vertex_type.byte_count)) cast(vec3 ref) deref = positions[index.position];
        
        if vertex_normals is_not null
            (vertex_normals + (i * vertex_type.byte_count)) cast(vec3 ref) deref = normals[index.normal];
        
        if vertex_uvs is_not null
            (vertex_uvs + (i * vertex_type.byte_count)) cast(vec2 ref) deref = uvs[index.uv];
    }
    
    tmemory.used_byte_count = tmemory_used_count;
    
    scene.objects  = objects;
    scene.indices  = indices;
    scene.vertices = vertices;
    return scene;
}
