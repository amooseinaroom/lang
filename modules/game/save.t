def save_version = 0 cast(u32);

multiline_comment
{ 
    specialize save state like so:

    struct save_state_entry
    {
        expand base save_state_entry_base;
        // your data here
    }
}

struct save_state_entry_base
{
    date_and_time platform_date_and_time;    
}

struct save_system
{
    memory  memory_arena;
    version u32;
    slot    u32;
    
    // store last 10 auto saves
    
    entries     save_state_entry[10];
    entry_count u32;
}

func auto_save(platform platform_api ref, state program_state ref)
{
    var tmemory = state.tmemory ref;
    
    if state.save_state.entry_count is state.save_state.entries.count
    {
        copy_array({ state.save_state.entries.count - 1, state.save_state.entries[0] ref } save_state_entry[], { state.save_state.entries.count - 1, state.save_state.entries[1] ref } save_state_entry[]);
        
        state.save_state.entry_count = state.save_state.entries.count - 1;
    }
    
    var entry = state.save_state.entries[state.save_state.entry_count] ref;
    entry.date_and_time = platform_local_date_and_time(platform);    
    state.save_state.entry_count += 1;
    
    var tmemory_backup = tmemory.used_count;
    
    var path = allocate_text(tmemory, "saves/slot_%.sav", state.save_state.slot + 1);
    var data = save_data(tmemory, state.save_state);
    platform_write_entire_file(platform, path, data);
    
    // clear and reallocate dynamic memory
    var save_memory = state.save_state.memory ref;
    clear(save_memory);
    load_data(save_memory, state.save_state, data);
    
    tmemory.used_count = tmemory_backup;
}

func load_slot(platform platform_api ref, state program_state ref, slot u32)
{
    var tmemory = state.tmemory ref;
    var tmemory_backup = tmemory.used_count;      
    
    var path = allocate_text(tmemory, "saves/slot_%.sav", slot + 1);
    var data = platform_read_entire_file(platform, tmemory, path);
    
    load_data(state.save_state.memory ref, state.save_state, data);
    assert(state.save_state.slot is slot);
    assert(state.save_state.version is save_version);
    
    tmemory.used_count = tmemory_backup;
}

func find_first_free_save_slot(platform platform_api ref, tmemory memory_arena ref) (slot u32)
{
    platform_create_directory(platform, "saves", false);
    
    var slot u32;
    loop slot; 64
    {
        var path = allocate_text(tmemory, "saves/slot_%.sav", slot + 1);
        var info = platform_get_file_info(platform, path);
        free(tmemory, path.base);
        
        if not info.ok
            break;
    }
    
    return slot;
}