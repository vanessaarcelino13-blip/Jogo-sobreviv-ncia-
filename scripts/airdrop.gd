extends StaticBody2D

@export var loot_table: Array[String] = [
    "metal_axe", "metal_pickaxe", "fiber", "hide",
    "coat", "sun_hat", "airdrop_chip", "stone"
]

var player_in_range := false
var remaining_loot: Array[String] = []
var beacon_phase := 0.0

func _ready() -> void:
    add_to_group("airdrops")
    for i in range(3):
        remaining_loot.append(loot_table.pick_random())
    $InteractArea.body_entered.connect(_on_body_entered)
    $InteractArea.body_exited.connect(_on_body_exited)
    $HintLabel.text = "[E] Abrir suprimentos"
    $HintLabel.visible = false

    var smoke := CPUParticles2D.new()
    smoke.position = Vector2(0, -15)
    smoke.amount = 18
    smoke.lifetime = 1.4
    smoke.emitting = true
    smoke.direction = Vector2(0, -1)
    smoke.spread = 22.0
    smoke.gravity = Vector2(0, -18)
    smoke.initial_velocity_min = 8.0
    smoke.initial_velocity_max = 19.0
    smoke.scale_amount_min = 0.7
    smoke.scale_amount_max = 1.3
    smoke.color = Color(0.88, 0.24, 0.16, 0.48)
    add_child(smoke)

func _process(delta: float) -> void:
    beacon_phase = fposmod(beacon_phase + delta * 2.4, TAU)
    queue_redraw()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_in_range = true
        $HintLabel.visible = true

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_in_range = false
        $HintLabel.visible = false

func _unhandled_input(event: InputEvent) -> void:
    if player_in_range and event.is_action_pressed("interact"):
        _loot()
        get_viewport().set_input_as_handled()

func _loot() -> void:
    for item_id in remaining_loot.duplicate():
        if GameManager.add_item(item_id, 1):
            remaining_loot.erase(item_id)
    if remaining_loot.is_empty():
        queue_free()
    else:
        $HintLabel.text = "Mochila cheia — libere espaço"
        $HintLabel.visible = true

func _draw() -> void:
    var pulse := 0.5 + 0.5 * sin(beacon_phase)
    draw_circle(Vector2(0, 0), 31.0 + pulse * 4.0, Color(0.9, 0.2, 0.12, 0.10 + pulse * 0.08))
    draw_rect(Rect2(-20, -13, 40, 26), Color("#485342"))
    draw_rect(Rect2(-20, -13, 40, 26), Color("#c4a36a"), false, 2.0)
    draw_rect(Rect2(-4, -13, 8, 26), Color("#c4a36a"))
    draw_line(Vector2(-20, 0), Vector2(20, 0), Color("#d7bd83"), 2.0)
    draw_circle(Vector2(0, -1), 4.0, Color("#c64b32"))
