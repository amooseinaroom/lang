
// no module, so user can just add it

import platform;
import memory;
import string;
import meta;

// can be overridden
def enable_hot_reloading = false;

multiline_comment
{
usage:

// optional
// override def enable_hot_reloading = true;

struct program_state
{
    expand base program_state_base;
}

func program_init program_init_type export
{
}

func program_update program_update_type export
{
    return true;
}

}

// interface

struct program_state_base
{
    memory memory_arena;
}

func program_init_type(platform platform_api ref, state program_state ref);

func program_update_type(platform platform_api ref, state program_state ref, library_was_reloaded b8, state_byte_count usize) (do_continue b8);

// main:

var platform platform_api;
platform_init(platform ref);

var program_name_buffer u8[512];
var program_name = platform_get_executable_name(platform ref, program_name_buffer);

var state program_state ref;
//var state_byte_count = type_byte_count(program_state);

{
    var memory memory_arena;
    init(memory ref);
    
    // using deref = {} prgram_state may cause a stack overflow, because MSVC has a bug for large structs
    allocate(memory ref, state ref);
    clear(value_to_u8_array(state deref));
    state.memory = memory;
}

// load library first, so we can better deal with remedy breakpoints
var library program_library;
if enable_hot_reloading
    library = load_program_library(platform ref, program_name);

program_init(platform ref, state);

var is_first_frame = true;

// skip init time
platform_update_time(platform ref);

while platform_handle_messages(platform ref)
{
    if enable_hot_reloading
    {
        var library_was_reloaded = try_reload_program_library(platform ref, library ref, program_name) or is_first_frame;
        var update = library.update;

        if false
        {
            // sync all exported function pointers from exe to dll
            if library_was_reloaded
            {
                loop var i; lang_global_variables.count
                {
                    var variable = lang_global_variables[i];

                    if not variable.type.indirection_count
                        continue;

                    var library_variable = platform_load_symbol(platform ref, library.platform, variable.name) cast(u8 ref ref);
                    library_variable deref = variable.base cast(u8 ref ref) deref;
                }
            }
        }

        if not update(platform ref, state, library_was_reloaded, 0)
            break;
    }
    else
    {
        if not program_update(platform ref, state, is_first_frame, 0)
            break;
    }

    is_first_frame = false;
}

struct program_library
{
    platform  platform_library;
    timestamp u64;
    update    program_update_type;
}

func load_program_library(platform platform_api ref, name string) (library program_library)
{
    var buffer u8[512];
    var dll_name = write(buffer, "%.dll", name);

    var library program_library;

    var live_index s32 = 0;
    {
        var info = platform_get_file_info(platform, dll_name);
        require(info.ok);

        library.timestamp = info.write_timestamp;

        // allow to run up to 32 instances, each with their own live.dll
        loop live_index; 32
        {
            var buffer u8[512];
            var live_name = write(buffer, "live%.dll", live_index);
            if platform_copy_file(platform, live_name, dll_name)
                break;
        }
    }

    var live_name = write(buffer, "live%", live_index);
    library.platform = platform_load_library(platform, live_name);
    require(library.platform.win32);

    library.update = platform_load_symbol(platform, library.platform, "program_update") cast(program_update_type);
    require(library.update);

    return library;
}

func try_reload_program_library(platform platform_api ref, library program_library ref, name string) (did_reload b8)
{
    var buffer u8[512];
    var dll_name = write(buffer, "%.dll", name);

    var info = platform_get_file_info(platform, dll_name);

    if info.ok and (library.timestamp is_not info.write_timestamp)
    {
        var test_library = platform_load_library(platform, name);
        if test_library.win32
        {
            var test_update = platform_load_symbol(platform, test_library, "program_update") cast(program_update_type);

            if test_update
            {
                platform_free_library(platform, test_library);
                platform_free_library(platform, library.platform);

                library deref = load_program_library(platform, name);

                return true;
            }
        }
    }

    return false;
}
