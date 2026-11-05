extends StaticBody2D

var saved_items: Dictionary = {}
var player_in_range := false

func _ready() -> void:
    add_to_group("player_corpses")
    $InteractArea.body_entered.connect(_on_body_entered)
    $InteractArea.body_exited.connect(_on_body_exited)
    $HintLabel.text = "[E] Recuperar mochila"
    $HintLabel.visible = false
    var glow := create_tween().set_loops()
    glow.tween_property(self, "modulate", Color(1.15, 0.9, 0.72), 0.55)
    glow.tween_property(self, "modulate", Color.WHITE, 0.55)

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
        _recover_items()
        get_viewport().set_input_as_handled()

func _recover_items() -> void:
    var remaining: Dictionary = {}
    for item_id in saved_items:
        var quantity := int(saved_items[item_id])
        if not GameManager.add_item(item_id, quantity):
            remaining[item_id] = quantity
    saved_items = remaining
    if saved_items.is_empty():
        queue_free()
    else:
        $HintLabel.text = "Mochila cheia — libere espaço"
