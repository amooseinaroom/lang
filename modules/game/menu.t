import platform;
import math;

struct menu_stack_entry
{
    name              string;
    state             u32;
    fade_out_duration seconds_f32;
}

enum menu_transition_phase u32
{
    inactive = -1 cast(u32);
    fade_in;
    active;
    fade_out;
}

type menu_value union 
{
    index  u32;
    timeout f32;
};

struct menu_stack
{
    active_stack                  menu_stack_entry[32];
    active_value_stack            menu_value[32];
    active_depth                  u32;
    
    frame_state_stack u32[32];
    frame_depth       u32;
    
    transition struct
    {
        next_active_name  string;
        next_active_state u32;
        next_active_depth u32;
        
        timeout           seconds_f32;
        duration          seconds_f32;
        phase             menu_transition_phase;
        phase_changed     b8;
    };
}

func menu_frame(menu menu_stack ref, delta_time seconds_f32)
{
    menu.frame_depth = 0;
    menu.frame_state_stack[0] = 0;
    
    var transition = menu.transition ref;
    transition.phase_changed = false;
    
    // activate what ever the first state is
    if not menu.active_depth
    {
        menu.active_depth = 1;
        menu.active_stack[0].state = 0;
        transition.phase = menu_transition_phase.fade_in;
        transition.phase_changed = true;
    }
    else if transition.timeout > 0 // or (transition.phase is_not menu_transition_phase.active)
    {
        transition.timeout -= delta_time;
        
        if transition.timeout <= 0
        {
            if transition.phase is menu_transition_phase.fade_out
            {
                assert(transition.next_active_depth <= (menu.active_depth + 1));
                menu.active_depth = transition.next_active_depth;
                menu.active_stack[menu.active_depth - 1].state = transition.next_active_state;
                menu.active_stack[menu.active_depth - 1].name  = transition.next_active_name;
                
                transition.phase = menu_transition_phase.fade_in;
            }
            else
            {
                // auto transition is active
                if transition.phase is menu_transition_phase.active
                    menu.transition.timeout += menu.active_stack[menu.active_depth - 1].fade_out_duration;
            
                transition.phase += 1;
            }
            
            transition.phase_changed = true;
        }
    }
}

func is_on_active_path(menu menu_stack ref) (on_active_path b8)
{
    assert(menu.active_depth >= menu.frame_depth);
    loop var i; menu.frame_depth
    {
        if menu.active_stack[i].state is_not menu.frame_state_stack[i]
            return false;
    }
    
    return true;
}

func state_begin(menu menu_stack ref, name = {} string, fade_in_duration = 0.25, fade_out_duration = 0.25) (on_active_path b8)
{
    var on_active_path =
        ((menu.frame_depth + 1) <= menu.active_depth) and
        is_on_active_path(menu) and
        ((menu.active_stack[menu.frame_depth].state is menu.frame_state_stack[menu.frame_depth]) or ((menu.active_stack[menu.frame_depth].state is -1 cast(u32)) and (menu.active_stack[menu.frame_depth].name is name)));
    
    if on_active_path
    {
        menu.active_stack[menu.frame_depth].state             = menu.frame_state_stack[menu.frame_depth];
        menu.active_stack[menu.frame_depth].name              = name;
        menu.active_stack[menu.frame_depth].fade_out_duration = fade_out_duration;
        menu.frame_depth += 1;
        
        // reset children stack
        menu.frame_state_stack[menu.frame_depth] = 0;
        
        if menu.active_depth is menu.frame_depth
        {
            if menu.transition.phase_changed and (menu.transition.phase is menu_transition_phase.fade_in)
            {
                menu.transition.duration = fade_in_duration;
                menu.transition.timeout += menu.transition.duration;
            }
            
        }
    }
    else
    {
        // advance sibling id
        menu.frame_state_stack[menu.frame_depth] += 1;
    }

    return on_active_path;
}

func get_child_state_count(menu menu_stack ref)
{
    assert(is_active(menu));
    return menu.frame_state_stack[menu.frame_depth];
}

func state_end(menu menu_stack ref)
{
    assert(is_on_active_path(menu));
    assert(menu.frame_depth);
    
    menu.frame_depth -= 1;
    
    // advance sibling id
    menu.frame_state_stack[menu.frame_depth] += 1;
}

// too many special cases for leafs
multiline_comment {
func state_leaf(menu menu_stack ref) (on_active_path b8)
{
    var on_active_path = state_begin(menu);
    if on_active_path
        state_end(menu);
    
    return on_active_path;
}
}

// don't use in state_leaf, they are always active
func is_active(menu menu_stack ref) (ok b8)
{
    assert(is_on_active_path(menu));
    return (menu.active_depth is menu.frame_depth) and (menu.transition.phase is menu_transition_phase.active);
}

func active_state_value(menu menu_stack ref) (value menu_value ref)
{
    assert(is_active(menu));
    return menu.active_value_stack[menu.active_depth - 1] ref;
}

func state_value(menu menu_stack ref) (value menu_value)
{
    assert(is_on_active_path(menu));
    return menu.active_value_stack[menu.frame_depth - 1];
}

func state_activation_ratio(menu menu_stack ref) (ratio f32)
{
    assert(is_on_active_path(menu));
    
    var transition_progress = 1.0;
    if menu.transition.duration > 0
        transition_progress = maximum(0, menu.transition.timeout / menu.transition.duration);
    
    if menu.transition.phase is menu_transition_phase.fade_out
         return transition_progress;
    else if menu.active_depth is menu.frame_depth
    {
        switch menu.transition.phase
        case menu_transition_phase.fade_in
            return 1 - transition_progress;
        case menu_transition_phase.active
            return 1;
    }

    return 1.0;
}

func transit_to(menu menu_stack ref, depth u32, state = -1 cast(u32), name = {} string)
{
    assert(is_active(menu));
    assert(depth and (depth <= menu.active_depth));
    assert((state is_not -1 cast(u32)) xor (name.count));
    
    menu.transition.next_active_state = state;
    menu.transition.next_active_name  = name;
    menu.transition.next_active_depth = depth;
    menu.transition.phase             = menu_transition_phase.fade_out;
    menu.transition.duration          = menu.active_stack[menu.active_depth - 1].fade_out_duration;
    menu.transition.timeout           += menu.transition.duration;
}

// assuming child will be called later in this frame
func transit_to_child(menu menu_stack ref, state = -1 cast(u32), name = {} string)
{
    assert(is_active(menu));
    assert((state is_not -1 cast(u32)) xor (name.count));
    
    menu.active_stack[menu.active_depth].state = state;
    menu.active_stack[menu.active_depth].name  = name;
    menu.active_depth += 1;
    menu.transition.timeout = 0.0;
    menu.transition.phase_changed = true;
    menu.transition.phase = menu_transition_phase.fade_in;
}

// assuming child was called before this call
func transit_to_preceding_child(menu menu_stack ref, child_index u32)
{
    assert(is_active(menu));
    
    var child_count = get_child_state_count(menu);
    assert(child_index < child_count);
    
    menu.active_stack[menu.active_depth].state = state;
    menu.active_stack[menu.active_depth].name  = name;
    menu.active_depth += 1;
    menu.transition.timeout = 0.0;
    menu.transition.phase_changed = true;
    menu.transition.phase = menu_transition_phase.fade_in;
}


func transit_to_parent(menu menu_stack ref, state = -1 cast(u32), name = {} string)
{
    transit_to(menu, menu.active_depth - 1, state, name);
}

func transit_to_sibling(menu menu_stack ref, state = -1 cast(u32), name = {} string)
{
    transit_to(menu, menu.active_depth, state, name);
}

func auto_transit_to(menu menu_stack ref, duration f32, depth_decrease u32, state = -1 cast(u32), name = {} string)
 {
    // only when we enter active state
    if is_active(menu) and menu.transition.phase_changed
    {
        assert(depth_decrease <= menu.active_depth);
        assert((state is_not -1 cast(u32)) xor (name.count));
        
        menu.transition.next_active_state = state;
        menu.transition.next_active_name  = name;
        menu.transition.next_active_depth = menu.active_depth - depth_decrease;
        menu.transition.duration          = duration;
        menu.transition.timeout           += menu.transition.duration;
    }
}

//func auto_transit_to_child(menu menu_stack ref, timeout f32, state = -1 cast(u32), name = {} string)
//{
//    auto_transit_to(menu, timeout, 1, state, name);
//}

func auto_transit_to_sibling(menu menu_stack ref, duration f32, state = -1 cast(u32), name = {} string)
{
    auto_transit_to(menu, duration, 0, state, name);
}

func auto_transit_to_parent(menu menu_stack ref, timeout f32)
{
    auto_transit_to(menu, timeout, 1, menu.active_stack[menu.active_depth - 2].state);
}

multiline_comment {

func menu_function(platform platform_api ref, state program_state ref, delta_seconds seconds_f32, menu menu_stack ref) (continue_game b8);

func menu_main menu_function
{
    var ui = state.ui ref;
    var font = state.font;
    var big_font = state.big_font;
    var animation_seconds = state.animation_seconds;
    var random = state.random ref;    

    if platform_key_was_pressed(platform, platform_key.escape)
    {
        menu deref = {} menu_stack;
        return true;
    }

    if state_begin(menu, "boot", 1.0, 0.5)
    {
        auto_transit_to_sibling(menu, 1, "title");
        
        draw_title(state, 0, 0, 0);
        
        var active_ratio = state_activation_ratio(menu);
        var color = to_rgba8(lerp(color_black, color_white, active_ratio));
        var texture_scale = ui.width * 0.2 / state.fmod_logo.width;
        draw_texture(ui, state.fmod_logo, ui.viewport_size.width - 32, 32, v2(1, 0), v2(texture_scale), color, layer_id.background + 1);
    
        state_end(menu);
    }
    
    if state_begin(menu, "title", 1.0, 0.5)
    {
        var active_ratio = state_activation_ratio(menu);
        
        var options_activation f32;
        
        if is_active(menu)
        {
            var color = blend(color_black, sin(tau32 * animation_seconds * 0.5) * 0.5 + 0.5);
            print_aligned(ui, font, scale(ui.viewport_size, v2(0.5, 0.333)), color, "press Enter or A on Gamepad");
            if platform_button_was_pressed(input.accept)
                transit_to_child(menu, "options");
        }
        
        if state_begin(menu, "options", 0.5, 0.5)
        {
            options_activation = state_activation_ratio(menu);
            state.ui_alpha = options_activation;
            
            var options =
            [
                "New Game",
                "Load Game",
                "Settings",
                "Quit"
            ] string[];
            
            if is_active(menu)
            {
                var index = active_state_value(menu).index ref;
                
                if update_option_index_up_down(input, index, options.count)
                {
                    switch index deref
                    case 0
                    {
                        start_new_game(platform, state);
                        transit_to(menu, 1, "draft");
                    }
                    
                    case 3
                        return false;
                }
            }
            
            var index = state_value(menu).index;
            
            var cursor = draw_center_menu_box(state, box_style.idle, 0, 3);
            print_options(state, cursor ref, options, index);
        
            state_end(menu);
        }
        
        draw_title(state, active_ratio, active_ratio, options_activation);
        
        state_end(menu);
    }

    return true;
}

func menu_status menu_function
{
    var party = state.party ref;
    
    // if parent is active, we can toggle into this
    if is_active(menu)
    {
        if platform_button_was_pressed(input.cancel)
        {
            transit_to_child(menu, "status");
        }
    }
    
    if state_begin(menu, "status", 0.5, 0.5)
    {
        var options =
        [
            "Party",
            "Equipment",
            //"Save",
            //"Load",
        ] string[];
        
        if is_active(menu) 
        {
            var index = active_state_value(menu).index ref;
            
            if platform_button_was_pressed(input.cancel)
                transit_to_parent(menu);
            else if update_option_index_up_down(input, index, options.count)
                transit_to_child(menu, index deref);
        }
        
        var index = state_value(menu).index;
        
        var cursor = draw_center_menu_box(state, box_style.idle, 0, 3);
        print(state, cursor ref, "Menu\n");
        print_options(state, cursor ref, options, index);
        
        draw_party(state, -1 cast(u32));
    
        multiline_comment {
        if state_begin(menu)
        {
            var unit_names string[4];
            loop var i; party.unit_count
                unit_names[i] = party.units[i].name;
            
            if is_active(menu)
            {
                var party_unit_index = active_state_value(menu);
                
                if platform_button_was_pressed(input.cancel)
                    transit_to_parent(menu);
                else
                    update_option_index_up_down(input, party_unit_index, party.unit_count);
            }
        
            var party_unit_index = state_value(menu);
        
            {
                var cursor = draw_center_menu_box(state, box_style.idle, 1, 3);
                print(state, cursor ref, "Party\n");
                print_options(state, cursor ref, { party.unit_count, unit_names.base } string[], party_unit_index);
            }
            
            {
                var cursor = draw_center_menu_box(state, box_style.idle, 2, 3);
                
                var unit = party.units[party_unit_index];
                
                var color = to_rgba8(text_color_idle);
                print(state, cursor ref, "%\n\n", unit.name);
                print(state, cursor ref, "Health:  %/%\n", format_value(unit.health, 3, " "[0]), unit.max_health);
                print(state, cursor ref, "Attack:  % (%+%)\n", format_value(unit.attack, 3, " "[0]), unit.attack, 0);
                print(state, cursor ref, "Defense: % (%+%)\n", format_value(unit.defense, 3, " "[0]), unit.defense, 0);
            }
            
            state_end(menu);
        }
        
        if state_begin(menu, "use item")
        {
            var unit_names string[4];
            loop var i; party.unit_count
                unit_names[i] = party.units[i].name;
            
            var item_index u32 = 0;
            var party_unit_index = -1 cast(u32);
            
            if is_active(menu)
            {
                var item_index = active_state_value(menu).index ref;
                
                if platform_button_was_pressed(input.cancel)
                    pop_active_state(menu);
                else if update_option_index_up_down(input, item_index, party.items.available_id_count)
                {
                    var item = party.items.available_ids[item_index deref];
                    if item <= item_id.sword
                    {
                       transit_to_child(menu, "use item");
                    }
                    else
                    {
                        transit_to_child(menu, "equip item");
                    }
                }
            }
                
            item_index = state_value(menu);
                
            if state_begin(menu)
            {
                if is_active(menu)
                {
                    var party_unit_index = active_state_value(menu);
                    
                    if update_option_index_left_right(input, party_unit_index, party.unit_count)
                    {
                    }
                }
                
                party_unit_index = state_value(menu);
                
                state_end(menu);
            }
            
            if state_begin(menu)            
            {
                if is_active(menu)
                {
                    var party_unit_index = active_state_value(menu);
                
                    if update_option_index_left_right(input, party_unit_index, party.unit_count)
                    {
                    }
                }
                
                party_unit_index = state_value(menu);
                
                state_end(menu);
            }
                
            {
                var cursor = draw_center_menu_box(state, box_style.idle, 1, 3);
                print(state, cursor ref, "Equipment\n");
                
                loop var i u32; party.items.available_id_count
                {
                    var item = party.items.available_ids[i];
                    var name = item_names[item];
                    print_option(state, cursor ref, i, item_index, "% x%", pad_right(name, max_item_name_count), party.items.count_by_id[item]);
                }
            }
            
            {
                var cursor = draw_center_menu_box(state, box_style.idle, 2, 3);
                
                var item = party.items.available_ids[item_index];
                
                var color = to_rgba8(text_color_idle);
                print(state, cursor ref, "%\n\n", item_names[item]);
                print(state, cursor ref, "%\n", item_descriptions[item]);
            }
            
            state_end(menu);
        }
        }
    
        state_end(menu);
    }
    
    return true;
}

func menu_dungeon menu_function
{
    var memory = state.memory ref;
    var tmemory = state.tmemory ref;
    var gl = state.gl ref;
    var render = state.render ref;
    var ui = state.ui ref;
    var window = state.window ref;
    var font = state.font;
    var random = state.random ref;
    var animation_seconds = state.animation_seconds;
    var party     = state.party ref;
    var encounter = state.encounter ref;
    
    var timeout_trigger = false;
    if party.transition_timeout > 0
    {
        party.transition_timeout -= delta_seconds * 2;
        
        if party.transition_timeout <= 0
        {
            timeout_trigger = true;
            party.transition_timeout = 0;
        }
    }
    
    switch party.state
    case dungeon_state_id.exploring
    {
        if status_menu(state, input)
        {
        }
        else
        {
            if platform_button_was_pressed(input.pause)
                party.state = dungeon_state_id.menu;
        
            if timeout_trigger
            {
                party.position = party.target_position;
                party.direction = party.target_direction;
                
                var rotation = mat4_transform(v3(0, 0, 1), 2 * pi32 * party.direction / face_direction.count);
                var front_position = party.position + vec2_cut(transform(rotation, v3(0, 1, 0)));
                
                if (state.map[front_position.y * state.map_width + front_position.x] is_not 1) and (random_index(random, 10) is 0)
                    random_encounter(state);
            }
            
             if party.transition_timeout is 0
            {
                var move = input.up.is_active cast(s32) - input.down.is_active cast(s32);
                if move is_not 0
                {
                    var rotation = mat4_transform(v3(0, 0, 1), 2 * pi32 * party.direction / face_direction.count);
                    party.target_position = party.position + vec2_cut(transform(rotation, v3(0, move, 0)));
                    
                    if state.map[party.target_position.y * state.map_width +party.target_position.x] is_not 1
                        party.transition_timeout = 1;
                    else
                        party.target_position = party.position;
                        
                }
                else
                {
                    var rotate = input.right.is_active cast(s32) - input.left.is_active cast(s32);
                    if rotate is_not 0
                    {
                        party.target_direction = ((party.direction - rotate + face_direction.count) mod face_direction.count);
                        party.transition_timeout = 1;
                    }
                }
            }
        }
    }
    case dungeon_state_id.battle
    {
        var alpha = 1 - party.transition_timeout;
        
        var box_width = (ui.viewport_size.width / party.units.count) - ui_border_margin;
        
        var timeout_was_triggered = false;
        
        if encounter.message_index < encounter.message_count
        {
            encounter.message_timeout -= delta_seconds;
            
            while encounter.message_timeout <= 0
            {
                encounter.message_index += 1;
                if encounter.message_index >= encounter.message_count
                {
                    encounter.message_index = 0;
                    encounter.message_count = 0;
                    encounter.message_timeout = 0;
                    break;
                }
                
                encounter.message_timeout += 1.0;
            }
        }
        
        if not encounter.message_count and (encounter.timeout > 0)
        {
            encounter.timeout -= delta_seconds;
            if encounter.timeout <= 0
                timeout_was_triggered = true;
        }
        
        {
            def actions = [
                "Attack",
                "Defend",
                "Use Item",
                "Run"
            ] string[];
            
            var available_action_count = actions.count;
            var select_to_action_map = [ 0, 1, 2, 3 ] u32[];
            var action_is_available = [ true, true, true, true ] b8[];
            assert(actions.count is action_id.count);
            
            {
                var run_position = party.position + get_world_direction(party deref, v2(0, -1));
                if state.map[run_position.y * state.map_width +run_position.x] is 1
                {
                    action_is_available[action_id.run] = false;
                    available_action_count -= 1;
                }
            }
            
            var available_party_units = get_available_units(party.units);
            var party_unit_index = -1 cast(u32);
            
            var available_enemy_units = get_available_units(encounter.enemies);
            var enemy_unit_index = -1 cast(u32);
            
            var selected_action = select_to_action_map[encounter.selected_action_item];
            
            if not encounter.message_count
            {
                switch encounter.battle_state
                case dungeon_battle_state_id.select_action
                {
                    if update_option_index_up_down(input, encounter.selected_action_item ref, available_action_count)
                        encounter.battle_state += 1;
                }
                case dungeon_battle_state_id.select_target
                {
                    var do_advance = false;
                    
                    switch selected_action
                    case action_id.attack
                    {
                        if update_option_index_left_right(input, encounter.target_index ref, available_enemy_units.count)
                        {
                            var enemy_index = available_enemy_units.indices[encounter.target_index];
                            
                            var action = encounter.actions[encounter.action_count] ref;
                            encounter.action_count += 1;
                            
                            action.unit = encounter.party_unit_index;
                            action.is_enemy = false;
                            action.attack.target = enemy_index;
                            action.attack.target_is_enemy = true;
                            action.action = selected_action;
                            action.attack.base_damage = 10;
                            
                            do_advance = true;
                        }
                        
                        enemy_unit_index = available_enemy_units.indices[encounter.target_index];
                    }
                    case action_id.use_item
                    {
                        var slots item_id[item_id.count];
                        var slot_count u32;
                        
                        loop var i u32; item_id.count
                        {
                            if party.items.count_by_id[i]
                            {
                                slots[slot_count] = i;
                                slot_count += 1;
                            }
                        }
                        
                        if update_option_index_up_down(input, encounter.target_index ref, slot_count)
                        {
                            var item = slots[encounter.target_index];
                            assert(party.items.count_by_id[item]);
                            party.items.count_by_id[item] -= 1;
                        
                            var action = encounter.actions[encounter.action_count] ref;
                            encounter.action_count += 1;
                            
                            action.unit = encounter.party_unit_index;
                            action.is_enemy = false;
                            action.item = item;
                            action.action = selected_action;
                            
                            do_advance = true;
                        }
                    }
                    else
                    {
                        var action = encounter.actions[encounter.action_count] ref;
                        encounter.action_count += 1;
                            
                        action.unit = encounter.party_unit_index;
                        action.is_enemy = false;
                        action.action = selected_action;
                        
                        do_advance = true;
                    }
                    
                    if do_advance
                    {
                        encounter.party_unit_index += 1;
                        if encounter.party_unit_index >= party.unit_count
                        {
                            encounter.battle_state = dungeon_battle_state_id.execute;
                            
                            loop var i u32; encounter.enemy_count
                            {
                                var action = encounter.actions[encounter.action_count] ref;
                                encounter.action_count += 1;
                                
                                action.action = action_id.attack;
                                action.unit = i;
                                action.is_enemy = true;
                                action.attack.target = random_index(random, party.unit_count);
                                action.attack.target_is_enemy = false;
                                action.attack.base_damage = 20;
                            }
                            
                            encounter.timeout = 1;
                            encounter.execute_action_index = 0;
                        }
                        else
                        {
                            encounter.battle_state = dungeon_battle_state_id.select_action;
                        }
                    }
                }
                case dungeon_battle_state_id.execute
                {
                    var do_action = timeout_was_triggered;
                    while do_action
                    {
                        var unit unit_entity ref;
                        var action = encounter.actions[encounter.execute_action_index];
                        if action.is_enemy
                            unit = encounter.enemies[action.unit] ref;
                        else
                            unit = party.units[action.unit] ref;
                            
                        if unit.health > 0
                            break;
                            
                        do_action and= next_action(state);
                    }
                
                    if do_action
                    {
                        var unit unit_entity ref;
                        var action = encounter.actions[encounter.execute_action_index];
                        
                        if action.is_enemy
                            unit = encounter.enemies[action.unit] ref;
                        else
                            unit = party.units[action.unit] ref;
                        
                        var target unit_entity ref;
                        if action.attack.target_is_enemy
                            target = encounter.enemies[action.attack.target] ref;
                        else
                            target = party.units[action.attack.target] ref;
                        
                        if target.health is 0
                        {
                            push_encounter_message(state, "% can't attack %. % was alreay defeated.", unit.name, target.name, target.name);
                        }
                        else
                        {
                            switch action.action
                            case action_id.attack
                            {
                                var base_damage = action.attack.base_damage;
                                var damage = unit.attack * base_damage / (unit.attack + target.defense);
                                var remainder = (unit.attack * base_damage) mod (unit.attack + target.defense);
                                if remainder
                                    damage += 1;
                                
                                target.health = maximum(0, target.health - damage);
                                
                                if action.attack.target_is_enemy
                                {
                                    var animation = state.enemy_animations[action.attack.target] ref;
                                    
                                    if target.health > 0
                                        animation.id = animation_state_id.hurting;
                                    else
                                        animation.id = animation_state_id.dying;
                                        
                                    animation.duration = 1.0;
                                    animation.timeout += animation.duration;
                                }
                            }
                            case action_id.run
                            {
                                var count = get_alive_enemy_count(encounter deref);
                                if random_index(random, 1 bit_shift_left count) is 0
                                {
                                    encounter.battle_state   = dungeon_battle_state_id.escaped;
                                    encounter.timeout = 1;
                                    
                                    push_encounter_message(state, "You escaped savely.");
                                    break;
                                }
                                else
                                {
                                    push_encounter_message(state, "You couldn't escape!");
                                }
                            }
                        }
                        
                        // after action, so we can check if battle is over
                        next_action(state);
                    }
                }
                case dungeon_battle_state_id.victory
                {
                    // fade out
                    alpha = encounter.timeout;
                
                    if timeout_was_triggered
                    {
                        party.state = dungeon_state_id.exploring;
                    }
                }
                case dungeon_battle_state_id.defeat
                {
                    if not is_transitioning(state.menu ref)
                        transit_to(state.menu ref, menu_state_id.title);
                }
                case dungeon_battle_state_id.escaped
                {
                    // fade out
                    alpha = encounter.timeout;
                
                    if timeout_was_triggered
                    {
                        party.state = dungeon_state_id.exploring;
                        party.target_position    = party.position + get_world_direction(party deref, v2(0, -1));
                        party.transition_timeout = 1;
                    }
                }
            }
            
            if encounter.message_index < encounter.message_count
            {
                var box = box2_size(v2(ui_border_margin, ui_border_margin), v2(ui.viewport_size.width - (ui_border_margin * 2), ui.viewport_size.height * 0.2));
            
                draw_rounded_box(ui, box, state.box_corner_radius, blend(box_color_idle, alpha));
                var cursor = cursor_below_position(font.info, box.min.x + 10, box.max.y - 10);
                
                print(ui, font, cursor ref, blend(text_color_idle, alpha), "%", encounter.messages[encounter.message_index]);
            }
            else 
            {
                if encounter.battle_state < dungeon_battle_state_id.execute
                {
                    var box = box2_size(v2(ui_border_margin, (ui_border_margin * 2) + (ui.viewport_size.height * 0.2)), v2(box_width * 0.75, ui.viewport_size.height * 0.5 - (ui_border_margin * 2)));
                    
                    draw_rounded_box(ui, box, state.box_corner_radius, blend(box_color_idle, alpha));
                    var cursor = cursor_below_position(font.info, box.min.x + 10, box.max.y - 10);
                    
                    print(ui, font, cursor ref, blend(text_color_idle, alpha), "Action:\n");
                    
                    loop var i; actions.count
                    {
                        var color = blend(text_color_idle, alpha);
                        if not action_is_available[i]
                            color = blend(text_color_locked, alpha);
                            
                        if encounter.selected_action_item is i
                            print(ui, font, cursor ref, color, "> %\n", actions[i]);
                        else
                            print(ui, font, cursor ref, color, "  %\n", actions[i]);
                    }
                    
                    if encounter.battle_state is dungeon_battle_state_id.select_target
                    {
                        switch selected_action
                        case action_id.use_item
                        {
                            var slots item_id[item_id.count];
                            var slot_count u32;
                            
                            loop var i u32; item_id.count
                            {
                                if party.items.count_by_id[i]
                                {
                                    slots[slot_count] = i;
                                    slot_count += 1;
                                }
                            }
                            
                            var box = box2_size(v2(ui_border_margin + box_width * 0.75, (ui_border_margin * 2) + (ui.viewport_size.height * 0.2)), v2(box_width * 0.75, ui.viewport_size.height * 0.5 - (ui_border_margin * 2)));
                            
                            draw_item_box(state, party.items, encounter.target_index, "Items", blend(text_color_idle, alpha), box, blend(box_color_idle, alpha), layer_id.hud0_back);
                        }
                    }
                }
            }
            
            loop var i; encounter.enemy_count
            {
                var unit = encounter.enemies[i];
                var x = layout_x(ui_border_margin, ui.viewport_size.width - ui_border_margin - box_width, i, encounter.enemy_count, encounter.enemies.count);
                var box = box2_size(v2(x, ui.viewport_size.height - ui_border_margin - (ui.viewport_size.height * 0.2)), v2(box_width, ui.viewport_size.height * 0.2));
                
                var color = blend(box_color_idle, alpha);
                if (selected_action is action_id.attack) and (enemy_unit_index is i)
                    color = blend(box_color_enemy_unit_select, alpha);
                
                draw_rounded_box(ui, box, state.box_corner_radius, color);
                
                var cursor = cursor_below_position(font.info, box.min.x + 10, box.max.y - 10);
                print(ui, font, cursor ref, blend(text_color_idle, alpha), "%\n  hp: %/%", unit.name,
                    format_value(unit.health,     3, " "[0]),
                    format_value(unit.max_health, 3, " "[0]));
            }
            
        }
    }
    
    var party_to_world = get_party_to_world(party deref);
    
    {
        var light = render.lighting.lights[0] ref;
        light.world_position_or_direction = transform(party_to_world, v3(0, 0.45, 0.25));
        light.is_point_light              = 1.0;
        light.color                       = [ 10, 10, 10 ] vec3;
        light.attenuation                 = 3;
    }
        
    // camery looks into xy plane, z is up
    var camera_height = 0.25;
    //var camera_to_world = mat4_camera_to_world_look_at([ 0, -0.5, camera_height ] vec3, [ 0, 1, camera_height ] vec3, [ 0, 0, 1 ] vec3);
    
    var camera_to_world = party_to_world * mat4_transform(v3(1, 0, 0), pi32 * 0.5, v3(0, -0.5, camera_height));
    //camera_to_world.forward.xyz = -camera_to_world.forward.xyz;
    //camera_to_world.translation.xyz += transform(camera_to_world, v3(0, 0.5, camera_height));
    var world_to_clip = render.camera_to_clip * mat4_inverse_transform_unscaled(camera_to_world);
    render.world_to_clip = world_to_clip;
    render.camera_to_world = camera_to_world;
    
    var cursor = cursor_below_position(font.info, 10, ui.viewport_size.height - 10);
    //print(ui, font, cursor ref, rgba8_white, "hello\ncam:\n%\n%\n%\n%\n", camera_to_world[0], camera_to_world[1], camera_to_world[2], camera_to_world[3]);
    
    //push_box(render, [ 0, 0, 5 ] vec3, [ 1, 1, 1 ] vec3, [ 0.5, 0.5, 0 ] vec3, [ 1, 1, 0, 1 ] vec4);
    var global t f32;
    t += delta_seconds * 0.1;
    push_flat_box(render, v3(0, 3, 0), quat_axis_angle(v3(1, 0, 0), 2 * pi32 * t), v3(1), v3(0.5, 0.5, 0), [ 1, 1, 0, 1 ] vec4);
    
    switch party.state
    case dungeon_state_id.battle
    {
        loop var i; encounter.enemy_count
        {
            var size = 0.15; 
            
            var unit = encounter.enemies[i];
            var animation = state.enemy_animations[i] ref;
            
            var animation_ratio f32;
            if animation.timeout > 0
            {
                animation.timeout -= delta_seconds;
                if animation.timeout <= 0
                {
                    animation.id = animation_state_id.idle;
                    animation.timeout = 0;
                }
                else
                {
                    animation_ratio = 1 - (animation.timeout / animation.duration);
                }
            }
            
            if unit.health is 0 and (animation.id is_not animation_state_id.dying)
                continue;
                
            var x = layout_ratio(i, encounter.enemy_count, encounter.enemies.count);
            
            var local mat_transform;
            var color vec4;
            var scale vec3;
            
            switch unit.id
            case unit_id.slime
            {
                local = mat4_transform(v3(0, 0, 1), lerp(1, -1, x) * 0.15 * pi32, v3(lerp(size - 1 * 0.5, 1 - size * 0.5, x), 1,  0));
                color = [ 0.2, 1.0, 0.2, 1.0 ] vec4;
                scale  = v3(size, size, size);
            }
            case unit_id.winged_eye
            {
                local = mat4_transform(v3(0, 0, 1), lerp(1, -1, x) * 0.15 * pi32, v3(lerp(size - 1 * 0.5, 1 - size * 0.5, x), 1, sin(animation_seconds * tau32) * 0.05 + 0.25));
                color = [ 0.2, 0.2, 1.0, 1.0 ] vec4;
                scale  = v3(size, size, size);
            }
            
            switch animation.id
            case animation_state_id.fade_in
            {
                color.alpha = animation_ratio;
            }
            case animation_state_id.fade_out
            {
                color.alpha = 1 - animation_ratio;
            }
            case animation_state_id.hurting
            {
                color = lerp([ 1, 1, 1, 1 ] vec4, color, animation_ratio);
            }
            case animation_state_id.dying
            {
                color.alpha = 1 - animation_ratio;
            }
            
            var enemy_to_world = party_to_world * local;
            push_flat_box(render, enemy_to_world, scale, v3(0.5, 0.5, 0), color);
        }
    }

    // render map
    {
        var colors = 
        [
            [ 0.4, 0.4, 0.4, 1 ] vec4,
            [ 0.2, 0.2, 0.2, 1 ] vec4,
        ] vec4[];
    
        var size = v3(1, 1, 9.0 / 16.0);
        loop var y = maximum(0, party.position.y cast(s32) - 10); minimum(state.map.count cast(s32), party.position.y cast(s32) + 10)
        {
            loop var x = maximum(0, party.position.x cast(s32) - 10); minimum(state.map[0].count cast(s32), party.position.x cast(s32) + 10)
            {
                var tile = state.map[y * state.map_width + x];
                if (tile is tile_id.wall) or (tile is tile_id.secret_passage)
                {
                    push_flat_box(render, scale(v3(x, y, 0), size), size, [ 0.5, 0.5, 0 ] vec3, colors[(x + y) bit_and 1]);
                }
                else
                {
                    push_flat_box(render, scale(v3(x, y, -1), size), size, [ 0.5, 0.5, 0 ] vec3, colors[(x + y + 1) bit_and 1]);
                    push_flat_box(render, scale(v3(x, y,  1), size), size, [ 0.5, 0.5, 0 ] vec3, colors[(x + y + 1) bit_and 1]);
                }
            }
        }
    }
    
    return true;
}
}

def fart = -12;