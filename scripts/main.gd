extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const RESOURCE_SCENE := preload("res://scenes/resource_node.tscn")
var player: CharacterBody2D
var status_label: Label
var message_label: Label
var time_label: Label
var day_night_overlay: ColorRect
var message_timer := 0.0

func _ready() -> void:
    GameManager.reset_new_game()
    _create_world()
    _create_player()
    _create_hud()
    _spawn_resources()
    GameManager.stats_changed.connect(_refresh_hud)
    _refresh_hud()

func _process(delta: float) -> void:
    GameManager.consume_survival(delta)
    message_timer = maxf(0.0, message_timer - delta)
    if message_timer <= 0.0 and message_label:
        message_label.text = ""
    var phase := fposmod(GameManager.elapsed / 180.0, 1.0)
    var darkness := 0.0
    if phase > 0.68:
        darkness = clampf((phase - 0.68) / 0.20, 0.0, 0.42)
    if day_night_overlay:
        day_night_overlay.color = Color(0.04, 0.07, 0.16, darkness)
    if time_label:
        time_label.text = "DIA %d  •  %s" % [GameManager.day, "NOITE" if darkness > 0.12 else "DIA"]

func _create_world() -> void:
    var ground := Polygon2D.new()
    ground.polygon = PackedVector2Array([Vector2(-1800,-1200), Vector2(1800,-1200), Vector2(1800,1200), Vector2(-1800,1200)])
    ground.color = Color("314f3b")
    add_child(ground)
    for i in range(120):
        var pebble := Polygon2D.new()
        pebble.polygon = PackedVector2Array([Vector2(-2,-1), Vector2(3,-2), Vector2(5,2), Vector2(-3,3)])
        pebble.position = Vector2(randf_range(-1100, 1100), randf_range(-850, 850))
        pebble.color = Color("496449") if i % 2 == 0 else Color("3c5a43")
        add_child(pebble)

func _create_player() -> void:
    player = PLAYER_SCENE.instantiate()
    add_child(player)
    var camera := Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    player.add_child(camera)

func _spawn_resources() -> void:
    randomize()
    for i in range(22):
        var tree = RESOURCE_SCENE.instantiate()
        tree.resource_type = "wood"
        tree.amount = randi_range(1, 3)
        tree.position = Vector2(randf_range(-950, 950), randf_range(-700, 700))
        add_child(tree)
    for i in range(16):
        var rock = RESOURCE_SCENE.instantiate()
        rock.resource_type = "stone"
        rock.amount = randi_range(1, 2)
        rock.position = Vector2(randf_range(-950, 950), randf_range(-700, 700))
        add_child(rock)

func _create_hud() -> void:
    var hud := CanvasLayer.new()
    add_child(hud)
    day_night_overlay = ColorRect.new()
    day_night_overlay.color = Color(0.04, 0.07, 0.16, 0.0)
    day_night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    day_night_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    day_night_overlay.z_index = -1
    hud.add_child(day_night_overlay)
    var panel := PanelContainer.new()
    panel.position = Vector2(18, 18)
    panel.custom_minimum_size = Vector2(310, 112)
    hud.add_child(panel)
    var layout := VBoxContainer.new()
    panel.add_child(layout)
    time_label = Label.new()
    time_label.add_theme_font_size_override("font_size", 18)
    layout.add_child(time_label)
    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 15)
    layout.add_child(status_label)
    var help := Label.new()
    help.text = "WASD: mover  •  E: coletar recurso"
    help.position = Vector2(20, 660)
    help.add_theme_font_size_override("font_size", 16)
    hud.add_child(help)
    message_label = Label.new()
    message_label.position = Vector2(20, 620)
    message_label.add_theme_font_size_override("font_size", 18)
    hud.add_child(message_label)
    var save_button := Button.new()
    save_button.text = "Salvar"
    save_button.position = Vector2(1130, 22)
    save_button.pressed.connect(_save_game)
    hud.add_child(save_button)

func _refresh_hud() -> void:
    if status_label:
        status_label.text = "Vida: %d   Fome: %d   Sede: %d\nMadeira: %d   Pedra: %d" % [roundi(GameManager.health), roundi(GameManager.hunger), roundi(GameManager.thirst), GameManager.wood, GameManager.stone]

func _save_game() -> void:
    GameManager.save_game()
    _show_message("Progresso salvo!")

func _show_message(text: String) -> void:
    message_label.text = text
    message_timer = 2.5
