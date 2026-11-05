extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const RESOURCE_SCENE := preload("res://scenes/resource_node.tscn")
const ANIMAL_SCRIPT := preload("res://scripts/animal.gd")

var player: CharacterBody2D
var health_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var status_label: Label
var resource_label: Label
var message_label: Label
var time_label: Label
var day_night_overlay: ColorRect
var damage_flash: ColorRect
var vignette_material: ShaderMaterial
var last_health := 100.0
var message_timer := 0.0

const PANEL_COLOR := Color("#1a1512")
const PANEL_BORDER := Color("#8a5a2b")
const TEXT_COLOR := Color("#ead9bd")

func _ready() -> void:
    randomize()
    GameManager.reset_new_game()
    _create_world()
    _create_player()
    _create_hud()
    _spawn_resources()
    _spawn_animals()
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
        time_label.text = "DIA %02d   •   %s" % [GameManager.day, "NOITE" if darkness > 0.12 else "DIA"]
    _update_low_health_vignette()

func _create_world() -> void:
    var ground := Polygon2D.new()
    ground.polygon = PackedVector2Array([Vector2(-1800,-1200), Vector2(1800,-1200), Vector2(1800,1200), Vector2(-1800,1200)])
    ground.color = Color("#354632")
    add_child(ground)

    # Camadas de manchas de terra e vegetação criadas no próprio Godot.
    for i in range(170):
        var dirt := Polygon2D.new()
        var w := randf_range(18.0, 55.0)
        var h := randf_range(9.0, 25.0)
        dirt.polygon = PackedVector2Array([Vector2(-w,0), Vector2(-w*0.55,-h), Vector2(w*0.65,-h*0.7), Vector2(w,2), Vector2(w*0.35,h), Vector2(-w*0.7,h*0.6)])
        dirt.position = Vector2(randf_range(-1500,1500), randf_range(-1000,1000))
        dirt.color = [Color("#514a35"), Color("#454331"), Color("#5b5038")][i % 3]
        dirt.z_index = 1
        add_child(dirt)

    for i in range(1500):
        var grass := Polygon2D.new()
        var x := randf_range(-3.0, 3.0)
        grass.polygon = PackedVector2Array([Vector2(-1.8,2.5), Vector2(x,-4.0), Vector2(2.2,2.5)])
        grass.position = Vector2(randf_range(-1750,1750), randf_range(-1150,1150))
        grass.color = [Color("#60734a"), Color("#718052"), Color("#465b3b"), Color("#84905a")][i % 4]
        grass.z_index = 2
        add_child(grass)

    for i in range(180):
        var pebble := Polygon2D.new()
        pebble.polygon = PackedVector2Array([Vector2(-3,-1), Vector2(3,-2), Vector2(6,2), Vector2(-2,4)])
        pebble.position = Vector2(randf_range(-1650,1650), randf_range(-1050,1050))
        pebble.color = Color("#77715e") if i % 2 == 0 else Color("#555b48")
        pebble.z_index = 3
        add_child(pebble)

func _create_player() -> void:
    player = PLAYER_SCENE.instantiate()
    add_child(player)

func _spawn_resources() -> void:
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

func _spawn_animals() -> void:
    for i in range(9):
        var animal := CharacterBody2D.new()
        animal.set_script(ANIMAL_SCRIPT)
        animal.position = Vector2(randf_range(-800, 800), randf_range(-600, 600))
        add_child(animal)

func _make_panel(parent: Node, position: Vector2, size: Vector2) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.position = position
    panel.custom_minimum_size = size
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL_COLOR
    style.border_color = PANEL_BORDER
    style.set_border_width_all(2)
    style.set_corner_radius_all(5)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 9
    style.content_margin_bottom = 9
    panel.add_theme_stylebox_override("panel", style)
    parent.add_child(panel)
    return panel

func _make_label(text_value: String, font_size: int, color: Color = TEXT_COLOR) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label

func _make_bar(fill_color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(240, 15)
    bar.show_percentage = false
    bar.min_value = 0
    bar.max_value = 100
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color("#2b241d")
    bg.border_color = Color("#080706")
    bg.set_border_width_all(2)
    bg.set_corner_radius_all(4)
    var fill := StyleBoxFlat.new()
    fill.bg_color = fill_color
    fill.set_corner_radius_all(3)
    bar.add_theme_stylebox_override("background", bg)
    bar.add_theme_stylebox_override("fill", fill)
    return bar

func _create_hud() -> void:
    var hud := CanvasLayer.new()
    hud.layer = 10
    add_child(hud)

    # Vinheta suave nas bordas da tela.
    var vignette := ColorRect.new()
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vignette.color = Color.WHITE
    var vignette_shader := Shader.new()
    vignette_shader.code = """
shader_type canvas_item;
uniform vec4 cor_borda : source_color = vec4(0.0, 0.0, 0.0, 0.48);
void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float alpha = smoothstep(0.30, 0.78, dist) * cor_borda.a;
    COLOR = vec4(cor_borda.rgb, alpha);
}
"""
    var vignette_material := ShaderMaterial.new()
    vignette_material.shader = vignette_shader
    vignette.material = vignette_material
    self.vignette_material = vignette_material
    hud.add_child(vignette)

    # Escurecimento dinâmico de noite.
    day_night_overlay = ColorRect.new()
    day_night_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    day_night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    day_night_overlay.color = Color(0.04, 0.07, 0.16, 0.0)
    hud.add_child(day_night_overlay)

    damage_flash = ColorRect.new()
    damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    damage_flash.color = Color(0.8, 0.0, 0.0, 0.0)
    hud.add_child(damage_flash)

    var resources_panel := _make_panel(hud, Vector2(18,18), Vector2(270,72))
    var resources_box := VBoxContainer.new()
    resources_box.add_child(_make_label("MOCHILA  /  RECURSOS", 13, Color("#c69a61")))
    resource_label = _make_label("▰ Madeira: 0     ◆ Pedra: 0", 16)
    resources_box.add_child(resource_label)
    resources_panel.add_child(resources_box)

    var phase_panel := _make_panel(hud, Vector2(530,18), Vector2(220,48))
    time_label = _make_label("DIA 01  •  DIA", 18)
    time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    phase_panel.add_child(time_label)

    var survival_panel := _make_panel(hud, Vector2(18,520), Vector2(290,174))
    var survival_box := VBoxContainer.new()
    survival_box.add_child(_make_label("CONDIÇÃO DO SOBREVIVENTE", 13, Color("#c69a61")))
    survival_box.add_child(_make_label("VIDA", 12))
    health_bar = _make_bar(Color("#a83232"))
    survival_box.add_child(health_bar)
    survival_box.add_child(_make_label("FOME", 12))
    hunger_bar = _make_bar(Color("#8a5a2b"))
    survival_box.add_child(hunger_bar)
    survival_box.add_child(_make_label("SEDE", 12))
    thirst_bar = _make_bar(Color("#4a6b8c"))
    survival_box.add_child(thirst_bar)
    survival_panel.add_child(survival_box)

    var equipment_panel := _make_panel(hud, Vector2(930,590), Vector2(330,105))
    var equipment_box := VBoxContainer.new()
    equipment_box.add_child(_make_label("EQUIPAMENTO ATUAL", 12, Color("#c69a61")))
    equipment_box.add_child(_make_label("✦  Pulso de defesa", 17))
    var durability := ProgressBar.new()
    durability.custom_minimum_size = Vector2(285, 12)
    durability.show_percentage = false
    durability.value = 100
    var durability_fill := StyleBoxFlat.new()
    durability_fill.bg_color = Color("#66834a")
    durability_fill.set_corner_radius_all(3)
    durability.add_theme_stylebox_override("fill", durability_fill)
    equipment_box.add_child(durability)
    equipment_panel.add_child(equipment_box)

    var help_panel := _make_panel(hud, Vector2(330,650), Vector2(420,42))
    help_panel.add_child(_make_label("WASD: mover   •   E: coletar   •   Q: defesa", 13))

    message_label = _make_label("", 18, Color("#f2d8a8"))
    message_label.position = Vector2(390,590)
    message_label.size = Vector2(500,36)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_child(message_label)

    var pulse_button := Button.new()
    pulse_button.text = "PULSO DE DEFESA"
    pulse_button.position = Vector2(1050,520)
    pulse_button.custom_minimum_size = Vector2(190,48)
    pulse_button.pressed.connect(_use_player_pulse)
    hud.add_child(pulse_button)

    var save_button := Button.new()
    save_button.text = "SALVAR"
    save_button.position = Vector2(1160,18)
    save_button.custom_minimum_size = Vector2(100,42)
    save_button.pressed.connect(_save_game)
    hud.add_child(save_button)

func _use_player_pulse() -> void:
    if is_instance_valid(player) and player.has_method("use_pulse"):
        player.use_pulse()
        _show_message("Pulso ativado: os animais se afastaram!")

func _refresh_hud() -> void:
    if GameManager.health < last_health:
        _play_damage_feedback()
    last_health = GameManager.health
    if health_bar:
        health_bar.value = GameManager.health
        hunger_bar.value = GameManager.hunger
        thirst_bar.value = GameManager.thirst
    if resource_label:
        resource_label.text = "▰ Madeira: %d     ◆ Pedra: %d" % [GameManager.wood, GameManager.stone]

func _save_game() -> void:
    GameManager.save_game()
    _show_message("Progresso salvo!")

func _show_message(text_value: String) -> void:
    if message_label:
        message_label.text = text_value
        message_timer = 2.5

func _play_damage_feedback() -> void:
    if damage_flash:
        damage_flash.color = Color(0.8, 0.0, 0.0, 0.28)
        var flash_tween := create_tween()
        flash_tween.tween_property(damage_flash, "color:a", 0.0, 0.48)
    if is_instance_valid(player):
        var camera := player.get_node_or_null("Camera2D")
        if camera and camera.has_method("shake"):
            camera.shake(0.22, 5.0)

func _update_low_health_vignette() -> void:
    if not vignette_material:
        return
    var health_ratio := clampf(GameManager.health / 100.0, 0.0, 1.0)
    var extra_dark := 0.0
    if health_ratio < 0.30:
        extra_dark = (0.30 - health_ratio) / 0.30
    vignette_material.set_shader_parameter("cor_borda", Color(0.0, 0.0, 0.0, 0.48 + extra_dark * 0.32))
