
import string;
import platform;
import memory;

var platform platform_api;
platform_init(platform ref);

platform_enable_console();

var memory memory_arena;
init(memory ref);

var output_memory memory_arena;
init(output_memory ref);

var source = platform_read_entire_file(platform ref, memory ref, "code/lang.h");

label main_loop while source.count
{
    var line = next_line(source ref);
    
    if try_skip_keyword(line ref, "struct")
    {
        var name = try_skip_name(line ref);
        assert(name.count);
        
        // skip forward declarations
        if try_skip(line ref, ";")
            continue;
        
        if not starts_with(name, "ast_")
            continue;
        
        def type_blacklist = [
            "ast_base_node",
        ] string[];
        
        loop var i; type_blacklist.count
            if name is type_blacklist[i]
                continue main_loop;
    
        allocate_text(output_memory ref, "struct %\n\r", name);
        allocate_text(output_memory ref, "{\n\r");
        // format leading tab spaces     "            "
        allocate_text(output_memory ref, "    expand  base ast_base_node;\n\r");
        
        while source.count
        {
            line = next_line(source ref);
            
            if try_skip(line ref, "}")
                break;
            
            if try_skip_keyword(line ref, "ast_base_node")
                continue;
                
            var type = try_skip_name(line ref);
            if not type.count
                continue;
            
            var indirection_count = try_skip_set(line ref, "*");
            
            var field = try_skip_name(line ref);
            assert(field.count);
            
            // 3 leading tab spaces
            allocate_text(output_memory ref, "            % %", field, type);
            
            loop var i usize; indirection_count
                allocate_text(output_memory ref, " ref");
            
            allocate_text(output_memory ref, ";\n\r");
        }

        allocate_text(output_memory ref, "}\n\r");
        allocate_text(output_memory ref, "\n\r");
    }
}

var output = {  output_memory.used_count, output_memory.base } string;
platform_write_entire_file(platform ref, "lang_compiler.t", output);

def name_blacklist = " \t\n\r+-*/!\"\\§²³^°$%&/()[]{}=?`´'#~<>|,;.:";
def white_set = " \t\n\r";

func next_line(iterator string ref) (line string)
{
    var line = try_skip_until(iterator, "\n", true);
    if not line.count
    {
        line = iterator deref;
        advance(iterator, iterator.count);
    }
    
    skip_white(line ref);
    
    return line;
}

func try_skip_name(iterator string ref) (name string)
{
    var name = try_skip_until_set(iterator, name_blacklist, false);
    if name.count
        skip_white(iterator);
        
    return name;
}

func skip_white(iterator string ref) (count usize)
{
    var count = iterator.count;
    
    while iterator.count
    {
        if try_skip(iterator, "//")
            next_line(iterator);
        else if not try_skip_set(iterator, white_set)
            break;
    }
    
    return count - iterator.count;
}

func try_skip_keyword(iterator string ref, keyword string) (ok b8)
{
    var test = iterator deref;
    
    var name = try_skip_name(test ref);
    if name is keyword
    {
        iterator deref = test;
        return true;
    }
    
    return false;
}