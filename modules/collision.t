
module math;

import platform;
import memory;
import meta;

struct collision_system
{
    edges   edge2[];

    spheres sphere2[256];
    bodies  collision_body[256];
    events collision_event[256];

    sphere_count u32;
    body_count   u32;
    event_count  u32;
}

struct ray2
{
    origin    vec2;
    direction vec2;
}

// TODO: fix these names!
struct plane2
{
    up            vec2;
    up_dot_origin f32;
}

struct sphere2
{
    center vec2;
    radius f32;
}

struct edge2
{
    from vec2;
    to vec2;
}

struct ray3
{
    origin    vec3;
    direction vec3;
}

struct plane3
{
    up            vec3;
    up_dot_origin f32;
}

struct sphere3
{
    center vec3;
    radius f32;
}

struct collision_body
{
    position vec2;
    movement vec2;
    sphere_offset u32;
    sphere_count  u32;
}

struct collision_event
{
    normal     vec2;
    body_index u32;
    other      other_collider;
}

func frame_begin(system collision_system ref)
{
    system.body_count   = 0;
    system.sphere_count = 0;
}

struct other_collider
{
    is_body b8;

    expand collider union
    {
        collision_index  u32;
        edge_index       u32;
        body_index       u32;
    }
}

struct body_step_movement
{
    movement          vec2;
    remaining_seconds f32;

    allowed_seconds   f32;

    //wall_normal       vec2;

    //is_other_body b8;
    //expand collider union
    //{
//        collision_index  u32;
//        edge_index       u32;
//        body_index       u32;
//    }
}

struct collision_entry
{
    wall_normal vec2;
    body_index  u32;
    at_seconds  f32;
    other       other_collider;
}

func maybe_add_event(memory memory_arena ref, entries collision_entry[] ref, allowed_seconds f32 ref, body_index u32, at_seconds f32, wall_normal vec2, is_body b8, other_index u32)
{
    if at_seconds < (allowed_seconds deref)
    {
        // remove all previous entries with this body_index
        loop var i; entries.count
        {
            var entry = entries[i];
            if (entry.body_index is body_index) or (entry.other.is_body and (entry.other.body_index is body_index))
            {
                entries[i] = entries[entries.count - 1];
                entries.count -= 1;
                i -= 1;
            }
        }

        // apply new size
        reallocate_array(memory, entries, entries.count);
    }

    if at_seconds <= (allowed_seconds deref)
    {
        allowed_seconds deref = at_seconds;

        reallocate_array(memory, entries, entries.count + 1);
        var entry = entries[entries.count - 1] ref;

        entry.wall_normal = wall_normal;
        entry.body_index = body_index;
        entry.at_seconds = at_seconds;
        entry.other.is_body = is_body;
        entry.other.collision_index = other_index;
    }
}

func frame_end(system collision_system ref, delta_seconds f32, tmemory memory_arena ref)
{
    var tmemory_used_count = tmemory.used_byte_count;
    var body_movements body_step_movement[];
    reallocate_array(tmemory, body_movements ref, system.body_count);
    clear({ type_byte_count(body_step_movement) * body_movements.count, body_movements.base cast(u8 ref) } u8[]);

    def steps_per_second = 60;

    def collision_step_seconds = 1.0 / steps_per_second;
    var step_count = maximum(delta_seconds / collision_step_seconds + 0.5, 1);

    system.event_count = 0;

    loop var body_index u32; system.body_count
    {
        var body = system.bodies[body_index] ref;

        body_movements[body_index].movement = body.movement;
    }

    loop var step; step_count
    {
        var step_scope = diagram_scope_begin();

        loop var body_index u32; system.body_count
        {
            var body = system.bodies[body_index] ref;

            body_movements[body_index].remaining_seconds += collision_step_seconds;
            body_movements[body_index].allowed_seconds = body_movements[body_index].remaining_seconds;
            //body_movements[body_index].wall_normal = {} vec2;
            //body_movements[body_index].collision_index = -1 cast(u32);
        }

        var entries collision_entry[];

        loop var body_index u32; system.body_count
        {
            var body_scope = diagram_scope_begin();

            var body = system.bodies[body_index] ref;

            var movement        = body_movements[body_index].movement;
            var allowed_seconds = body_movements[body_index].allowed_seconds ref;

            multiline_comment
            {
                var allowed_seconds = body_movements[body_index].allowed_seconds;
                var wall_normal     = body_movements[body_index].wall_normal;

                var min_event collision_event;
                min_event.body_index = body_index;
                min_event.edge_index = -1 cast(u32);
            }

            loop var sphere_index = body.sphere_offset; body.sphere_offset + body.sphere_count
            {
                var sphere = system.spheres[sphere_index];
                sphere.center += body.position;

                draw_sphere(sphere, diagram_color_a);
                draw_edge({ sphere.center, sphere.center + (movement * delta_seconds) } edge2, diagram_color_a);

                loop var edge_index u32; system.edges.count
                {
                    // dot(sphere.center + movement * t, normal) - dot(edge.from, normal) == 0
                    // dot(sphere.center - edge.from, normal) + dot(movement, normal) * t == 0
                    // t == -dot(sphere.center - edge.from, normal) / dot(movement, normal)

                    var edge = system.edges[edge_index];
                    var edge_direction = edge.to - edge.from;
                    var normal vec2;
                    normal[0] = -edge_direction[1];
                    normal[1] =  edge_direction[0];
                    normal = normalize(normal);

                    var m_dot_n = dot(normal, body.movement);

                    if m_dot_n >= 0
                        continue;

                    // we are inside plane
                    var penetration = dot(sphere.center - edge.from, normal);
                    if (penetration >= 0) and (penetration < sphere.radius)
                    {
                        // we are in edge
                        var d = dot(sphere.center - edge.from, edge_direction) / squared_length(edge_direction);
                        if (d >= 0) and (d <= 1)
                        {
                            draw_edge(edge, diagram_color_b);
                            draw_edge({ (edge.from + edge.to) * 0.5, (edge.from + edge.to) * 0.5 + normal } edge2, diagram_color_b);

                            maybe_add_event(tmemory, entries ref, allowed_seconds, body_index, 0, normal, false, edge_index);

                            multiline_comment
                            {
                                allowed_seconds = 0;
                                wall_normal = normal;
                                min_event.is_other_body = false;
                                min_event.edge_index = edge_index;
                            }
                        }
                    }
                    // we would collide
                    else
                    {
                        var c_dot_n = dot(normal, sphere.center - edge.from - (normal * sphere.radius));

                        assert(m_dot_n is_not 0);

                        var t = -c_dot_n / m_dot_n;

                        if (t >= 0) and (t <= (allowed_seconds deref))
                        {
                            var new_center = sphere.center + (body.movement * t);
                            // we are in edge
                            var d = dot(new_center - edge.from, edge_direction) / squared_length(edge_direction);

                            draw_sphere({ edge.from + (edge_direction * d), sphere.radius } sphere2, diagram_color_fail);

                            if (d >= 0) and (d <= 1)
                            {
                                draw_edge(edge, diagram_color_b);
                                draw_edge({ (edge.from + edge.to) * 0.5, (edge.from + edge.to) * 0.5 + normal } edge2, diagram_color_b);

                                draw_sphere({ new_center, sphere.radius } sphere2, diagram_color_success);

                                maybe_add_event(tmemory, entries ref, allowed_seconds, body_index, t, normal, false, edge_index);

                                multiline_comment
                                {
                                    allowed_seconds = t;
                                    wall_normal = normal;
                                    min_event.is_other_body = false;
                                    min_event.edge_index = edge_index;
                                }
                            }
                        }
                    }
                }

                loop var other_body_index = body_index + 1; system.body_count
                {
                    var other_body = system.bodies[other_body_index] ref;

                    var other_movement = body_movements[other_body_index].movement;

                    var relative_movement = movement - other_movement;

                    var other_body_scope = diagram_scope_begin();
                    draw_sphere(sphere, diagram_color_a);
                    draw_edge({ sphere.center, sphere.center + (movement * delta_seconds) } edge2, diagram_color_a);

                    loop var other_sphere_index = other_body.sphere_offset; other_body.sphere_offset + other_body.sphere_count
                    {
                        var other_sphere = system.spheres[other_sphere_index];
                        other_sphere.center += other_body.position;

                        draw_sphere({ other_sphere.center, other_sphere.radius } sphere2, diagram_color_b);
                        draw_edge({ other_sphere.center, other_sphere.center + (other_movement * delta_seconds) } edge2, diagram_color_b);


                        // combined radius of other sphere
                        var combined_radius = other_sphere.radius + sphere.radius;

                        // sphrere postition realtive to other sphere
                        var relative_position = sphere.center - other_sphere.center;


                        if squared_length(relative_position) <= (combined_radius * combined_radius)
                        {
                            var sphere_center_prime       = sphere.center;
                            var other_sphere_center_prime = other_sphere.center;
                            var normal = normalize(sphere_center_prime - other_sphere_center_prime);

                            // moving outside of each of other
                            if dot(normal, movement) >= 0
                                continue;

                            draw_sphere({ sphere_center_prime,       sphere.radius } sphere2,       diagram_color_a_prime);
                            draw_sphere({ other_sphere_center_prime, other_sphere.radius } sphere2, diagram_color_b_prime);


                            draw_edge({ sphere_center_prime, sphere_center_prime + normal } edge2, diagram_color_a_prime);

                            if (0 <= (allowed_seconds deref)) and (0 <= body_movements[other_body_index].allowed_seconds)
                            {
                                maybe_add_event(tmemory, entries ref, allowed_seconds, body_index, 0, normal, true, other_body_index);
                                maybe_add_event(tmemory, entries ref, body_movements[other_body_index].allowed_seconds ref, other_body_index, 0, -normal, true, body_index);
                            }

                            multiline_comment
                            {
                                if t < allowed_seconds
                                {
                                    allowed_seconds = t;
                                    wall_normal = normal;
                                    min_event.is_other_body = true;
                                    min_event.other_body_index = other_body_index;
                                }

                                if t < body_movements[other_body_index].allowed_seconds
                                {
                                    body_movements[other_body_index].allowed_seconds = t;
                                    body_movements[other_body_index].wall_normal     = -normal;
                                    body_movements[other_body_index].is_other_body = true;
                                    body_movements[other_body_index].other_body_index = body_index;
                                }
                            }

                            continue;
                        }

                        // |sphere.center + relative_movement * t  - other_sphere.center|² == (sphere.radius + other_sphere.radius)²
                        // | relative_position + relative_movement * t |² == (sphere.radius + other_sphere.radius)²

                        // (a + b)² == a² + 2ab + b²

                        // squared_length(relative_position) + dot(relative_position, relative_movement) * 2 * t + squared_length(relative_movement) * t² == radius²
                        // squared_length(relative_position) + dot(relative_position, relative_movement) * 2 * t +  == combined_radius²
                        // squared_length(relative_movement) * t² + dot(relative_position, relative_movement) * 2 * t + squared_length(relative_position) - combined_radius² == 0
                        // a * t² + b * t + c == 0

                        var two_a = squared_length(relative_movement) * 2;
                        if two_a is 0
                            continue;

                        // var c = squared_length(relative_position) - combined_radius²
                        var b = dot(relative_position, relative_movement) * 2;

                        // root_squared = b * b - 4 * a * c
                        var root_squared = (b * b) - (two_a * 2 * (squared_length(relative_position) - (combined_radius * combined_radius)));

                        if root_squared < 0
                            continue;

                        var root = sqrt(root_squared);

                        var t0 = (-b - root) / two_a;
                        var t1 = (-b + root) / two_a;

                        var t f32;
                        if (t0 > 0) and (t0 < t1)
                            t = t0;
                        else if t1 > 0
                            t = t1;
                        else
                            continue;

                        var sphere_center_prime       = sphere.center       + (movement * t);
                        var other_sphere_center_prime = other_sphere.center + (other_movement * t);
                        draw_sphere({ sphere_center_prime,       sphere.radius } sphere2,       diagram_color_a_prime);
                        draw_sphere({ other_sphere_center_prime, other_sphere.radius } sphere2, diagram_color_b_prime);

                        var normal = normalize(sphere_center_prime - other_sphere_center_prime);
                        draw_edge({ sphere_center_prime, sphere_center_prime + normal } edge2, diagram_color_a_prime);

                        if (t <= (allowed_seconds deref)) and (t <= body_movements[other_body_index].allowed_seconds)
                        {
                            maybe_add_event(tmemory, entries ref, allowed_seconds, body_index, t, normal, true, other_body_index);
                            maybe_add_event(tmemory, entries ref, body_movements[other_body_index].allowed_seconds ref, other_body_index, t, -normal, true, body_index);
                        }

                        multiline_comment
                        {
                            if t < allowed_seconds
                            {
                                allowed_seconds = t;
                                wall_normal = normal;
                                min_event.is_other_body = true;
                                min_event.other_body_index = other_body_index;
                            }

                            if t < body_movements[other_body_index].allowed_seconds
                            {
                                body_movements[other_body_index].allowed_seconds = t;
                                body_movements[other_body_index].wall_normal     = -normal;
                                body_movements[other_body_index].is_other_body = true;
                                body_movements[other_body_index].other_body_index = body_index;
                            }
                        }
                    }

                    diagram_scope_end(other_body_scope);
                }
            }

            multiline_comment
            {
                body_movements[body_index].allowed_seconds = allowed_seconds;
                body_movements[body_index].wall_normal     = wall_normal;
                body_movements[body_index].is_other_body   = min_event.is_other_body;
                body_movements[body_index].collision_index = min_event.collision_index;
            }

            diagram_scope_end(body_scope);
        }

        // update all bodies together
        loop var body_index; system.body_count
        {
            var body = system.bodies[body_index] ref;

            var info = body_movements[body_index] ref;

            body.position += info.movement * info.allowed_seconds;
            info.remaining_seconds -= info.allowed_seconds;
            //info.movement -= (info.wall_normal * dot(info.movement, info.wall_normal));

            multiline_comment
            {
                if info.collision_index is_not -1 cast(u32)
                {
                    //if info.is_other_body and (body_index < info.other_body_index)
                    {
                        var event = system.events[system.event_count] ref;
                        system.event_count += 1;

                        event.other =
                        event.is_other_body   = info.is_other_body;
                        event.collision_index = info.collision_index;
                        event.normal          = info.wall_normal;
                    }
                }
            }
        }

        loop var entry_index; entries.count
        {
            var entry = entries[entry_index];

            body_movements[entry.body_index].movement -= (entry.wall_normal * dot(body_movements[entry.body_index].movement, entry.wall_normal));

            if entry.other.is_body
                body_movements[entry.other.body_index].movement -= (-entry.wall_normal * dot(body_movements[entry.other.body_index].movement, -entry.wall_normal));

            var event = system.events[system.event_count] ref;
            system.event_count += 1;

            event.normal = entry.wall_normal;
            event.body_index = entry.body_index;
            event.other  = entry.other;
        }

        free(tmemory, entries.base);

        diagram_scope_end(step_scope);
    }

    free(tmemory, body_movements.base);

    tmemory.used_byte_count = tmemory_used_count;
}

func add_body(system collision_system ref, position vec2, movement vec2) (body collision_body ref)
{
    var body = system.bodies[system.body_count] ref;
    system.body_count += 1;

    body deref = {} collision_body;
    body.position = position;
    body.movement = movement;
    body.sphere_offset = system.sphere_count;

    return body;
}

func add_sphere(system collision_system ref, body collision_body ref, center vec2, radius f32)
{
    assert(system.sphere_count is (body.sphere_offset + body.sphere_count));
    var sphere = system.spheres[system.sphere_count] ref;
    system.sphere_count += 1;

    sphere.center = center;
    sphere.radius = radius;

    body.sphere_count += 1;
}

func get_normal(edge edge2) (normal vec2)
{
    var edge_direction = edge.to - edge.from;
    var normal vec2;
    normal[0] = -edge_direction[1];
    normal[1] =  edge_direction[0];
    normal = normalize(normal);
    return normal;
}

func get_hit_distance(ray ray3, plane plane3) (ok b8, distance f32)
{
    var up_dot_direction = dot(plane.up, ray.direction);

    if up_dot_direction is 0
        return false, 0;

    var distance = (plane.up_dot_origin - dot(plane.up, ray.origin)) / up_dot_direction;
    return true, distance;
}

func get_hit_distance(ray ray3, sphere sphere3) (ok b8, distances f32[2])
{
    // | ray.origin + ray.direction * distance - sphere.center |² <= sphere.radius²
    // [ ray.origin - sphere.center |² + 2 * dot(ray.direction, ray.origin - sphere.center) * distance + | ray.direction |² * distance² <= sphere.radius²
    // distance² * | ray.direction |² + distance * 2 * dot(ray.direction, ray.origin - sphere.center) + | ray.origin - sphere.center |² - sphere.radius² <= 0
    //

    var relative_ray_origin = ray.origin - sphere.center;
    var a = squared_length(ray.direction);

    if a <= 0
        return false, 0;

    var b = 2 * dot(ray.direction, relative_ray_origin);
    var c = squared_length(relative_ray_origin) - (sphere.radius * sphere.radius);
    var root_squared = b * b - (4 * a * c);

    if root_squared < 0
        return false, 0;

    var root = sqrt(root_squared);

    var distances f32[2];
    distances[0] = (-b - root) / (2 * a);
    distances[1] = (root - b) / (2 * a);

    return true, distances;
}

func get_closest_positive_hit_distance(ray ray3, sphere sphere3) (ok b8, distance f32)
{
    var hit = get_hit_distance(ray, sphere);
    if hit.ok
    {
        var distance = hit.distances[0];
        if distance <= 0
            distance = hit.distances[1];

        if distance <= 0
            return false, 0;

        return true, distance;
    }
    else
    {
        return false, 0;
    }
}

var global debug_diagram debug_diagram_stack;

struct debug_diagram_stack
{
    scopes  diagram_scope_info[1024];
    spheres diagram_sphere2[10000];
    edges   diagram_edge2[10000];

    scope_count  u32;
    sphere_count u32;
    edge_count   u32;
}

struct diagram_scope_info
{
    sphere_offset u32;
    edge_offset   u32;
    sphere_count  u32;
    edge_count    u32;
}

struct diagram_sphere2
{
    color  vec4;
    sphere sphere2;
}

struct diagram_edge2
{
    color vec4;
    edge  edge2;
}

def diagram_color_a       = [ 1, 0, 0, 1 ] vec4;
def diagram_color_b       = [ 0, 0, 1, 1 ] vec4;

def diagram_color_a_prime = [ 1,   0.5, 0.5, 1 ] vec4;
def diagram_color_b_prime = [ 0.5, 0.5, 1.0, 1 ] vec4;
def diagram_color_success = [ 0, 1, 0, 1 ] vec4;
def diagram_color_fail    = [ 1, 1, 0, 1 ] vec4;

func diagram_frame_begin()
{
    debug_diagram.scope_count  = 0;
    debug_diagram.sphere_count = 0;
    debug_diagram.edge_count   = 0;
}

func diagram_frame_end()
{
    if debug_diagram.scope_count
    {
        var scope = debug_diagram.scopes[debug_diagram.scope_count - 1] ref;
        diagram_scope_end(scope);
    }
}

func diagram_scope()
{
    if debug_diagram.scope_count
    {
        var scope = debug_diagram.scopes[debug_diagram.scope_count - 1] ref;
        diagram_scope_end(scope);
     }

    diagram_scope_begin();
}

func diagram_scope_begin() (scope diagram_scope_info ref)
{
    if debug_diagram.scope_count >= debug_diagram.scopes.count
        return null;

    var scope = debug_diagram.scopes[debug_diagram.scope_count] ref;
    debug_diagram.scope_count += 1;

    scope.sphere_offset = debug_diagram.sphere_count;
    scope.edge_offset = debug_diagram.edge_count;

    return scope;
}

func diagram_scope_end(scope diagram_scope_info ref)
{
    if scope
    {
        scope.sphere_count = debug_diagram.sphere_count - scope.sphere_offset;
        scope.edge_count = debug_diagram.edge_count - scope.edge_offset;
    }
}

func draw_sphere(sphere sphere2, color vec4)
{
    var diagram = debug_diagram.spheres[debug_diagram.sphere_count] ref;
    debug_diagram.sphere_count += 1;

    diagram.sphere = sphere;
    diagram.color  = color;
}

func draw_edge(edge edge2, color vec4)
{
    var diagram = debug_diagram.edges[debug_diagram.edge_count] ref;
    debug_diagram.edge_count += 1;

    diagram.edge  = edge;
    diagram.color = color;
}

func get_hit_distance(ray ray2, plane plane2) (ok b8, distance f32)
{
    var up_dot_direction = dot(plane.up, ray.direction);

    if up_dot_direction is 0
        return false, 0;

    var distance = (plane.up_dot_origin - dot(plane.up, ray.origin)) / up_dot_direction;
    return true, distance;
}

func get_hit_distance(ray ray2, box box2, max_distance f32 = 10000) (ok b8, distance f32)
{
    var min_distance = max_distance;

    if ray.direction.x is_not 0
    {
        var distance = (box.min.x - ray.origin.x) / ray.direction.x;
        if distance >= 0
        {
            var y = ray.direction.y * distance + ray.origin.y;
            if (box.min.y <= y) and (y < box.max.y) and (min_distance > distance)
                min_distance = distance;
        }

        distance = (box.max.x - ray.origin.x) / ray.direction.x;
        if distance >= 0
        {
            var y = ray.direction.y * distance + ray.origin.y;
            if (box.min.y <= y) and (y < box.max.y) and (min_distance > distance)
                min_distance = distance;
        }
    }

    if ray.direction.y is_not 0
    {
        var distance = (box.min.y - ray.origin.y) / ray.direction.y;
        if distance >= 0
        {
            var x = ray.direction.x * distance + ray.origin.x;
            if (box.min.x <= x) and (x < box.max.x) and (min_distance > distance)
                min_distance = distance;
        }

        distance = (box.max.y - ray.origin.y) / ray.direction.y;
        if distance >= 0
        {
            var x = ray.direction.x * distance + ray.origin.x;
            if (box.min.x <= x) and (x < box.max.x) and (min_distance > distance)
                min_distance = distance;
        }
    }

    return min_distance < max_distance, min_distance;
}

func get_hit_distance(ray_to_box_transform mat_transform, ray ray3, box box3, max_distance f32 = 10000) (ok b8, distance f32)
{
    ray.origin    = transform(ray_to_box_transform, ray.origin);
    ray.direction = transform(ray_to_box_transform, ray.direction, 0);
    return get_hit_distance(ray, box, max_distance);
}

func get_hit_distance(ray ray3, box box3, max_distance f32 = 10000) (ok b8, distance f32)
{
    var min_distance = max_distance;

    var distance_to_box_min = (box.min - ray.origin) / ray.direction;
    var distance_to_box_max = (box.max - ray.origin) / ray.direction;

    loop var dim u32; 3
    {
        if ray.direction[dim] is_not 0
        {
            var distance = distance_to_box_min[dim];
            if (distance >= 0) and (min_distance > distance)
            {
                var point = ray.direction * distance + ray.origin;

                var ok = true;
                loop var i u32; 2
                {
                    var other_dim = (dim + i + 1) mod 3;

                    if (box.min[other_dim] > point[other_dim]) or (point[other_dim] >= box.max[other_dim])
                    {
                        ok = false;
                        break;
                    }
                }

                if ok
                    min_distance = distance;
            }

            distance = distance_to_box_max[dim];
            if (distance >= 0) and (min_distance > distance)
            {
                var point = ray.direction * distance + ray.origin;

                var ok = true;
                loop var i u32; 2
                {
                    var other_dim = (dim + i + 1) mod 3;

                    if (box.min[other_dim] > point[other_dim]) or (point[other_dim] >= box.max[other_dim])
                    {
                        ok = false;
                        break;
                    }
                }

                if ok
                    min_distance = distance;
            }
        }
    }

    return min_distance < max_distance, min_distance;
}