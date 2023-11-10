
module camera;

import platform;
import math;

struct fly_camera
{
    camera_to_world mat4;
    world_to_camera mat4;
    position vec3;
    rotation_x f32;
    rotation_y f32;

    zoom_mouse_wheel f32;
    zoom f32;
}

def camera_zoom_mouse_wheel_offset = 4;

func init(camera fly_camera ref, position vec3, target vec3, up = [ 0, 1, 0 ] vec3)
{
    var forward = normalize(position - target);
    var right   = normalize(cross(up, forward));
    //camera.camera_to_world.up      = cross(camera.camera_to_world.forward, camera.camera_to_world.right);
    //camera.camera_to_world.translation = position;

    camera.position = position;

    var projected_forward = normalize(forward - (up * dot(forward, up)));

    camera.rotation_x = acos(dot(projected_forward, forward));
    if dot(forward, up) > 0
        camera.rotation_x = -camera.rotation_x;

    camera.rotation_y = acos(dot(projected_forward, right));
    if dot(cross(projected_forward, right), up) <= 0
        camera.rotation_y = -camera.rotation_y;

    update_transform(camera);
    camera.world_to_camera = mat4_inverse_transform_unscaled(camera.camera_to_world);
}

func update(camera fly_camera ref, movement vec3, rotation vec2, zoom_wheel_delta f32)
{
    // arbitrary constants
    camera.zoom_mouse_wheel += zoom_wheel_delta;
    camera.zoom_mouse_wheel = clamp(camera.zoom_mouse_wheel, -4, 4);
    var zoom = pow(2.0, camera.zoom_mouse_wheel + camera_zoom_mouse_wheel_offset);

    if zoom_wheel_delta is_not 0
        camera.position += camera.camera_to_world.forward * (zoom - camera.zoom);

    camera.zoom = zoom;

    // relative to camera view
    movement = vec3_cut(camera.camera_to_world * vec4_expand(movement, 0)) * zoom;

    camera.rotation_x -= 2 * pi32 * rotation.x;
    camera.rotation_y += 2 * pi32 * rotation.y;

    camera.position += movement;

    update_transform(camera);
}

func update_transform(camera fly_camera ref)
{
    camera.camera_to_world = get_camera_to_world_transform(camera.position, camera.rotation_x, camera.rotation_y);
}

func get_camera_to_world_transform(position vec3, rotation_x f32, rotation_y f32) (camera_to_world mat_transform)
{
    var y_rotation = quat_axis_angle([ 0, 1, 0 ] vec3, rotation_y);
    var x_rotation = quat_axis_angle([ 1, 0, 0 ] vec3, rotation_x);

    var rotation = x_rotation * y_rotation;

    return mat4_transform(rotation, position);
}

func update(camera fly_camera ref, platform platform_api ref, window platform_window ref)
{
    var movement vec3;
    movement.x = platform_key_is_active(platform, "D"[0]) cast(f32) - platform_key_is_active(platform, "A"[0]) cast(f32);
    movement.y = platform_key_is_active(platform, "E"[0]) cast(f32) - platform_key_is_active(platform, "Q"[0]) cast(f32);
    movement.z = platform_key_is_active(platform, "S"[0]) cast(f32) - platform_key_is_active(platform, "W"[0]) cast(f32);

    var mouse_delta = [ window.previous_mouse_position.x, window.previous_mouse_position.y ] vec2 - [ window.mouse_position.x, window.mouse_position.y ] vec2;

    var rotation vec2;
    if platform_key_is_active(platform, platform_key.mouse_right)
    {
        rotation.y += mouse_delta.x / 2048.0;
        rotation.x += mouse_delta.y / 2048.0;
    }

    update(camera, movement * platform.delta_seconds, rotation, platform.mouse_wheel_delta * -0.25);
}