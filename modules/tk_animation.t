
module tk_format;

import meta;

def tk_animation_version = 1;

struct tk_animation_pack
{
	animations        tk_animation[];	
	frames_per_second u32;
} 

struct tk_animation
{
	name                string;
	node_infos          tk_animation_node_info[];
	start_frame         u32;
	frame_count         u32;
	duration_in_seconds f32;

	// frame_count * node_infos.count many
	node_frames tk_animation_node_frame[];
}

struct tk_animation_node_info
{
	name string;
	with_translation b8;
	with_rotation    b8;
	with_scale       b8;
}

struct tk_animation_node_frame
{
	rotation    quat;
	translation vec3;	
	scale       vec3;
}

def tk_animation_node_frame_identity = { quat_identity, {} vec3, [ 1, 1, 1 ] vec3 } tk_animation_node_frame;

func load(pack tk_animation_pack ref, source string, memory memory_arena ref) (ok b8, error_line string, error_line_number u32, error_column u32)
{
	var _test_memory = memory deref;
    var test_memory = _test_memory ref;

    var _iterator = source;
    var iterator = _iterator ref;
    
    pack deref = {} tk_animation_pack;
    
    tk_mesh_skip_space(iterator);
    if not try_skip(iterator, "version")
        return tk_mesh_error(source, iterator);
    
    tk_mesh_skip_space(iterator);    
    var version u32;
    if not try_parse_u32(version ref, iterator)
        return tk_mesh_error(source, iterator);

    if version is_not tk_animation_version
    	return tk_mesh_error(source, iterator);

    tk_mesh_skip_space(iterator);
    if not try_skip(iterator, "frames_per_second")
        return tk_mesh_error(source, iterator);

	tk_mesh_skip_space(iterator);
	var frames_per_second u32;
    if not try_parse_u32(frames_per_second ref, iterator)
        return tk_mesh_error(source, iterator);

    pack.frames_per_second = frames_per_second;
    
    {
    	tk_mesh_skip_space(iterator);
    	if not try_skip(iterator, "animations")
        	return tk_mesh_error(source, iterator);

    	var array_info = tk_mesh_try_parse_array_open(iterator);
    	if not array_info.ok
           	return tk_mesh_error(source, iterator);       

		var animations tk_animation[];		
        reallocate_array(test_memory, animations ref, array_info.count);
        pack.animations = animations;

        while iterator.count
        {
        	if tk_mesh_try_parse_array_close(iterator, array_info ref)
        		break;           

        	tk_mesh_skip_space(iterator);
	    	if not try_skip(iterator, "animation")
	        	return tk_mesh_error(source, iterator);

			tk_mesh_skip_space(iterator);
	        var name string;
            if not try_parse_quoated_string(name ref, iterator)
                return tk_mesh_error(source, iterator);

            var animation = animations[array_info.index - 1] ref;
	        animation.name = name;	       

	    	var array_info = tk_mesh_try_parse_array_open(iterator);
	    	if not array_info.ok
	           	return tk_mesh_error(source, iterator);	       	        

	        var node_infos tk_animation_node_info[];
	        reallocate_array(test_memory, node_infos ref, array_info.count);
	        animation.node_infos = node_infos;

	        while iterator.count
	        {
	        	if tk_mesh_try_parse_array_close(iterator, array_info ref)
        			break;	           

	            var name string;
            	if not try_parse_quoated_string(name ref, iterator)
                	return tk_mesh_error(source, iterator);

                tk_mesh_skip_space(iterator);
                var with_translation = try_skip(iterator, "translation");	

	        	tk_mesh_skip_space(iterator);
                var with_rotation = try_skip(iterator, "rotation");

	        	tk_mesh_skip_space(iterator);
                var with_scale = try_skip(iterator, "scale");

	        	var info = node_infos[array_info.index - 1] ref;
	        	info.name = name;
	        	info.with_translation = with_translation;
	        	info.with_rotation    = with_rotation;
	        	info.with_scale       = with_scale;	        
	        }

	        if not tk_mesh_check_array_closed(iterator, array_info)
	        	return tk_mesh_error(source, iterator);  

	        tk_mesh_skip_space(iterator);
	    	if not try_skip(iterator, "frames")
	        	return tk_mesh_error(source, iterator);

	        tk_mesh_skip_space(iterator);    
		    var start_frame u32;
		    if not try_parse_u32(start_frame ref, iterator)
		        return tk_mesh_error(source, iterator);

		    tk_mesh_skip_space(iterator);    
		    var frame_count u32;
		    if not try_parse_u32(frame_count ref, iterator)
		        return tk_mesh_error(source, iterator);

		    animation.frame_count = frame_count;
           
           	tk_mesh_skip_space(iterator);    
		    var duration_in_seconds f32;
		    if not try_parse_f32(duration_in_seconds ref, iterator)
		        return tk_mesh_error(source, iterator);

		    {
			    var array_info = tk_mesh_try_parse_array_open(iterator);
		    	if not array_info.ok
		           	return tk_mesh_error(source, iterator);		       
		        
		        // the actual count is frame_count * (float values of all channels)
		        array_info.count = frame_count * node_infos.count cast(u32);

		        var frames tk_animation_node_frame[];
		        reallocate_array(test_memory, frames ref, array_info.count);
		        animation.node_frames = frames;

		        label frame_loop while iterator.count
		        {		        			           
		            loop var node_index u32; node_infos.count
		            {
		            	if tk_mesh_try_parse_array_close(iterator, array_info ref)
        					break frame_loop;

		            	var info = node_infos[node_index];
		            	var frame = frames[array_info.index - 1] ref;

		            	if info.with_translation
		            	{
		            		loop var i; 3
		            		{
			            		tk_mesh_skip_space(iterator);
			            		if not try_parse_f32(frame.translation[i] ref, iterator)
			        				return tk_mesh_error(source, iterator);
			        		}
		            	}
		            	else
		            	{
		            		frame.translation = v3(0);
		            	}

		            	if info.with_rotation
		            	{
		            		loop var i; 4
		            		{
			            		tk_mesh_skip_space(iterator);
			            		if not try_parse_f32(frame.rotation[i] ref, iterator)
			        				return tk_mesh_error(source, iterator);
			        		}
		            	}
		            	else
		            	{
		            		frame.rotation = quat_identity;
		            	}

		            	if info.with_scale
		            	{
		            		loop var i; 3
		            		{
			            		tk_mesh_skip_space(iterator);
			            		if not try_parse_f32(frame.scale[i] ref, iterator)
			        				return tk_mesh_error(source, iterator);
			        		}
		            	}
		            	else
		            	{
		            		frame.scale = v3(1);
		            	}		            
		            }
		        }

		        if not tk_mesh_check_array_closed(iterator, array_info)
		        	return tk_mesh_error(source, iterator);        			
		    }
        }

        if not tk_mesh_check_array_closed(iterator, array_info)
	        return tk_mesh_error(source, iterator);  
    }
     
    memory deref = test_memory deref;
    return true, "", 0, 0;
}

def tk_max_mesh_node_count = 64;

struct tk_mesh_animation_nodes
{
	nodes_to_parent            mat_transform[tk_max_mesh_node_count];
	mesh_to_blend_nodes        mat_transform[tk_max_mesh_node_count];		
	node_parent_indices        u32[tk_max_mesh_node_count];
	blend_node_to_node_indices u32[tk_max_mesh_node_count];	
	node_count                 u32;
	blend_node_count           u32;	
}

func load(nodes tk_mesh_animation_nodes ref, mesh tk_mesh)
{
	assert(mesh.nodes.count <= nodes.nodes_to_parent.count);
    loop var i u32; mesh.nodes.count    
    {
        nodes.node_parent_indices[i] = mesh.nodes[i].parent_index;
        nodes.nodes_to_parent[i]     = mesh.nodes[i].node_to_parent;    
    }
    nodes.node_count = mesh.nodes.count cast(u32);

    assert(mesh.blend_node_indices.count <= nodes.mesh_to_blend_nodes.count);
    loop var i u32; mesh.blend_node_indices.count      
    { 
        var node_index = mesh.blend_node_indices[i];
        nodes.mesh_to_blend_nodes[i]        = mesh.nodes[node_index].mesh_to_bone;
        nodes.blend_node_to_node_indices[i] = node_index;
    }
    nodes.blend_node_count = mesh.blend_node_indices.count cast(u32);   
}

struct tk_mesh_animation
{
	node_frames       tk_animation_node_frame[];
	node_count        u32;
	frame_count       u32;
	frames_per_second u32;
}

struct tk_mesh_animation_state
{
	node_deltas          tk_animation_node_frame[tk_max_mesh_node_count];
	node_delta_weights   f32[tk_max_mesh_node_count];
	mesh_nodes_to_world  mat_transform[tk_max_mesh_node_count];
	blend_nodes_to_world mat_transform[tk_max_mesh_node_count];	
}

func load(animation tk_mesh_animation ref, mesh tk_mesh, pack tk_animation_pack, name string, memory memory_arena ref)
{
	var animation_index = -1 cast(u32);
	loop var i u32; pack.animations.count
	{
		if pack.animations[i].name is name
		{
			animation_index = i;
			break;
		}
	}	
    
	assert(animation_index is_not -1 cast(u32));
    var pack_animation = pack.animations[animation_index];

    var node_to_channel_indices u32[tk_max_mesh_node_count];

    loop var node_index u32; mesh.nodes.count
    {
        var name = mesh.nodes[node_index].name;
        node_to_channel_indices[node_index] = -1 cast(u32);

        loop var info_index u32; pack_animation.node_infos.count
        {        	
            if name is pack_animation.node_infos[info_index].name
            {
                node_to_channel_indices[node_index] = info_index;
                break;
            }
        }
    }

    animation deref = {} tk_mesh_animation;
    animation.node_count        = mesh.nodes.count cast(u32);
    animation.frame_count       = pack_animation.frame_count;
    animation.frames_per_second = pack.frames_per_second;
    reallocate_array(memory, animation.node_frames ref, pack_animation.frame_count * mesh.nodes.count);

    loop var frame_index u32; pack_animation.frame_count
    {
        loop var node_index u32; mesh.nodes.count
        {
            var channel_index = node_to_channel_indices[node_index];
            if channel_index is -1 cast(u32)
                animation.node_frames[frame_index * mesh.nodes.count + node_index] = tk_animation_node_frame_identity;
            else
                animation.node_frames[frame_index * mesh.nodes.count + node_index] = pack_animation.node_frames[frame_index * pack_animation.node_infos.count + channel_index];
        }
    }
}

func blend(state tk_mesh_animation_state ref, animation tk_mesh_animation, time f32, weight f32 = 1.0, do_loop b8)
{	
	time = fmod(time, (animation.frames_per_second * animation.frame_count) cast(f32));

	var frame_index_f32 = time * animation.frames_per_second;
    var frame_index = floor(frame_index_f32) cast(u32);    
	var frame_blend = frame_index_f32 - frame_index;
    
    if do_loop
    {    	
    	frame_index = frame_index mod (animation.frame_count - 1);
    }
    else
    {
    	if frame_index > (animation.frame_count - 1)
    	{
    		frame_index = animation.frame_count - 2;
    		frame_blend = 1.0;
    	}    
    }
   
    blend_frame(state, animation, frame_index,     weight * (1 - frame_blend));
    blend_frame(state, animation, frame_index + 1, weight * frame_blend);       
}

func blend_frame(state tk_mesh_animation_state ref, animation tk_mesh_animation, frame_index u32, weight f32)
{	
	assert(frame_index < animation.frame_count);

	var	node_count = animation.node_count;
	var offset = frame_index * node_count;

    loop var node_index u32; node_count
    {            
        var frame = animation.node_frames[offset + node_index];
        state.node_deltas[node_index].translation                       += frame.translation * weight;
        state.node_deltas[node_index].scale                             += frame.scale * weight;
        state.node_deltas[node_index].rotation ref cast(vec4 ref) deref += frame.rotation ref cast(vec4 ref) deref * weight;
        state.node_delta_weights[node_index] += weight;
    }    
}

func blend_end(state tk_mesh_animation_state ref, nodes tk_mesh_animation_nodes, mesh_to_world mat_transform)
{
	loop var i u32; nodes.node_count
    {
    	var scale = 1 / state.node_delta_weights[i];
        var frame = state.node_deltas[i];
        frame.translation *= scale;
        frame.scale       *= scale;
        frame.rotation ref cast(vec4 ref) deref = normalize(frame.rotation  ref cast(vec4 ref) deref);
        
        var animation_delta = mat4_transform(frame.rotation, frame.translation, frame.scale);

        var parent_index = nodes.node_parent_indices[i];
        if parent_index is_not -1 cast(u32)
        {
            assert(parent_index < i);
            state.mesh_nodes_to_world[i] = state.mesh_nodes_to_world[parent_index] * nodes.nodes_to_parent[i] * animation_delta;
        }
        else
        {
            state.mesh_nodes_to_world[i] = mesh_to_world * nodes.nodes_to_parent[i] * animation_delta;
        }
    }

    loop var i u32; nodes.blend_node_count
    {
        var node_index = nodes.blend_node_to_node_indices[i];
        state.blend_nodes_to_world[i] = state.mesh_nodes_to_world[node_index] * nodes.mesh_to_blend_nodes[i];       
    } 
}