
import platform;
import memory;
import random;
import math;
import ui;
import font;
import string;
import gl;

var platform platform_api;
platform_init(platform ref);
platform_enable_console(platform ref);

var memory memory_arena;
init(memory ref);

var tmemory memory_arena;
init(tmemory ref);

var renderer render_api;
init(renderer ref, platform ref, tmemory ref);

var _ui ui_system;
var ui = _ui ref;
init(ui, platform ref, renderer.gl ref);

var font ui_font;
init(font ref, platform ref, memory ref, tmemory ref, "C:/windows/fonts/consola.ttf", 24);

enum piece_type u32
{
    empty;
    o;
    i;
    t;
    l;
    j;
    z;
    s;
}

struct falling_piece
{
    center_times_2 vec2s;
    bricks         vec2s[4];
    type           piece_type;
}

def piece_type_colors =
[
    {} rgba8,
    [ 255, 255,   0, 255 ] rgba8,
    [ 100, 100, 255, 255 ] rgba8,
    [ 255,   0, 255, 255 ] rgba8,
    [ 255, 100,   0, 255 ] rgba8,
    [   0,   0, 255, 255 ] rgba8,
    [ 255,   0,   0, 255 ] rgba8,
    [   0, 255,   0, 255 ] rgba8
] rgba8[piece_type.count];

def frame_color = [ 80, 80, 80, 255 ] rgba8;

// or [24][10]piece_type ?
type board_type piece_type[10][24];

enum game_state u32
{
    title;
    running;
    clearing_rows;
    game_over;
}

struct game_type
{
    board                   board_type;
    piece                   falling_piece;
    next_piece              falling_piece;
    random                  random_pcg;
    tick_timeout            f32;
    prevent_falling_timeout f32;
    state                   game_state;
    in_fast_fall            b8
}

func next_piece(game game_type ref)
{
    game.state = game_state.running;
    game.piece = game.next_piece;
    game.next_piece = make_random_piece(game.random ref, game.board[0].count, game.board.count);
    game.in_fast_fall = false;
    game.tick_timeout = 1.0;
    game.prevent_falling_timeout = 0.0;
}

platform_update_time(platform ref); // skip startup time

var game game_type;
game.random = platform_get_random_from_time(platform ref);
game.next_piece = make_random_piece(game.random ref, game.board[0].count, game.board.count);
next_piece(game ref);

// TEMP export piece info
loop var type = piece_type.empty + 1; piece_type.count
{
    var piece = make_piece(type, 10, 24);
    print("\n% % %", type, piece.center_times_2.x * 0.5, piece.center_times_2.x * 0.5);
}

var jiggle_time f32;

while platform_handle_messages(platform ref)
{
    var delta_seconds = platform.delta_seconds;

    var window = renderer.window ref;

    if platform.do_quit or window.do_close
        break;

    platform_window_frame(platform ref, window);

    ui_frame(ui, delta_seconds);
    ui_window(ui, platform ref, window);

    {
        var cursor font_cursor;
        cursor.x = 100;
        cursor.y = 400;
        cursor.line_x = cursor.x;
        print(ui, font, cursor ref, "fps: %\n", 1 / delta_seconds);
        //print(ui, font, cursor ref, "world_to_clip: %\n", renderer.camera_to_clip * renderer.world_to_camera);
    }

    var previous_state game_state = game.state + 1;
    while previous_state is_not game.state
    {
        previous_state = game.state;

        switch game.state
        case game_state.game_over
        {
            game.tick_timeout = game.tick_timeout + delta_seconds * game.board.count * 2;
            delta_seconds = 0;

            if platform_key_was_pressed(platform ref, platform_key.enter)
            {
                game.state = game_state.running;

                loop var y; game.board.count
                {
                    loop var x; game.board[0].count
                    {
                        game.board[y][x] = piece_type.empty;
                    }
                }
            }
        }
        case game_state.clearing_rows
        {
            def speed = 2;
            var delta_time = delta_seconds * speed;
            delta_seconds = 0;

            game.tick_timeout = game.tick_timeout - delta_time;

            if game.tick_timeout <= 0
            {
                next_piece(game ref);

                var target_y = 0;
                loop var y; game.board.count
                {
                    var row_is_full = true;
                    loop var x; game.board[0].count
                    {
                        if game.board[y][x] is piece_type.empty
                            row_is_full = false;

                        game.board[target_y][x] = game.board[y][x];
                    }

                    if not row_is_full
                        target_y = target_y + 1;
                }
            }
        }
        case game_state.running
        {
            def speed = 2;
            var delta_time = delta_seconds * speed;

            if platform_key_was_pressed(platform ref, "W"[0])
            {
                game.in_fast_fall = true;
                game.prevent_falling_timeout = 0;
            }

            if not game.in_fast_fall and platform_key_is_active(platform ref, "S"[0])
                delta_time = delta_time * 8;

            if game.in_fast_fall
                delta_time = delta_seconds * game.board.count * 4;

            game.tick_timeout            = game.tick_timeout            - delta_time;
            game.prevent_falling_timeout = game.prevent_falling_timeout - delta_time;

            if not game.in_fast_fall
            {
                var move_x s32 = platform_key_was_pressed(platform ref, "D"[0]) cast(s32) - platform_key_was_pressed(platform ref, "A"[0]) cast(s32);

                if move_x is_not 0
                {
                    var backup = game.piece;

                    move(game.piece ref, move_x, 0);

                    if is_colliding(game.piece, game.board)
                        game.piece = backup;
                    else
                        game.prevent_falling_timeout = 1.0;
                }

                var rotation s32 = platform_key_was_pressed(platform ref, "K"[0]) cast(s32) - platform_key_was_pressed(platform ref, "J"[0]) cast(s32);

                if rotation is_not 0
                {
                    var backup = game.piece;

                    if rotation is 1
                    {
                        loop var i; game.piece.bricks.count
                        {
                            var brick = game.piece.bricks[i] ref;
                            var old = brick deref;
                            brick.x = ( (old.y * 2 - game.piece.center_times_2.y) + game.piece.center_times_2.x) / 2;
                            brick.y = (-(old.x * 2 - game.piece.center_times_2.x) + game.piece.center_times_2.y) / 2;
                        }
                    }
                    else
                    {
                        loop var i; game.piece.bricks.count
                        {
                            var brick = game.piece.bricks[i] ref;
                            var old = brick deref;
                            brick.x = (-(old.y * 2 - game.piece.center_times_2.y) + game.piece.center_times_2.x) / 2;
                            brick.y = ( (old.x * 2 - game.piece.center_times_2.x) + game.piece.center_times_2.y) / 2;
                        }
                    }

                    var ok = true;
                    if is_colliding(game.piece, game.board)
                    {
                        // try move up
                        move(game.piece ref, 0, 1);

                        if is_colliding(game.piece, game.board)
                        {
                            // move left, canel up
                            move(game.piece ref, -1, -1);

                            if is_colliding(game.piece, game.board)
                            {
                                // move right, cancel left
                                move(game.piece ref, 2, 0);

                                // cancel rotation
                                if is_colliding(game.piece, game.board)
                                    ok = false;
                            }
                        }
                    }

                    if not ok
                        game.piece = backup;
                    else
                         game.prevent_falling_timeout = 1.0;
                }
            }

            while game.tick_timeout <= 0
            {
                game.tick_timeout = game.tick_timeout + 1;

                var piece_did_fall = false;
                loop var i; game.piece.bricks.count
                {
                    var y = game.piece.bricks[i].y - 1;

                    if (y < 0) or (game.board[y][game.piece.bricks[i].x] is_not piece_type.empty)
                    {
                        piece_did_fall = true;
                        break;
                    }
                }

                var prevent_falling = game.prevent_falling_timeout > 0;

                if piece_did_fall and (not prevent_falling)
                {
                    loop var i; game.piece.bricks.count
                    {
                        var brick vec2s = game.piece.bricks[i];
                        game.board[brick.y][brick.x] = game.piece.type;
                    }

                    loop var i; game.piece.bricks.count
                    {
                        var brick vec2s = game.piece.bricks[i];
                        if brick.y >= (game.board.count - 4)
                        {
                            game.state = game_state.game_over;
                            break;
                        }
                    }

                    if game.state is game_state.game_over
                    {
                        game.tick_timeout = 0;
                        break;
                    }

                    var has_full_row b8;
                    loop var y; game.board.count
                    {
                        has_full_row = true;
                        loop var x; game.board[0].count
                        {
                            if game.board[y][x] is piece_type.empty
                            {
                                has_full_row = false;
                                break;
                            }
                        }

                        if has_full_row
                            break;
                    }

                    if has_full_row
                        game.state = game_state.clearing_rows;
                    else
                        next_piece(game ref);
                }
                else if not piece_did_fall
                {
                    move(game.piece ref, 0, -1);
                    assert(not is_colliding(game.piece, game.board));
                }
            }
        }
    }

    jiggle_time = fmod(jiggle_time + (platform.delta_seconds * 0.1), 1.0);
    var jiggle = sin(jiggle_time * 2 * pi32) * 0.05 * pi32;

    {
        var position = vec3_cut(renderer.camera_to_world[3]);
        position[2] = 2;
        push_light(renderer ref, position, [ 250, 250, 250 ] vec3);
    }

    var stone_lines u32;

    switch game.state
    case game_state.game_over
    {
        stone_lines = game.tick_timeout cast(u32);
    }
    case game_state.running
    {
        // render preview first
        {
            var preview = game.piece;
            while not is_colliding(preview, game.board)
                move(preview ref, 0, -1);

            move(preview ref, 0, 1);

            var color = lerp(piece_type_colors[game.piece.type], rgba8_white, 0.5);
            color[3] = 150;
            loop var i; preview.bricks.count
            {
                var brick = preview.bricks[i];
                push_brick(renderer ref, brick.x, brick.y, color);
            }
        }

        var color = piece_type_colors[game.piece.type];
        loop var i; game.piece.bricks.count
        {
            var brick = game.piece.bricks[i];
            push_brick(renderer ref, brick.x, brick.y, color);
        }

        push_light(renderer ref, [ game.piece.bricks[0].x, game.piece.bricks[0].y, 2 ] vec3, [ color[0] * 50 / 255.0, color[1] * 50 / 255.0, color[2] * 50 / 255.0 ] vec3);

        // debug center
        if false
        {
            var margin = 0.3;
            var min = v2(game.piece.center_times_2.x, game.piece.center_times_2.y) * 0.5 + margin;
            color[0] = 255 - color[0];
            color[1] = 255 - color[1];
            color[2] = 255 - color[2];
            push_quad(renderer ref, box2_size(min, v2(1 - (2 * margin))), color);
        }

    }

    loop var y; game.board.count
    {
        var row_is_full = true;
        loop var x; game.board[0].count
        {
            if game.board[y][x] is piece_type.empty
            {
                row_is_full = false;
                break;
            }
        }

        loop var x; game.board[0].count
        {
            var type piece_type = game.board[y][x];
            if type is_not piece_type.empty
            {
                var color = piece_type_colors[type];
                if y < stone_lines
                    color = frame_color;
                else if row_is_full
                    color = lerp(rgba8_white, color, game.tick_timeout);

                push_brick(renderer ref, x, y, color);
            }
        }
    }

    loop var i; game.next_piece.bricks.count
    {
        var brick = game.next_piece.bricks[i];

        push_brick(renderer ref, brick.x - 10, brick.y, piece_type_colors[game.next_piece.type]);
    }

    loop var i; game.board[0].count + 2
        push_brick(renderer ref, i - 1, -1, frame_color);

    loop var i; game.board.count
    {
        var color = frame_color;

        if i >= (game.board.count - 4)
            color = frame_color;

        push_brick(renderer ref, -1,             i, color);
        push_brick(renderer ref, game.board[0].count, i, color);
    }

    present(platform ref, renderer ref, jiggle, tmemory ref);
    ui_present(renderer.gl ref, ui);
    gl_window_present(platform ref, renderer.gl ref, window);
}

func move(piece falling_piece ref, dx s32, dy s32)
{
    piece.center_times_2.x = piece.center_times_2.x + (dx * 2);
    piece.center_times_2.y = piece.center_times_2.y + (dy * 2);

    loop var i; piece.bricks.count
    {
        var brick = piece.bricks[i] ref;
        brick.x = brick.x + dx;
        brick.y = brick.y + dy;
    }
}

func is_colliding(piece falling_piece, board board_type) (result b8)
{
    loop var i; piece.bricks.count
    {
        var brick = piece.bricks[i];
        if (brick.x < 0) or (brick.x >= board[0].count)
            return true;

        if brick.y < 0
            return true;

        if board[brick.y][brick.x] is_not piece_type.empty
            return true;
    }

    return false;
}

func make_piece(type piece_type, board_width s32, board_height s32) (result falling_piece)
{
    var piece falling_piece;
    piece.type = type;

    switch type
    case piece_type.o
    {
        var x s32 = board_width / 2 - 1;
        piece.bricks[0].x = x;
        piece.bricks[0].y = board_height - 3;
        piece.bricks[1].x = x + 1;
        piece.bricks[1].y = board_height - 3;
        piece.bricks[2].x = x;
        piece.bricks[2].y = board_height - 4;
        piece.bricks[3].x = x + 1;
        piece.bricks[3].y = board_height - 4;

        piece.center_times_2 = piece.bricks[2];
        piece.center_times_2.x = (piece.center_times_2.x * 2) + 1;
        piece.center_times_2.y = (piece.center_times_2.y * 2) + 1;
    }
    case piece_type.i
    {
        var x s32 = board_width / 2 - 1;
        piece.bricks[0].x = x;
        piece.bricks[0].y = board_height - 1;
        piece.bricks[1].x = x;
        piece.bricks[1].y = board_height - 2;
        piece.bricks[2].x = x;
        piece.bricks[2].y = board_height - 3;
        piece.bricks[3].x = x;
        piece.bricks[3].y = board_height - 4;

        piece.center_times_2 = piece.bricks[2];
        piece.center_times_2.x = (piece.center_times_2.x * 2) + 1;
        piece.center_times_2.y = (piece.center_times_2.y * 2) + 1;
    }
    case piece_type.t
    {
        var x s32 = board_width / 2 - 1;
        piece.bricks[0].x = x;
        piece.bricks[0].y = board_height - 2;
        piece.bricks[1].x = x;
        piece.bricks[1].y = board_height - 3;
        piece.bricks[2].x = x;
        piece.bricks[2].y = board_height - 4;
        piece.bricks[3].x = x + 1;
        piece.bricks[3].y = board_height - 3;

        piece.center_times_2 = piece.bricks[1];
        piece.center_times_2.x = (piece.center_times_2.x * 2);
        piece.center_times_2.y = (piece.center_times_2.y * 2);
    }
    case piece_type.l
    {
        var x s32 = board_width / 2 - 1;
        piece.bricks[0].x = x;
        piece.bricks[0].y = board_height - 2;
        piece.bricks[1].x = x;
        piece.bricks[1].y = board_height - 3;
        piece.bricks[2].x = x;
        piece.bricks[2].y = board_height - 4;
        piece.bricks[3].x = x + 1;
        piece.bricks[3].y = board_height - 4;

        piece.center_times_2 = piece.bricks[1];
        piece.center_times_2.x = (piece.center_times_2.x * 2);
        piece.center_times_2.y = (piece.center_times_2.y * 2);
    }
    case piece_type.j
    {
        var x s32 = board_width / 2;
        piece.bricks[0].x = x;
        piece.bricks[0].y = board_height - 2;
        piece.bricks[1].x = x;
        piece.bricks[1].y = board_height - 3;
        piece.bricks[2].x = x;
        piece.bricks[2].y = board_height - 4;
        piece.bricks[3].x = x - 1;
        piece.bricks[3].y = board_height - 4;

        piece.center_times_2 = piece.bricks[1];
        piece.center_times_2.x = (piece.center_times_2.x * 2);
        piece.center_times_2.y = (piece.center_times_2.y * 2);
    }
    case piece_type.z
    {
        var x s32 = board_width / 2 - 1;
        piece.bricks[0].x = x - 1;
        piece.bricks[0].y = board_height - 3;
        piece.bricks[1].x = x;
        piece.bricks[1].y = board_height - 3;
        piece.bricks[2].x = x;
        piece.bricks[2].y = board_height - 4;
        piece.bricks[3].x = x + 1;
        piece.bricks[3].y = board_height - 4;

        piece.center_times_2 = piece.bricks[1];
        piece.center_times_2.x = (piece.center_times_2.x * 2);
        piece.center_times_2.y = (piece.center_times_2.y * 2);
    }
    case piece_type.s
    {
        var x s32 = board_width / 2 - 1;
        piece.bricks[0].x = x + 1;
        piece.bricks[0].y = board_height - 3;
        piece.bricks[1].x = x;
        piece.bricks[1].y = board_height - 3;
        piece.bricks[2].x = x;
        piece.bricks[2].y = board_height - 4;
        piece.bricks[3].x = x - 1;
        piece.bricks[3].y = board_height - 4;

        piece.center_times_2 = piece.bricks[1];
        piece.center_times_2.x = (piece.center_times_2.x * 2);
        piece.center_times_2.y = (piece.center_times_2.y * 2);
    }
    else
    {
        assert(false);
    }

    return piece;
}

func make_random_piece(random random_pcg ref, board_width s32, board_height s32) (result falling_piece)
{
    var type = (random_index(random, piece_type.count - 1) + 1) cast(piece_type);
    return make_piece(type, board_width, board_height);
}

func push_brick(renderer render_api ref, x f32, y f32, color rgba8, location = get_call_location())
{
    var margin = 0.05;
    var min = v2(x, y) + margin - 0.5;
    push_quad(renderer, box2_size(min, v2(1 - (2 * margin))), color, location);

    push_command(renderer, mat4_transform([ x, y, 0] vec3), [ color[0] / 255.0, color[1] / 255.0, color[2] / 255.0, color[3] / 255.0 ] vec4);
}
