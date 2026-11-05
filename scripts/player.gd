extends CharacterBody2D

@export var speed: float = 220.0
@export var pulse_radius: float = 112.0
@export var pulse_cooldown: float = 1.4
var facing: Vector2 = Vector2.DOWN
var pulse_timer := 0.0
var pulse_visual := 0.0

func _ready() -> void:
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    queue_redraw()

func _physics_process(delta: float) -> void:
    pulse_timer = maxf(0.0, pulse_timer - delta)
    pulse_visual = maxf(0.0, pulse_visual - delta)
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if direction.length() > 0.05:
        facing = direction.normalized()
    velocity = direction * speed
    move_and_slide()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        collect_nearest_resource()
    if event.is_action_pressed("defend"):
        use_pulse()

func use_pulse() -> void:
    if pulse_timer > 0.0:
        return
    pulse_timer = pulse_cooldown
    pulse_visual = 0.28
    for animal in get_tree().get_nodes_in_group("wildlife"):
        if is_instance_valid(animal) and global_position.distance_to(animal.global_position) <= pulse_radius:
            if animal.has_method("scare_away"):
                animal.scare_away(global_position)
    queue_redraw()

func collect_nearest_resource() -> void:
    var closest: Area2D = null
    var closest_distance := 72.0
    for item in get_tree().get_nodes_in_group("resources"):
        if not is_instance_valid(item):
            continue
        var distance := global_position.distance_to(item.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest = item
    if closest and closest.has_method("collect"):
        closest.collect()

func _draw() -> void:
    if pulse_visual > 0.0:
        var alpha := pulse_visual / 0.28
        draw_arc(Vector2.ZERO, pulse_radius * (1.0 - alpha * 0.35), 0.0, TAU, 48, Color(0.45, 0.85, 1.0, alpha * 0.8), 3.0)
    draw_circle(Vector2(0, 3), 12, Color(0, 0, 0, 0.22))
    draw_circle(Vector2.ZERO, 10, Color("e8bd8c"))
    draw_circle(Vector2(0, -7), 9, Color("263b35"))
    draw_circle(Vector2(-3, -1), 1.3, Color("17221f"))
    draw_circle(Vector2(3, -1), 1.3, Color("17221f"))
    draw_line(Vector2.ZERO, facing * 15.0, Color("a9eaff"), 2.5)
