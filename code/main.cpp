
#if defined _DEBUG
    #define LANG_BREAK_ON_ERROR
#endif

#include "basic.h"
#include "lang_c.h"

struct lang_source
{
    string name;
    string text;
};

buffer_type(lang_sources, lang_source_array, lang_source);

void convert_path_slashes(string path)
{
    for (u32 i = 0; i < path.count; i++)
        if (path.base[i] == '\\')
            path.base[i] = '/';
}

void append(lang_sources *sources, string_builder *source_name_builder, string source_name)
{
    // filter *.t files
    if ((source_name.count < 2) || (source_name.base[source_name.count - 1] != 't') || (source_name.base[source_name.count - 2] != '.'))
        return;
    
    // copy path persistantly
    // note that this may move the memory, so previous source name bases need to be recomputed later
    source_name = print(source_name_builder, "%.*s", fs(source_name));

    convert_path_slashes(source_name);
    
    resize_buffer(sources, sources->count + 1);
    require(platform_allocate_and_read_entire_file(&sources->base[sources->count - 1].text, (cstring) source_name.base));
    sources->base[sources->count - 1].name = source_name;
}

void print_usage(cstring executable_name)
{
    printf("usage:\n\t%s -cpp <cpp output name> <list of files and directories to compile>\n", executable_name);
    printf("\t%s -exe <exe name> <list of files and directories to compile> (only in VS command prompt)\n", executable_name);
    printf("\nexamples:\n\t%s -cpp hello_triangle.cpp tests/triangle.t modules modules/win32\n", executable_name);
    printf("\t%s -exe hello_triangle tests/triangle.t modules modules/win32\n", executable_name);
}

s32 main(s32 argument_count, cstring arguments[])
{
    if (argument_count < 4)
    {
        print_usage(arguments[0]);
        return -1;
    }
    
    cstring cpp_output_file = "build/lang_output.cpp";
    cstring exe_output_file = null;
    bool build_debug = false;
    u32  enable_array_bound_checks = -1;
    bool has_target = false;    
    bool argument_error = false;
    
    lang_sources sources = {};
    
    platform_api platform;
    platform_init(&platform);
    
    u64 time_ticks = platform_get_realtime_ticks(&platform);
    u64 start_time_ticks = time_ticks;
    u64 last_time_ticks = time_ticks;
    
    memory_arena memory = {};
    resize_buffer(&memory.buffer, 20 << 20); // 20mb
    
    string_builder source_name_builder = {};
    
    auto working_directory = platform_get_working_directory(&memory);
    
    for (u32 i = 1; i < argument_count; i++)
    {
        string compile_option = cstring_to_string(arguments[i]);
        
        if (compile_option == s("-cpp"))
        {
            if (has_target)
            {
                printf("unexpected -cpp, target already set\n");
                argument_error = true;
                break;
            }
        
            if (i + 1 >= argument_count)
            {
                argument_error = true;
                break;
            }
            
            has_target = true;
            cpp_output_file = arguments[++i];
        }
        else if (compile_option == s("-exe"))
        {
            if (has_target)
            {
                printf("unexpected -exe, target already set\n");
                argument_error = true;
                break;
            }
            
            if (i + 1 >= argument_count)
            {
                argument_error = true;
                break;
            }
            
            has_target = true;
            exe_output_file = arguments[++i];
        }        
        else if (compile_option == s("-debug"))
        {
            if (build_debug)
            {
                printf("unexpected -debug, conflicting with previous arguments\n");
                argument_error = true;
                break;
            }
            
            build_debug = true;
        }
        else if (compile_option == s("-enable_array_bound_checks"))
        {
            if (enable_array_bound_checks != -1)
            {
                printf("unexpected -enable_array_bound_checks, conflicting with previous arguments\n");
                argument_error = true;
                break;
            }
            
            enable_array_bound_checks = true;
        }
        else if (compile_option == s("-disable_array_bound_checks"))
        {
            if (enable_array_bound_checks != -1)
            {
                printf("unexpected -disable_array_bound_checks, conflicting with previous arguments\n");
                argument_error = true;
                break;
            }
            
            enable_array_bound_checks = false;
        }
        else // is a file or directory
        {
            auto argument = arguments[i];
            
            auto info = platform_get_file_info(argument);
            if (!info.ok)
            {
                printf("file, directory or option \"%s\" does not exist\n", argument);
                argument_error = true;
                break;
            }
            
            if (info.is_directory)
            {
                char _pattern[1024];
                usize count = sprintf_s(_pattern, carray_count(_pattern), "%s/*", argument);
                string pattern = { count, (u8 *) _pattern };
                
                convert_path_slashes(pattern);
                
                auto iterator = platform_file_search_begin(&platform, pattern, &memory);
                
                while (platform_file_search_next(&platform, &iterator, &memory))
                {
                    auto file = iterator.found_file;
                    if (file.is_directory)
                        continue;
                    
                    append(&sources, &source_name_builder, file.absolute_path);
                }
                
                platform_file_search_end(&platform, &iterator, &memory);
            }
            else
            {
                auto absolute_path = get_absolute_path(&memory, working_directory, cstring_to_string(argument));
                append(&sources, &source_name_builder, absolute_path);
            }
        }
    }
    
    if (!has_target)
        argument_error;
        
    if (argument_error)
    {
        print_usage(arguments[0]);
        return -1;
    }
    
    lang_parser parser = {};
    parser.lang_internal_source = platform_read_embedded_file("LANG_INTERNAL.T");
    reset(&parser);
    
    time_ticks = platform_get_realtime_ticks(&platform);
    u64 load_files_ticks = time_ticks - last_time_ticks;
    last_time_ticks = time_ticks;
    
    usize byte_offset = 0;
    for (auto i = 0; i < sources.count; i++)
    {
        // since source_name_builder memory might have moved, so we need to recompute the base
        sources.base[i].name.base = source_name_builder.memory.base + byte_offset;
        byte_offset += sources.base[i].name.count;
        if (!parse(&parser, sources.base[i].text, sources.base[i].name))
            break;
    }
    
    if (enable_array_bound_checks == -1)
        enable_array_bound_checks = build_debug;
    
    string bool_names[] =
    {
        s("false"),
        s("true")
    };
    
    if (build_debug || enable_array_bound_checks)
    {
        auto platform_internal_build_source = print(&memory, "override lang lang_debug = true; override lang lang_enable_array_boun_checks = %.*s;", fs(bool_names[enable_array_bound_checks]));
        parse(&parser, platform_internal_build_source, s("internal_lang_build"));
    }
    
    time_ticks = platform_get_realtime_ticks(&platform);
    u64 parse_ticks = time_ticks - last_time_ticks;
    last_time_ticks = time_ticks;
    
    if (!parser.error)
        resolve(&parser);
    
    time_ticks = platform_get_realtime_ticks(&platform);
    u64 resolve_ticks = time_ticks - last_time_ticks;
    last_time_ticks = time_ticks;
    
    u64 compile_ticks = 0;
    u64 save_output_ticks = 0;
    if (!parser.error)
    {
        lang_c_compile_settings settings = {};
        //settings.prefix = s("tk_");
        auto output = compile(&parser, settings);
        
        time_ticks = platform_get_realtime_ticks(&platform);
        compile_ticks = time_ticks - last_time_ticks;
        last_time_ticks = time_ticks;
        
        if (exe_output_file)
            system("if not exist build mkdir build");
        
        platform_write_entire_file(cpp_output_file, output.builder.memory.array);
        
        time_ticks = platform_get_realtime_ticks(&platform);
        save_output_ticks = time_ticks - last_time_ticks;
        last_time_ticks = time_ticks;
    }
    
    if (parser.error)
    {
        printf("\nError: %.*s\n", fs(parser.error_messages.memory.array));
        return -1;
    }
        
    u64 cpp_compile_output_ticks = 0;
    if (!parser.error && exe_output_file)
    {
        system("if not exist build mkdir build");
        
        u8 _lang_path[MAX_PATH];
        string lang_path;
        lang_path.base = _lang_path;
        lang_path.count = GetModuleFileName(NULL, (char *) lang_path.base, MAX_PATH);
        
        {
            u32 lang_path_count = 0;
            for (u32 i = 0; i < lang_path.count; i++)
            {
                if (lang_path.base[i] == '/')
                    lang_path.base[i] = '\\';
                    
                if (lang_path.base[i] == '\\')
                    lang_path_count = i;
            }
            
            lang_path.count = lang_path_count;
        }
        
        string command;
        if (build_debug)
            command = print(&memory, "pushd build & cl /Fe../%s ../%s /MTd /Od /DEBUG /Zi /EHsc /nologo /link /INCREMENTAL:NO /LIBPATH:\"%.*s\\debug\" & popd\0", exe_output_file, cpp_output_file, fs(lang_path));
        else
            command = print(&memory, "pushd build & cl /Fe../%s ../%s /MT /O2 /EHsc /nologo /link /INCREMENTAL:NO /LIBPATH:\"%.*s\\release\" & popd\0", exe_output_file, cpp_output_file, fs(lang_path));
        
        system((char *) command.base);
        // TODO: check if cl could be executed
        
        time_ticks = platform_get_realtime_ticks(&platform);
        cpp_compile_output_ticks = time_ticks - last_time_ticks;
        last_time_ticks = time_ticks;
    }
    
    time_ticks = platform_get_realtime_ticks(&platform);
    u64 total_ticks = time_ticks - start_time_ticks;
    
    usize line_count = 0;
    usize byte_count = 0;
    for (auto i = 0; i < sources.count; i++)
    {
        auto text = sources.base[i].text;
        
        for (usize i = 0; i < text.count; i++)
        {
            if (text.base[i] == '\n')
                line_count++;
        }
        
        if (text.count)
            line_count++;
        
        byte_count += text.count;
    }
    
    printf("    load files time: % 6.3fs (%12.2f lines per second, %15.2f bytes per second)\n", (f32) load_files_ticks / platform.ticks_per_second,  (f32) line_count * platform.ticks_per_second / load_files_ticks,  (f32) byte_count * platform.ticks_per_second / load_files_ticks);
    printf("         parse time: % 6.3fs (%12.2f lines per second, %15.2f bytes per second)\n", (f32) parse_ticks / platform.ticks_per_second,       (f32) line_count * platform.ticks_per_second / parse_ticks,       (f32) byte_count * platform.ticks_per_second / parse_ticks);
    printf("       resolve time: % 6.3fs (%12.2f lines per second, %15.2f bytes per second)\n", (f32) resolve_ticks / platform.ticks_per_second,     (f32) line_count * platform.ticks_per_second / resolve_ticks,     (f32) byte_count * platform.ticks_per_second / resolve_ticks);
    printf("  compile to C time: % 6.3fs (%12.2f lines per second, %15.2f bytes per second)\n", (f32) compile_ticks / platform.ticks_per_second,     (f32) line_count * platform.ticks_per_second / compile_ticks,     (f32) byte_count * platform.ticks_per_second / compile_ticks);
    printf(" save C output time: % 6.3fs (%12.2f lines per second, %15.2f bytes per second)\n", (f32) save_output_ticks / platform.ticks_per_second, (f32) line_count * platform.ticks_per_second / save_output_ticks, (f32) byte_count * platform.ticks_per_second / save_output_ticks);
    printf("compile to exe time: % 6.3fs (%12.2f lines per second, %15.2f bytes per second)\n", (f32) cpp_compile_output_ticks / platform.ticks_per_second, (f32) line_count * platform.ticks_per_second / cpp_compile_output_ticks, (f32) byte_count * platform.ticks_per_second / cpp_compile_output_ticks);
    printf("         total time: % 6.3fs (%12.2f lines per second, %15.2f bytes per second)\n", (f32) total_ticks / platform.ticks_per_second,       (f32) line_count * platform.ticks_per_second / total_ticks,       (f32) byte_count * platform.ticks_per_second / total_ticks);
    
#if defined _DEBUG
    printf("resolve table max probe step count: %llu\n", parser.resolve_table.max_step_count);
#endif
    
    byte_count_info info;
    info.value = byte_count;
    printf("      total count: %llu lines (%llugb %llumb %llukb %llub)\n", line_count, info.giga, info.mega, info.kilo, info.byte);
    printf("\n");
    
    
#if defined _DEBUG

    if (0)
    {
        auto table = &global_debug_platform_allocation_table;
        
        byte_count_info info;
        info.value = table->byte_count;
        printf("\nMemory: %llugb %llumb %llukb %llub (in %llu different allocations)\n", info.giga, info.mega, info.kilo, info.byte, table->count);
        for (usize i = 0; i < table->count; i++)
        {
            auto location = table->locations[i];
            printf("Allocation: %s,%s(%i) 0x%08p %llu bytes\n", location.file, location.function, location.line, table->bases[i], table->byte_counts[i]);
        }
    }

#endif
    
    return 0;
}