
module timing;

import platform;
import memory;
import meta;

// can be overriden
def timing_enabled = lang_debug;

func timing_init(frame_count u32)
{
    if timing_enabled
    {
        var table = global_timing_table ref;
        init(table.memory ref);
        
        reallocate_array(table.memory ref, table.frames ref, frame_count);
    }
}

func timer_frame_begin(location = get_call_location())
{
    if timing_enabled
    {
        var table = global_timing_table ref;
        
        table.current_frame = (table.current_frame + 1) mod table.frames.count cast(u32);
        
        var frame_entry_count = table.frames[table.current_frame].count;
        
        move_array(table.entries, 0, frame_entry_count);
        
        reallocate_array(table.memory ref, table.entries ref, table.entries.count - frame_entry_count);
        table.frame_begin_entry_count = table.entries.count cast(u32);
        
        loop var i; table.frames.count
        {
            table.frames[i].base -= frame_entry_count;
        }
        
        table.frames[table.current_frame] = {} timing_entry[];
        
        table.current_entry = 0;
        push_timer(location);
    }
}

func timer_frame_end()
{
    if timing_enabled
    {
        pop_timer();
    
        var table = global_timing_table ref;
        var frame = table.frames[table.current_frame] ref;
        frame.base  = table.entries.base + table.frame_begin_entry_count;
        frame.count = table.entries.count - table.frame_begin_entry_count;
    }
}

func push_timer(location = get_call_location()) (entry timing_entry ref)
{
    if timing_enabled
    {
        var table = global_timing_table ref;
        reallocate_array(table.memory ref, table.entries ref, table.entries.count + 1);
        
        var entry = table.entries[table.entries.count - 1] ref;
        entry.location = location;
        entry.parent_entry = table.current_entry;
        table.current_entry = table.entries.count cast(u32) - 1;
        
        entry.cpu_cycle_counter = platform_cpu_cycle_counter();
        entry.realtime_counter  = platform_realtime_counter();
        
        return entry;
    }
    else
    {
        return null;
    }
}

func pop_timer()
{
    if timing_enabled
    {
        var cpu_cycle_counter = platform_cpu_cycle_counter();
        var realtime_counter  = platform_realtime_counter();
    
        var table = global_timing_table ref;
        var entry = table.entries[table.current_entry] ref;
        table.current_entry = entry.parent_entry;
        
        entry.realtime_counter = realtime_counter   - entry.realtime_counter;
        entry.cpu_cycle_counter = cpu_cycle_counter - entry.cpu_cycle_counter;
    }
}

struct timing_entry
{
    location          lang_code_location;
    realtime_counter  u64;
    cpu_cycle_counter u64;
    parent_entry      u32;
}

struct timing_table
{
    memory memory_arena;
    entries timing_entry[];
    
    frames timing_entry[][];
    frame_begin_entry_count u32;
    current_frame u32;
    
    current_entry u32;
}

var global global_timing_table timing_table;