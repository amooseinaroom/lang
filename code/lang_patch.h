void write_number(string_builder *builder, parsed_number value)
{
    if (value.is_character)
    {
        assert(!value.is_float && !value.is_signed && !value.is_hex);

        print_raw(builder, "\"%c\"[0]", (u8) value.u64_value);
    }
    else if (value.is_float)
    {
        print(builder, "%f", value.f64_value);
    }
    else if (value.is_signed)
    {
        if (value.is_hex)
        {
            if (value.s64_value < 0)
                print(builder, "-0x%llx", value.s64_value);
            else
                print(builder, "0x%llx", value.s64_value);
        }
        else
            print(builder, "%lli", value.s64_value);
    }
    else
    {
        if (value.is_hex)
            print(builder, "0x%llx", value.u64_value);
        else
            print(builder, "%llu", value.u64_value);
    }
}


void write_type(string_builder *builder, lang_complete_type type)
{
    switch (name_type->node_type)
    {
        default:
        {
            print(builder, "typedef ");
            print_type(buffer, type, name);

            print_line(builder, ";");
        } break;

        case ast_node_type_function_type:
        {
            local_node_type(function_type, name_type);

            print(builder, "typedef ");
            print_function_type(buffer, function_type, name, null);
            print_line(builder, ";");
        } break;

        case ast_node_type_compound_type:
        case ast_node_type_union_type:
        {
            auto compound_or_union_type = (ast_compound_type *) name_type;

            if (name_type->node_type == ast_node_type_union_type)
                print(builder, "typedef union ");
            else
                print(builder, "typedef struct ");

            if (name.count)
                print(builder, "%.*s", fs(name));
            else
                print_type(buffer, type);

            print_scope_open(builder);

            for (auto field = compound_or_union_type->first_field; field; field = (ast_variable *) field->node.next)
            {
                print_declaration(buffer, field);
                print_line(builder, ";");
            }

            print_scope_close(builder, false);

            print(builder, " ");

            if (name.count)
                print(builder, "%.*s", fs(name));
            else
                print_type(buffer, type);

            print_line(builder, ";");
        } break;

        case ast_node_type_array_type:
        {
            local_node_type(array_type, name_type);

            print_line(builder, "typedef struct");
            print_scope_open(builder);

            if (array_type->item_count_expression)
            {
                auto item_count = get_array_item_count(array_type);
                print_type(buffer, array_type->item_type, s("base["));
                print_line(builder, "%llu];", item_count);
            }
            else
            {
                print_line(builder, "usize count;");

                print_type(buffer, array_type->item_type, s("*base"));
                print_line(builder, ";");
            }

            print_scope_close(builder, false);
            if (name.count)
                print_line(builder, " %.*s;", fs(name));
            else
            {
                print(builder, " ");
                print_type(buffer, type);
                print_line(builder, ";");
            }
        } break;

        case ast_node_type_enumeration_type:
        {
            local_node_type(enumeration_type, name_type);

            print(builder, "typedef ");
            print_type(buffer, enumeration_type->item_type, name);
            print_line(builder, ";");

            auto base_type = enumeration_type->item_type.base_type.node;
            while (is_node_type(base_type, enumeration_type))
            {
                local_node_type(enumeration_type, base_type);
                base_type = enumeration_type->item_type.base_type.node;
            }

            local_node_type(number_type, base_type);

            ast_enumeration_item *last_item_with_expression = null;

            while (enumeration_type)
            {
                for (auto item = enumeration_type->first_item; item; item = (ast_enumeration_item *) item->node.next)
                {
                    print(builder, "const %.*s %.*s_%.*s = ", fs(name), fs(name), fs(item->name));

                    assert(item->expression);

                    if (!is_node_type(item->expression, number))
                    {
                        print_comment_begin(buffer);
                        print_expression(buffer, item->expression, null, false, false);
                        print_comment_end(buffer);
                    }

                    parsed_number number = {};
                    number.is_signed = number_type->is_signed;
                    number.u64_value = get_enumeration_item_value(item);
                    number.bit_count_power_of_two = number_type->bit_count_power_of_two;// get_bit_count_power_of_two(number.u64_value);


                    print_number(buffer, number);
                    print_line(builder, ";");
                }

                auto base_type = enumeration_type->item_type.base_type.node;
                if (!is_node_type(base_type, enumeration_type))
                    break;

                enumeration_type = get_node_type(enumeration_type, base_type);
            }
        } break;
    }
}

void write_expression(string_builder *builder, ast_node *expression)
{
    switch (node->node_type)
    {
        cases_complete_message("unhandled expression type %.*s", fnode_type_name(node));

        // nothing to do
        case ast_node_type_base_node:
        break;

        case ast_node_type_number:
        {
            local_node_type(number, node);
            write_number(buffer, number->value);
        } break;

        case ast_node_type_string_literal:
        {
            local_node_type(string_literal, node);
            print(builder, "\"");
            print_c_string(builder, string_literal->text, string_literal->is_raw);
            print(builder, "\"");
        } break;

        case ast_node_type_array_literal:
        {
            local_node_type(array_literal, node);

            print(builder, "[ ");

            for (auto argument = array_literal->first_argument; argument; argument = argument->next)
                write_expression(builder, argument->expression);

            print(builder, "]");
            print_type(builder, array_literal->type);
        } break;

        case ast_node_type_compound_literal:
        {
            local_node_type(compound_literal, node);
            print_compound_literal(buffer, compound_literal, expression_to_local_map, is_inside_array_literal, is_initialization);
        } break;

        case ast_node_type_name_reference:
        {
            local_node_type(name_reference, node);

            if (!name_reference->reference)
            {
                print_comment_begin(buffer);
                print(builder, "not resolved");
                print_comment_end(buffer);
            }

            if (is_node_type(name_reference->reference, function))
            {
                local_node_type(function, name_reference->reference);
                print_function_name(builder, function);
            }
            // since C may not be able to fold the constant, we just write the whole value
            else if (is_initialization && is_node_type(name_reference->reference, constant))
            {
                local_node_type(constant, name_reference->reference);

                print_comment_begin(buffer);
                print(builder, "%.*s", fs(name_reference->name));
                print_comment_end(buffer);
                print(builder, " ");

                print_expression(buffer, constant->expression, expression_to_local_map, is_inside_array_literal, true);
            }
            else
            {
                print(builder, "%.*s", fs(name_reference->name));
            }
        } break;

        case ast_node_type_function_call:
        {
            local_node_type(function_call, node);

            print_expression(buffer, function_call->expression, expression_to_local_map, is_inside_array_literal, is_initialization);
            print(builder, "(");

            bool is_not_first = false;
            for (auto argument = function_call->first_argument; argument; argument = (ast_argument *) argument->node.next)
            {
                if (is_not_first)
                    print(builder, ", ");

                print_expression(buffer, argument->expression, expression_to_local_map, is_inside_array_literal, false);
                is_not_first = true;
            }
            print(builder, ")");
        } break;

        case ast_node_type_dereference:
        {
            local_node_type(dereference, node);

            print(builder, "*");
            print_expression(buffer, dereference->expression, expression_to_local_map, is_inside_array_literal, is_initialization);
        } break;

        case ast_node_type_field_dereference:
        {
            local_node_type(field_dereference, node);

            assert(field_dereference->reference);

            auto type = get_expression_type(buffer->parser, field_dereference->expression).base_type;

            if (is_node_type(type.node, enumeration_type))
            {
                assert(!type.indirection_count);
                if (field_dereference->name == s("count"))
                {
                    local_node_type(enumeration_type, type.node);

                    print_comment_begin(buffer);

                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal, is_initialization);
                    print(builder, "_%.*s", fs(field_dereference->name));

                    print_comment_end(buffer);

                    print(builder, " %i", enumeration_type->item_count);
                }
                else
                {
                    print_comment_begin(buffer);
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal, is_initialization);
                    print(builder, "_%.*s", fs(field_dereference->name));
                    print_comment_end(buffer);

                    local_node_type(enumeration_item, field_dereference->reference);
                    print_expression(buffer, enumeration_item->expression, null, false, false);
                }
            }
            else if (is_node_type(type.node, array_type) && ((ast_array_type *) type.node)->item_count_expression)
            {
                local_node_type(array_type, type.node);

                if ((field_dereference->name == s("count")))
                {
                    print_comment_begin(buffer);
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal, false);
                    print(builder, ".");
                    print(builder, "%.*s", fs(field_dereference->name));
                    print_comment_end(buffer);

                    print_expression(buffer, array_type->item_count_expression, expression_to_local_map, is_inside_array_literal, false);
                }
                else
                {
                    // cast (const type[count]) to (type *)
                    print(builder, "(");
                    print_type(buffer, get_indirect_type(parser, array_type->item_type));
                    print(builder, ") ");
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal, false);
                    print(builder, ".base");
                }
            }
            else
            {
                if (type.indirection_count == 1)
                {
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal, is_initialization);
                    print(builder, "->");

                }
                else if (type.indirection_count == 0)
                {
                    print_expression(buffer, field_dereference->expression, expression_to_local_map, is_inside_array_literal, is_initialization);
                    print(builder, ".");
                }
                else
                {
                    print_comment_begin(buffer);
                    print(builder, "too many indirections %.*s", fs(field_dereference->name));
                    print_comment_end(buffer);
                }

                print(builder, "%.*s", fs(field_dereference->name));
            }
        } break;

        case ast_node_type_array_index:
        {
            local_node_type(array_index, node);

            auto type = get_expression_type(parser, array_index->array_expression);
            auto base_type = type.base_type.node;
            local_node_type(array_type, base_type);

            // auto derefence array pointers
            if (type.base_type.indirection_count)
            {
                print(builder, "(");

                for (u32 i = 0; i < type.base_type.indirection_count; i++)
                    print(builder, "*");

                print_expression(buffer, array_index->array_expression, expression_to_local_map, is_inside_array_literal, false);
                print(builder, ")");
            }
            else
            {
                print_expression(buffer, array_index->array_expression, expression_to_local_map, is_inside_array_literal, false);
            }

            print(builder, ".base[");
            print_expression(buffer, array_index->index_expression, expression_to_local_map, is_inside_array_literal, false);
            print(builder, "]");
        } break;

        case ast_node_type_unary_operator:
        {
            local_node_type(unary_operator, node);

            switch (unary_operator->operator_type)
            {
                case ast_unary_operator_type_cast:
                {
                    bool do_close = false;
                    // compound/union aliases don't need casting in C
                    if (unary_operator->type.base_type.indirection_count || (!is_node_type(unary_operator->type.base_type.node, compound_type) && !is_node_type(unary_operator->type.base_type.node, union_type)))
                    {
                        print(builder, "((");
                        print_type(buffer, unary_operator->type);
                        print(builder, ") ");
                        do_close = true;
                    }

                    if (unary_operator->type.name_type.indirection_count)
                    {
                        auto type = get_expression_type(parser, unary_operator->expression);

                        if (!type.name_type.indirection_count && is_node_type(type.base_type.node, number_type))
                        {
                            auto usize_type = get_node_type(number_type, parser->base_alias_types[lang_base_alias_type_usize]->type.base_type.node);

                            local_node_type(number_type, type.base_type.node);
                            if (number_type->bit_count_power_of_two < usize_type->bit_count_power_of_two)
                                print(builder, "(usize)");
                        }
                    }

                    print_expression(buffer, unary_operator->expression, expression_to_local_map, is_inside_array_literal, is_initialization);

                    if (do_close)
                        print(builder, ")");
                } break;

                default:
                {
                    if (unary_operator->function)
                    {
                        print_function_name(builder, unary_operator->function);
                        print(builder, "(", fs(ast_unary_operator_names[unary_operator->operator_type]));
                        print_expression(buffer, unary_operator->expression, expression_to_local_map, is_inside_array_literal, false);
                        print(builder, ")");
                    }
                    else
                    {
                        string c_symbols[] =
                        {
                            s("!"),
                            s("~"),
                            s("-"),
                            s("&"),
                        };

                        assert(unary_operator->operator_type < carray_count(c_symbols));

                        // we don't have const, so we may need to cast const away when taking pointers to constants
                        if (unary_operator->operator_type == ast_unary_operator_type_take_reference)
                        {
                            // cast const away
                            auto head = get_head_expression(unary_operator->expression);
                            if (is_node_type(head, constant))
                            {
                                local_node_type(constant, head);
                                print(builder, "(");
                                print_type(buffer, unary_operator->type);
                                print(builder, ") ");
                            }
                        }

                        print(builder, "%.*s", fs(c_symbols[unary_operator->operator_type]));
                        print_expression(buffer, unary_operator->expression, expression_to_local_map, is_inside_array_literal, is_initialization);
                    }
                }
            }
        } break;

        case ast_node_type_get_function_reference:
        {
            local_node_type(get_function_reference, node);
            assert(get_function_reference->function);
            print_function_name(builder, get_function_reference->function);
        } break;

        case ast_node_type_get_type_info:
        {
            local_node_type(get_type_info, node);
            print_type_info(buffer, get_type_info->type, is_initialization);
        } break;

        case ast_node_type_type_byte_count:
        {
            local_node_type(type_byte_count, node);

            auto count_and_alignment = get_type_byte_count_and_alignment(type_byte_count->type);

            print_comment_begin(buffer);

            print(builder, "type_byte_count(");
            print_type(buffer, type_byte_count->type);
            print(builder, ")");

            print_comment_end(buffer);

            print(builder, "%llu", count_and_alignment.byte_count);
        } break;

        case ast_node_type_binary_operator:
        {
            local_node_type(binary_operator, node);

            if (binary_operator->function)
            {
                print_function_name(builder, binary_operator->function);
                print(builder, "(", fs(ast_binary_operator_names[binary_operator->operator_type]));
                print_expression(buffer, binary_operator->left, expression_to_local_map, is_inside_array_literal, false);
                print(builder, ", ");
                print_expression(buffer, binary_operator->left->next, expression_to_local_map, is_inside_array_literal, false);
                print(builder, ")");
            }
            else
            {
                string c_symbols[] =
                {
                    s("||"),
                    s("&&"),
                    s("!="),

                    s("=="),
                    s("!="),

                    s("<"),
                    s("<="),
                    s(">"),
                    s(">="),

                    s("|"),
                    s("&"),
                    s("^"),
                    s("<<"),
                    s(">>"),

                    s("+"),
                    s("-"),
                    s("*"),
                    s("/"),
                    s("%"),
                };

                assert(binary_operator->operator_type < carray_count(c_symbols));

                print(builder, "(");
                print_expression(buffer, binary_operator->left, expression_to_local_map, is_inside_array_literal, is_initialization);
                print(builder, " %.*s ", fs(c_symbols[binary_operator->operator_type]));
                print_expression(buffer, binary_operator->left->next, expression_to_local_map, is_inside_array_literal, is_initialization);
                print(builder, ")");
            }
        } break;
    }
}

void lang_patch_operator_precedence(lang_parser *parser)
{
    for_bucket_item(bucket, index, parser->binary_operator_buckets)
    {
        auto binary_operator = &bucket->base[index];
        if (binary_operator->parent && is_node_type(parent, unary_operator) | binary_operator))
    }
}