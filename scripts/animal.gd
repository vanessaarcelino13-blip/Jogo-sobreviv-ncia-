extends CharacterBody2D

@export var move_speed: float = 62.0
var target: Node2D
var flee_timer := 0.0
var flee_direction := Vector2.ZERO
var wander_direction := Vector2.ZERO
var wander_timer := 0.0

func _ready() -> void:
    add_to_group("wildlife")
    queue_redraw()
    wander_direction = Vector2.RIGHT.rotated(randf_range(-PI, PI))

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target):
        var players := get_tree().get_nodes_in_group("player")
        if players.size() > 0:
            target = players[0]
    if flee_timer > 0.0:
        flee_timer -= delta
        velocity = flee_direction * move_speed * 2.3
    elif is_instance_valid(target) and global_position.distance_to(target.global_position) < 270.0:
        velocity = global_position.direction_to(target.global_position) * move_speed * 0.55
    else:
        wander_timer -= delta
        if wander_timer <= 0.0:
            wander_timer = randf_range(1.2, 3.0)
            wander_direction = Vector2.RIGHT.rotated(randf_range(-PI, PI))
        velocity = wander_direction * move_speed * 0.25
    move_and_slide()

func scare_away(from_position: Vector2) -> void:
    flee_direction = (global_position - from_position).normalized()
    if flee_direction.length() < 0.1:
        flee_direction = Vector2.RIGHT
    flee_timer = 2.8

func _draw() -> void:
    draw_circle(Vector2(0, 5), 15, Color(0, 0, 0, 0.2))
    draw_ellipse(Vector2.ZERO, Vector2(12, 8), Color("9a704b"))
    draw_circle(Vector2(0, -7), 8, Color("b8895d"))
    draw_triangle(PackedVector2Array([Vector2(-7,-12), Vector2(-9,-20), Vector2(-2,-14)]), Color("80583e"))
    draw_triangle(PackedVector2Array([Vector2(7,-12), Vector2(9,-20), Vector2(2,-14)]), Color("80583e"))
    draw_circle(Vector2(-3, -8), 1.2, Color("211b18"))
    draw_circle(Vector2(3, -8), 1.2, Color("211b18"))
    draw_circle(Vector2(0, -4), 1.8, Color("30221d"))
