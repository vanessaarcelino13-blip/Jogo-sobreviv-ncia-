extends CharacterBody2D

@export var speed: float = 220.0
var facing: Vector2 = Vector2.DOWN

func _ready() -> void:
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    queue_redraw()

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if direction.length() > 0.05:
        facing = direction.normalized()
    velocity = direction * speed
    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        collect_nearest_resource()

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
    draw_circle(Vector2(0, 3), 14, Color(0, 0, 0, 0.22))
    draw_circle(Vector2.ZERO, 12, Color("e8bd8c"))
    draw_circle(Vector2(0, -5), 8, Color("263b35"))
    draw_circle(Vector2(-3, -1), 1.3, Color("17221f"))
    draw_circle(Vector2(3, -1), 1.3, Color("17221f"))
    draw_line(Vector2.ZERO, facing * 17.0, Color("fff0c9"), 2.0)
