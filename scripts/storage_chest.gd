extends StaticBody2D

@export var chest_id: String = "base_chest"
var player_in_range := false

func _ready() -> void:
    add_to_group("storage_chests")
    $InteractArea.body_entered.connect(_on_body_entered)
    $InteractArea.body_exited.connect(_on_body_exited)
    $HintLabel.visible = false

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
        var ui: Node = load("res://scenes/storage_ui.tscn").instantiate()
        ui.set("chest_id", chest_id)
        get_tree().current_scene.add_child(ui)
        get_tree().paused = true
        get_viewport().set_input_as_handled()
