extends Camera2D

@export var look_ahead_distance: float = 48.0
@export var look_ahead_speed: float = 2.4
@export var return_speed: float = 3.5

var player: CharacterBody2D
var base_offset: Vector2 = Vector2.ZERO
var current_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
    player = get_parent() as CharacterBody2D
    base_offset = offset
    position_smoothing_enabled = true
    position_smoothing_speed = 5.0
    zoom = Vector2(2.0, 2.0)
    limit_left = -1800
    limit_top = -1200
    limit_right = 1800
    limit_bottom = 1200

func _process(delta: float) -> void:
    if not is_instance_valid(player):
        return

    var velocity: Vector2 = player.velocity
    var target_offset := Vector2.ZERO

    if velocity.length() >= 10.0:
        target_offset = velocity.normalized() * look_ahead_distance
        current_offset = current_offset.lerp(
            target_offset,
            1.0 - exp(-look_ahead_speed * delta)
        )
    else:
        current_offset = current_offset.lerp(
            Vector2.ZERO,
            1.0 - exp(-return_speed * delta)
        )

    offset = base_offset + current_offset
