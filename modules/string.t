
module string;

import platform;
import memory;
import math;
import meta;

struct string_builder_settings
{
    fraction_digit_count u32;
    add_enum_type b8;
}

def default_string_builder_settings = { 3, false } string_builder_settings;

struct string_builder
{
    text     string;
    capacity usize;
    settings string_builder_settings;
}

func string_builder_from_buffer(buffer string, settings = default_string_builder_settings) (builder string_builder)
{
    var builder string_builder;
    builder.text = buffer;
    builder.capacity = builder.text.count;
    builder.text.count = 0;
    builder.settings = settings;

    return builder;
}

func grow(builder string_builder ref, count usize, location = get_call_location()) (offset usize)
{
    assert((builder.text.count + count) <= builder.capacity, location);

    var offset = builder.text.count;
    builder.text.count = builder.text.count + count;

    return offset;
}

func write(builder string_builder ref, text string, location = get_call_location()) (result string)
{
    if not builder.capacity
        return { text.count, null } string;

    var offset = grow(builder, text.count, location);

    loop var i usize; text.count
        (builder.text.base + offset + i) deref = text[i]; // avoid array bound checks

    return { text.count, builder.text.base + offset } string;
}

func write_indent(builder string_builder ref = null, indent_count usize = 4, character u8 = " "[0], location = get_call_location()) (result string)
{
    if not builder.capacity
        return { indent_count, null } string;

    var offset = grow(builder, indent_count, location);

    loop var i usize; indent_count
    {
        (builder.text.base + offset + i) deref = character; // avoid array bound checks
    }

    return { indent_count, builder.text.base + offset } string;
}

struct format_string_input
{
    formatter write_formatter;

    text                string;
    max_character_count usize;
    pad_right          b8;
    padding_character   u8;
}

func pad_left(text string, max_character_count usize, padding_character u8 = " "[0], location = get_call_location()) (result format_string_input)
{
    assert(max_character_count >= text.count, location);

    var result format_string_input;
    result.formatter           = get_function_reference(write_formatter_string write_formatter);
    result.text                = text;
    result.pad_right           = false;
    result.max_character_count = max_character_count;
    result.padding_character   = padding_character;
    return result;
}

func pad_right(builder string_builder ref = null, text string, max_character_count usize, padding_character u8 = " "[0], location = get_call_location()) (result format_string_input)
{
    assert(max_character_count >= text.count, location);

    var result format_string_input;
    result.formatter           = get_function_reference(write_formatter_string write_formatter);
    result.text                = text;
    result.pad_right           = true;
    result.max_character_count = max_character_count;
    result.padding_character   = padding_character;
    return result;
}

func write_formatter_string write_formatter
{
    var input = formatter cast(format_string_input ref) deref;

    if not builder.capacity
        return { input.max_character_count, null } string;

    var offset = grow(builder, input.max_character_count, location);

    if not input.pad_right
    {
        var padding_count = input.max_character_count - input.text.count;
        loop var i usize; padding_count
        {
            //(builder.text.base + offset + i) deref = input.padding_character;
            var x = (builder.text.base + offset + i);
            x deref = input.padding_character;
        }

        offset += padding_count;
    }

    loop var i usize; input.text.count
        (builder.text.base + offset + i) deref = input.text[i]; // avoid array bound checks

    if input.pad_right
    {
        var padding_count = input.max_character_count - input.text.count;
        offset += input.text.count;

        loop var i usize; padding_count
        {
            //(builder.text.base + offset + i) deref = input.padding_character;
            var x = (builder.text.base + offset + i);
            x deref = input.padding_character;
        }
    }

    return { input.max_character_count, builder.text.base + builder.text.count - input.max_character_count } string;
}

func write_newline(builder string_builder ref) (result string)
{
    return write(builder, "\n");
}

func write_u64(builder string_builder ref = null, value u64, max_digit_count u32 = 0, padding_character u8 = "0"[0], base u8 = 10, first_character_after_9 = "a"[0], location = get_call_location()) (result string)
{
    assert(base > 1, location);

    var digit_count u32 = 0;
    {
        var test_value = value;
        while test_value
        {
            digit_count = digit_count + 1;
            test_value = test_value / base;
        }

        if not digit_count
            digit_count = 1;
    }

    assert(not max_digit_count or (digit_count <= max_digit_count), location);

    if not max_digit_count
        max_digit_count = digit_count;

    if not builder.capacity
        return { max_digit_count, null } string;

    var offset = grow(builder, max_digit_count, location);

    if max_digit_count
        loop var i u32; max_digit_count - digit_count
            builder.text[offset + i] = padding_character;

    loop var i u32; digit_count
    {
        var digit u8 = (value mod base) cast(u8);
        value = value / base;

        var index = builder.text.count - 1 - i;
        if digit < 10
            builder.text[index] = digit + "0"[0];
        else
            builder.text[index] = digit - 10 + first_character_after_9;
    }

    return { max_digit_count, builder.text.base + builder.text.count - max_digit_count } string;
}

func write_hex(builder string_builder ref = null, value u64, first_character_after_9 u8 = "a"[0], max_digit_count u32 = 0, padding_character u8 = "0"[0], location = get_call_location()) (result string)
{
    return write_u64(builder, value, max_digit_count, padding_character, 16, first_character_after_9, location);
}

func write_s64(builder string_builder ref = null, value s64, max_digit_count u32 = 0, padding_character u8 = "0"[0], base u8 = 10, first_character_after_9 u8 = "a"[0], location = get_call_location()) (result string)
{
    var byte_count usize;
    if value < 0
    {
        byte_count = write(builder, "-", location).count;
        value = -value;
    }
    else if max_digit_count
    {
        byte_count = write(builder, " ", location).count;
    }

    byte_count += write_u64(builder, value cast(u64), max_digit_count, padding_character, base, first_character_after_9, location).count;

    if not builder.capacity
        return { byte_count, null } string;
    else
        return { byte_count, builder.text.base + builder.text.count - byte_count } string;
}

func write_f64(builder string_builder ref = null, value f64, fraction_digit_count u32, fraction_character = "."[0], max_whole_digit_count u32 = 0, padding_character u8 = "0"[0], base u8 = 10, first_character_after_9 u8 = "a"[0], location = get_call_location()) (result string)
{
    var byte_count usize;
    if value < 0
    {
        byte_count = write(builder, "-", location).count;
        value = -value;
    }

    var whole_number = value cast(u64);
    byte_count += write_u64(builder, whole_number, max_whole_digit_count, padding_character, base, first_character_after_9, location).count + fraction_digit_count + 1;

    if not builder.capacity
        return { byte_count, null } string;

    var offset = grow(builder, fraction_digit_count + 1, location);
    builder.text[offset] = fraction_character;

    var fraction f64 = absolute(value - whole_number);

    loop var i usize; fraction_digit_count
    {
        var digit = (fraction * base) cast(u8);
        fraction = fraction * base;
        fraction = fraction - ((fraction) cast(s32));

        if digit < 10
            builder.text[offset + 1 + i] = digit + "0"[0];
        else
            builder.text[offset + 1 + i] = digit - 10 + first_character_after_9;
    }

    return { byte_count, builder.text.base + builder.text.count - byte_count } string;
}

func write_formatter(builder string_builder ref = null, formatter u8 ref, location = get_call_location()) (result string);

struct format_u64_input
{
    formatter write_formatter;

    value                   u64;
    max_digit_count         u32;
    padding_character       u8;
    base                    u8;
    first_character_after_9 u8;
}

func format_value(value u64, max_digit_count u32 = 0, padding_character = "0"[0], base u8 = 10, first_character_after_9 = "a"[0]) (result format_u64_input)
{
    var result format_u64_input;
    result.formatter = get_function_reference(write_formatter_u64 write_formatter);
    result.value                   = value;
    result.max_digit_count         = max_digit_count;
    result.padding_character       = padding_character;
    result.base                    = base;
    result.first_character_after_9 = first_character_after_9;

    return result;
}

func format_hex(value u64, first_character_after_9 = "a"[0], max_digit_count u32 = 0, padding_character = "0"[0]) (result format_u64_input)
{
    return format_value(value, max_digit_count, padding_character, 16, first_character_after_9);
}

func write_formatter_u64 write_formatter
{
    var input = formatter cast(format_u64_input ref) deref;
    return write_u64(builder, input.value, input.max_digit_count, input.padding_character, input.base, input.first_character_after_9, location);
}

struct format_s64_input
{
    formatter write_formatter;

    value                   s64;
    max_digit_count         u32;
    padding_character       u8;
    base                    u8;
    first_character_after_9 u8;
}

func format_value(value s64, max_digit_count u32 = 0, padding_character = "0"[0], base u8 = 10, first_character_after_9 = "a"[0]) (result format_s64_input)
{
    var result format_s64_input;
    result.formatter = get_function_reference(write_formatter_s64 write_formatter);
    result.value                   = value;
    result.max_digit_count         = max_digit_count;
    result.padding_character       = padding_character;
    result.base                    = base;
    result.first_character_after_9 = first_character_after_9;

    return result;
}

func write_formatter_s64 write_formatter
{
    var input = formatter cast(format_s64_input ref) deref;
    return write_s64(builder, input.value, input.max_digit_count, input.padding_character, input.base, input.first_character_after_9, location);
}

struct format_f64_input
{
    formatter write_formatter;

    value                   f64;
    fraction_digit_count    u32;
    max_whole_digit_count   u32;
    base                    u8;
    fraction_character      u8;
    padding_character       u8;
    first_character_after_9 u8;
}

func format_value(value f64, fraction_digit_count u32, fraction_character = "."[0], max_whole_digit_count u32 = 0, padding_character = "0"[0], base u8 = 10, first_character_after_9 = "a"[0]) (result format_f64_input)
{
    var result format_f64_input;
    result.formatter = get_function_reference(write_formatter_f64 write_formatter);
    result.value = value;
    result.fraction_digit_count = fraction_digit_count;
    result.fraction_character = fraction_character;
    result.max_whole_digit_count = max_whole_digit_count;
    result.padding_character = padding_character;
    result.base = base;
    result.first_character_after_9 = first_character_after_9;

    return result;
}

func write_formatter_f64 write_formatter
{
    var input = formatter cast(format_f64_input ref) deref;
    return write_f64(builder, input.value, input.fraction_digit_count, input.fraction_character, input.max_whole_digit_count, input.padding_character, input.base, input.first_character_after_9, location);
}

func get_u64_value(number lang_typed_value) (value u64)
{
    assert(number.type.type_type is lang_type_info_type.number);

    var value u64;
    var number_type = number.type.number_type deref;

    multiline_comment
    {
        if number_type.is_float
        {
            switch number_type.byte_count_and_alignment
            case 4
                result = number.f32_number cast(u64);
            case 8
                result = number.f64_number cast(u64);
        }
        else if number_type.is_signed
        {
            result = number.s64_number cast(u64);
        }
        else
        {
            result = number.u64_number;
        }
    }

    if number_type.is_float
    {
        switch number_type.byte_count_and_alignment
        case 4
            value = number.base cast(f32 ref) deref cast(u64);
        case 8
            value = number.base cast(f64 ref) deref cast(u64);
    }
    else if number_type.is_signed
    {
        switch number_type.byte_count_and_alignment
        case 1
            value = number.base cast(s8 ref) deref cast(u64);
        case 2
            value = number.base cast(s16 ref) deref cast(u64);
        case 4
            value = number.base cast(s32 ref) deref cast(u64);
        case 8
            value = number.base cast(s64 ref) deref cast(u64);
    }
    else
    {
        switch number_type.byte_count_and_alignment
        case 1
            value = number.base cast(u8 ref) deref;
        case 2
            value = number.base cast(u16 ref) deref;
        case 4
            value = number.base cast(u32 ref) deref;
        case 8
            value = number.base cast(u64 ref) deref;
    }

    return value;
}

func write_typed_value(builder string_builder ref, typed_value lang_typed_value, location = get_call_location(), depth u32 = 0, quoted_strings = false) (result string)
{
    var byte_count usize;

    if typed_value.type.indirection_count
    {
        byte_count += write(builder, "0x").count;
        byte_count += write_hex(builder, typed_value.base cast(u64)).count;
    }
    else
    {
        switch typed_value.type.type_type
        case lang_type_info_type.number
        {
            if typed_value.type.alias is "b8"
            {
                def b8_names = [ "false", "true" ] string[];

                var value = typed_value.base cast(u8 ref) deref;
                byte_count += write(builder, b8_names[value]).count;
                break;
            }

            var number_type = typed_value.type.number_type deref;

            // later we will use union for numbers, instead of pointers to local variables
            multiline_comment
            {
                if number_type.is_float
                {
                    var value f64;
                    switch number_type.byte_count_and_alignment
                    case 4
                        value = typed_value.f32_number;
                    case 8
                        value = typed_value.f64_number;

                    byte_count += write_f64(builder, value, builder.settings.fraction_digit_count).count;
                }
                else if number_type.is_signed
                {
                    var value = typed_value.s64_number;
                    byte_count += write_s64(builder, value).count;
                }
                else
                {
                    var value = typed_value.u64_number;
                    byte_count += write_u64(builder, value).count;
                }
            }

            // just a hack for now
            if number_type.is_float
            {
                var value f64;
                switch number_type.byte_count_and_alignment
                case 4
                    value = typed_value.base cast(f32 ref) deref;
                case 8
                    value = typed_value.base cast(f64 ref) deref;

                byte_count += write_f64(builder, value, builder.settings.fraction_digit_count).count;
            }
            else if number_type.is_signed
            {
                var value s64;

                switch number_type.byte_count_and_alignment
                case 1
                    value = typed_value.base cast(s8 ref) deref;
                case 2
                    value = typed_value.base cast(s16 ref) deref;
                case 4
                    value = typed_value.base cast(s32 ref) deref;
                case 8
                    value = typed_value.base cast(s64 ref) deref;

                byte_count += write_s64(builder, value).count;
            }
            else
            {
                var value u64;

                switch number_type.byte_count_and_alignment
                case 1
                    value = typed_value.base cast(u8 ref) deref;
                case 2
                    value = typed_value.base cast(u16 ref) deref;
                case 4
                    value = typed_value.base cast(u32 ref) deref;
                case 8
                    value = typed_value.base cast(u64 ref) deref;

                byte_count += write_u64(builder, value).count;
            }
        }
        case lang_type_info_type.enumeration
        {
            var enumeration_type = typed_value.type.enumeration_type deref;

            var number lang_typed_value;
            number.type = enumeration_type.item_type;
            number.value = typed_value.value;
            var value = get_u64_value(number);

            var is_first = true;
            loop var i; enumeration_type.items.count
            {
                if value is enumeration_type.items[i].value
                {
                    if not is_first
                        byte_count += write(builder, " or ").count;

                    if builder.settings.add_enum_type
                    {
                        byte_count += write(builder, typed_value.type.alias).count;
                        byte_count += write(builder, ".").count;
                    }

                    byte_count += write(builder, enumeration_type.items[i].name).count;
                    is_first = false;
                }
            }

            if is_first
            {
                byte_count += write(builder, "invalid ").count;
                byte_count += write(builder, typed_value.type.alias).count;
                byte_count += write(builder, " value").count;
            }
        }
        case lang_type_info_type.array
        {
            var array_type = typed_value.type.array_type deref;
            if typed_value.type.alias is "string"
            {
                if quoted_strings
                {
                    byte_count += write(builder, "\"").count;
                    byte_count += write(builder, typed_value.base cast(string ref) deref).count;
                    byte_count += write(builder, "\"").count;
                }
                else
                {
                    byte_count += write(builder, typed_value.base cast(string ref) deref).count;
                }
            }
            else
            {
                var item_value lang_typed_value;
                item_value.type = array_type.item_type;

                var base_array lang_base_array;

                if array_type.item_count is 0
                {
                    base_array = typed_value.base_array deref;
                }
                else
                {
                    base_array.count = array_type.item_count;
                    base_array.base  = typed_value.base;
                }

                byte_count += write(builder, "[").count;
                byte_count += write_u64(builder, base_array.count).count;
                byte_count += write(builder, "][ ").count;

                var add_newlines = base_array.count > 10;

                if add_newlines
                    byte_count += write_newline(builder).count;

                loop var i usize; base_array.count
                {
                    if add_newlines
                        byte_count += write_indent(builder).count;

                    item_value.base = base_array.base + (item_value.type.byte_count * i);
                    byte_count += write_typed_value(builder, item_value, location, depth + 1).count;
                    byte_count += write(builder, ", ").count;

                    if add_newlines
                        byte_count += write_newline(builder).count;
                }

                byte_count += write(builder, "]").count;
            }
        }
        case lang_type_info_type.compound
        {
            var compound_type = typed_value.type.compound_type deref;

            // write_formatter
            if (compound_type.fields[0].type.reference is get_type_info(write_formatter).reference) and not compound_type.fields[0].type.indirection_count
            {
                var base = typed_value.base cast(write_formatter ref);
                var formatter = base deref;
                byte_count += formatter(builder, base, location).count;
            }
            else
            {
                byte_count += write(builder, "{ ").count;

                if depth is 0
                    byte_count += write_newline(builder).count;

                loop var i; compound_type.fields.count
                {
                    if depth is 0
                        byte_count += write_indent(builder).count;

                    byte_count += write(builder, compound_type.fields[i].name).count;
                    byte_count += write(builder, " = ").count;

                    var field_value lang_typed_value;
                    field_value.type  = compound_type.fields[i].type;
                    field_value.base = typed_value.base + compound_type.fields[i].byte_offset;
                    byte_count += write_typed_value(builder, field_value, location, depth + 1, true).count; // quoted_strings = true
                    byte_count += write(builder, ", ").count;

                    if depth is 0
                        byte_count += write_newline(builder).count;
                }

                byte_count += write(builder, "}").count;
            }
        }
        case lang_type_info_type.union
        {
            var union_type = typed_value.type.union_type deref;

            byte_count += write(builder, "{ ").count;

            // show first field
            {
                var field = union_type.fields[0];

                byte_count += write(builder, field.name).count;
                byte_count += write(builder, " = ").count;

                var field_value lang_typed_value;
                field_value.type  = field.type;
                field_value.value = typed_value.value;
                byte_count += write_typed_value(builder, field_value, location, depth + 1).count;
            }

            byte_count += write(builder, " }").count;
        }
        else
        {
            assert(false);
        }
    }

    if not builder.capacity
        return { byte_count, null } string;
    else
        return { byte_count, builder.text.base + builder.text.count - byte_count } string;
}

func write(builder string_builder ref, format string, location = get_call_location(), expand values lang_typed_value[]) (result string)
{
    var byte_count usize;

    var value_index usize = 0;
    var count usize = 0;
    while count < format.count
    {
        var character = format[count];
        count = count + 1;

        switch character
        //case "\\"[0]
        //{
            //count = count + 1;
        //}
        case "%"[0]
        {
            if count > 1
            {
                var text = { count - 1, format.base } string;
                byte_count += write(builder, text).count;
            }

            format.base  = format.base + count;
            format.count = format.count - count;
            count = 0;

            byte_count += write_typed_value(builder, values[value_index], location).count;
            value_index = value_index + 1;
        }
    }

    if count
    {
        var text = { count, format.base } string;
        byte_count += write(builder, text).count;
    }

    assert(value_index is values.count, location, "too many values passed to print");

    if not builder.capacity
        return { byte_count, null } string;
    else
        return { byte_count, builder.text.base + builder.text.count - byte_count } string;
}

func print_expression(value lang_typed_value, text = get_call_argument_text(value))
{
    print("% = %", text, value);
}

func print_indent(count u32)
{
    loop var i; count
    {
        platform_print("    ");
    }
}

func write_type(builder string_builder ref, type_info lang_type_info, expand_next = false, do_expand = true, depth u32 = 0)
{
    write(builder, type_info.alias);

    if not type_info.alias.count or do_expand
    {
        do_expand = expand_next;

        switch type_info.type_type
        case lang_type_info_type.number
        {
        }
        case lang_type_info_type.compound
        {
            var compound = type_info.compound_type deref;

            if type_info.alias.count
                write(builder, " ");

            write(builder, "compound {\n");

            loop var i; compound.fields.count
            {
                write_indent(builder, depth + 1);
                write(builder, compound.fields[i].name);
                write(builder, " ");
                write_type(builder, compound.fields[i].type, expand_next, do_expand, depth + 1);
                write(builder, ";\n");
            }

            write_indent(builder, depth);
            write(builder, "}");
        }
        case lang_type_info_type.array
        {
            var array = type_info.array_type deref;

            if type_info.alias.count
                write(builder, " ");

            write_type(builder, array.item_type, expand_next, do_expand, depth);

            write(builder, "[");

            if array.item_count
                write_u64(builder, array.item_count);

            write(builder, "]");
        }
        else
        {
            write(builder, "(unhandled)");
        }
    }

    loop var i; type_info.indirection_count
        write(builder, " ref");
}

func write_buffer(buffer u8[], format string, location = get_call_location(), expand values = {} lang_typed_value[]) (text string)
{
    var builder string_builder;
    builder.text.base = buffer.base;
    builder.capacity = buffer.count;
    var text = write(builder ref, format, values);
    return text;
}

func print_type(location = get_call_location(), format string, expand values = {} lang_typed_value[]);

func print print_type
{
    var buffer u8[4096];
    var text = write(buffer, format, location, values);
    platform_print(text);
}

func print_line print_type
{
    print(location, format, values);
    platform_print("\n");
}

func debug_print print_type
{
    if lang_debug
        print(location, format, values);
}

func debug_print_line print_type
{
    if lang_debug
        print_line(location, format, values);
}

func allocate_text(memory memory_arena ref, settings = default_string_builder_settings, text string, location = get_call_location()) (result string)
{
    var byte_count = text.count;

    var builder string_builder;
    builder.settings = settings;
    builder.capacity = byte_count;
    builder.text.base = allocate(memory, builder.capacity, 1);
    var result = write(builder ref, text);
    return result;
}

func allocate_text(memory memory_arena ref, settings = default_string_builder_settings, format string, location = get_call_location(), expand values lang_typed_value[]) (result string)
{
    var builder string_builder;
    builder.settings = settings;
    builder.capacity = write(builder ref, format, values).count;
    builder.text.base = allocate(memory, builder.capacity, 1);
    var result = write(builder ref, format, values);
    return result;
}

func print(tmemory memory_arena ref, settings = default_string_builder_settings, format string, location = get_call_location(), expand values = {} lang_typed_value[])
{
    var result = allocate_text(tmemory, settings, format, values);
    platform_print(result);

    free(tmemory, result.base);
}

func write(buffer u8[], settings = default_string_builder_settings, format string, location = get_call_location(), expand values lang_typed_value[]) (text string)
{
    var builder string_builder;
    builder.text.base = buffer.base;
    builder.capacity  = buffer.count;
    builder.settings  = settings;
    write(builder ref, format, values);

    return builder.text;
}

func write(memory memory_arena ref, text string ref, settings = default_string_builder_settings, format string, location = get_call_location(), expand values lang_typed_value[]) (text string)
{
    var sub_text = allocate_text(memory, settings, format, location, values);

    if not sub_text.count
        sub_text.base = text.base + text.count;

    text.count += sub_text.count;
    text.base = sub_text.base + sub_text.count - text.count;

    return sub_text;
}

func write(memory memory_arena ref, text string ref, settings = default_string_builder_settings, raw_text string, location = get_call_location()) (text string)
{
    var sub_text = allocate_text(memory, settings, raw_text, location);
    text.count += sub_text.count;
    text.base = sub_text.base + sub_text.count - text.count;
    return sub_text;
}

func write(memory memory_arena ref, settings = default_string_builder_settings, format string, location = get_call_location(), expand values lang_typed_value[]) (text string)
{
    var text string;
    return write(memory, text ref, settings, format, location, values);
}

func starts_with(text string, prefix string) (result b8)
{
    if text.count < prefix.count
        return false;

    loop var i; prefix.count
    {
        if text[i] is_not prefix[i]
            return false;
    }

    return true;
}

func write_location(builder string_builder ref, location lang_code_location)
{
    write(builder, "%/% %(%,%)", location.module, location.function, location.file, location.line, location.column);
}

func print_location(location lang_code_location)
{
    print("%/% %(%,%)", location.module, location.function, location.file, location.line, location.column);
}

func try_skip(iterator string ref, pattern string, location = get_call_location()) (ok b8)
{
    if iterator.count < pattern.count
        return false;

    loop var i; pattern.count
    {
        if iterator[i] is_not pattern[i]
            return false;
    }

    advance(iterator, pattern.count);
    return true;
}

func skip(iterator string ref, pattern string, location = get_call_location())
{
    var ok = try_skip(iterator, pattern, location);
    assert(ok);
}

// assuming set only consistes one byte characters
func try_skip_set(iterator string ref, set string, location = get_call_location()) (count usize)
{
    var count usize;

    label main_loop while count < iterator.count
    {
        loop var i; set.count
        {
            if iterator[count] is set[i]
            {
                count += 1;
                continue main_loop;
            }
        }

        break;
    }

    advance(iterator, count);
    return count;
}

func try_skip_until(iterator string ref, pattern string, skip_pattern = true, skip_on_end = true, location = get_call_location()) (skipped_text string)
{
    var text = iterator deref;

    while text.count >= pattern.count
    {
        if try_skip(text ref, pattern)
        {
            var count = (text.base - iterator.base) cast(usize);

            if not skip_pattern
                count = count - pattern.count;

            var skipped_text string;
            skipped_text.base  = iterator.base;
            skipped_text.count = count;
            advance(iterator, count);

            return skipped_text;
        }
        else
        {
            advance(text ref);
        }
    }

    if skip_on_end
    {
        var skipped_text = iterator deref;
        advance(iterator, iterator.count);
        return skipped_text;
    }

    return {} string;
}

func try_skip_until_set(iterator string ref, set string, skip_set = true, skip_on_end = true, location = get_call_location()) (skipped_text string)
{
    var text = iterator deref;

    while text.count
    {
        var skip_count = try_skip_set(text ref, set);
        if skip_count
        {
            var count = (text.base - iterator.base) cast(usize);

            var skipped_text string;
            skipped_text.base  = iterator.base;
            skipped_text.count = count - skip_count; // without set

            if not skip_set
                count = count - skip_count;

            advance(iterator, count);

            return skipped_text;
        }
        else
        {
            advance(text ref);
        }
    }

    if skip_on_end
    {
        var skipped_text = iterator deref;
        advance(iterator, iterator.count);
        return skipped_text;
    }

    return {} string;
}

func try_parse_f64(value f64 ref, text string ref, base u8 = 10) (ok b8)
{
    var is_signed = try_skip(text, "-");
    if not is_signed
        try_skip(text, "+");

    var whole u64;
    if not try_parse_u64(whole ref, text, base)
        return false;

    var fraction f64 = 0;
    if try_skip(text, ".")
    {
        var count usize;
        var factor   f64 = base;

        while count < text.count
        {
            var head = text[count];
            var digit u8;
            if not try_get_digit(digit ref, head, base)
                break;

            fraction = fraction + (digit / factor);
            factor   = factor * base;

            count = count + 1;
        }

        advance(text, count);
    }

    if is_signed
        value deref = -(whole + fraction);
    else
        value deref = whole + fraction;

    return true;
}

func try_parse_f32(value f32 ref, text string ref, base u8 = 10) (ok b8)
{
    var value_f64 f64;
    var ok = try_parse_f64(value_f64 ref, text, base);
    value deref = value_f64 cast(f32);

    return ok;
}

func try_parse_s64(value s64 ref, text string ref, base u8 = 10) (ok b8)
{
    var is_signed = try_skip(text, "-");
    if not is_signed
        try_skip(text, "+");

    var value_u64 u64;
    var ok = try_parse_u64(value_u64 ref, text, base);

    if is_signed
        value deref = -(value_u64 cast(s64));
    else
        value deref = value_u64 cast(s64);

    return ok;
}

func try_parse_s32(out_value s32 ref, text string ref, base u8 = 10) (ok b8)
{
    var value s64;
    if not try_parse_s64(value ref, text, base)
        return false;

    if absolute(value) > (-1 cast(u32))
        return false;

    out_value deref = value cast(s32);
    return true;
}

func try_get_digit(out_digit u8 ref, head u32, base u8 = 10) (ok b8)
{
    var digit = head - "0"[0];

    if digit > 9
    {
        if base <= 10
            return false;

        digit = head - "a"[0] + 10;
        if (digit < 10) or (digit >= base)
            digit = head - "A"[0] + 10;

        if (digit < 10) or (digit >= base)
            return false;
    }

    out_digit deref = digit cast(u8);

    return true;
}

func try_parse_u64(out_value u64 ref, text string ref, base u8 = 10) (ok b8)
{
    var count usize = 0;
    var value u64 = 0;
    while count < text.count
    {
        var head = text[count];
        var digit u8;
        if not try_get_digit(digit ref, head, base)
            break;

        var previous = value;
        value = (value * base) + digit;
        if previous > value
            return false;

        count = count + 1;
    }

    out_value deref = value;
    advance(text, count);

    return count > 0;
}

func try_parse_u32(out_value u32 ref, text string ref, base u8 = 10) (ok b8)
{
    var value u64;
    if not try_parse_u64(value ref, text, base)
        return false;

    if value > (-1 cast(u32))
        return false;

    out_value deref = value cast(u32);
    return true;
}

func to_lower_case(text string)
{
    loop var i usize; text.count
    {
        var head = text[i];
        if ("A"[0] <= head) and (head <= "Z"[0])
            text[i] = head - "A"[0] + "a"[0];
    }
}

struct editable_text
{
    buffer     string;
    edit_offset u32;
    used_count  u32;
}

func get_text(text editable_text) (result string)
{
    return { text.used_count, text.buffer.base } string;
}

func edit_text(text editable_text ref, characters platform_character[] ref) (reset_carret b8)
{
    var reset_carret = false;

    var i u32;
    label character_loop loop i; characters.count
    {
        var character = characters[i];

        if character.is_character
        {
            if (text.used_count < text.buffer.count) and (character.code >= 32) and (character.code < 128)
            {
                var used_count usize = text.used_count;
                insert(text.buffer, used_count ref, text.edit_offset, 1);
                text.used_count = used_count cast(u32);
                text.buffer[text.edit_offset] = character.code cast(u8);
                text.edit_offset += 1;
            }

            reset_carret = true;
        }
        else
        {
            switch character.code
            case platform_special_character.backspace
            {
                if text.edit_offset
                {
                    text.edit_offset -= 1;
                    var used_count usize = text.used_count;
                    remove(text.buffer, used_count ref, text.edit_offset, 1);
                    text.used_count = used_count cast(u32);
                }

                reset_carret = true;
            }
            case platform_special_character.delete
            {
                if text.edit_offset < text.used_count
                {
                    var used_count usize = text.used_count;
                    remove(text.buffer, used_count ref, text.edit_offset, 1);
                    text.used_count = used_count cast(u32);
                }

                reset_carret = true;
            }
            case platform_special_character.enter
            {
                if character.with_shift and not character.with_alt and not character.with_control
                {
                    var used_count usize = text.used_count;
                    insert(text.buffer, used_count ref, text.edit_offset, 1);
                    text.used_count = used_count cast(u32);
                    text.buffer[text.edit_offset] = "\n"[0];
                    text.edit_offset += 1;
                }
                else if not character.with_shift and not character.with_alt and not character.with_control
                {
                    i += 1;
                    break character_loop;
                }
            }
            case platform_special_character.left
            {
                if text.edit_offset
                    text.edit_offset -= 1;

                reset_carret = true;
            }
            case platform_special_character.right
            {
                if text.edit_offset < text.used_count
                    text.edit_offset += 1;

                reset_carret = true;
            }
            case platform_special_character.end
            {
                text.edit_offset = text.used_count;
                reset_carret = true;
            }
            case platform_special_character.home
            {
                text.edit_offset = 0;
                reset_carret = true;
            }
        }
    }

    characters.base  += i;
    characters.count -= i;

    return reset_carret;
}

func split_path(path string) (directory string, name string, extension string)
{
    var directory = { 0, path.base } string;

    while path.count
    {
        var count = try_skip_until(path ref, "/", true, false).count;
        if not count
            break;

        directory.count += count;
    }

    // exlude last "/"
    if directory.count
        directory.count -= 1;

    var name = { 0, path.base } string;

    while path.count
    {
        var count = try_skip_until(path ref, ".", true, false).count;
        if not count
            break;

        name.count += count;
    }

    if not name.count
    {
        name = path;
        advance(path ref, name.count);
    }
    else
    {
        name.count -= 1; // remove .
    }

    var extension = path;

    return directory, name, extension;
}

func get_absolute_path(buffer string, working_directory string, relative_path string) (absolute_path string)
{
    // COMPILER BUG: quotes in get_call_argument_text is not escaped
    def slash = "/"[0];
    assert(not working_directory.count or (working_directory[working_directory.count - 1] is_not slash));
    assert(not relative_path.count or (relative_path[relative_path.count - 1] is_not slash));

    var builder = string_builder_from_buffer(buffer);
    write(builder ref, working_directory);

    while relative_path.count
    {
        var directory = try_skip_until_set(relative_path ref, "/", false, true);
        assert(directory.count);

        try_skip(relative_path ref, "/");

        if directory is ".."
        {
            var path = builder.text;
            loop var i usize; path.count
            {
                if path[path.count - i - 1] is "/"[0]
                {
                    path.count -= i + 1;
                    break;
                }
            }

            builder.text = path;
        }
        else if directory is "."
        {
            assert(builder.text.count);
        }
        else
        {
            write(builder ref, "/%", directory);
        }
    }

    return builder.text;
}

func latin_to_lower_case(text string)
{
    loop var i usize; text.count
    {
        var letter = text[i];
        if (letter >= "A"[0]) and (letter <= "Z"[0])
            text[i] = text[i] - "A"[0] + "a"[0];
    }
}