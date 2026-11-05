extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const RESOURCE_SCENE := preload("res://scenes/resource_node.tscn")
const ANIMAL_SCRIPT := preload("res://scripts/animal.gd")
const AIRDROP_SCENE := preload("res://scenes/airdrop.tscn")

var player: CharacterBody2D
var health_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var status_label: Label
var resource_label: Label
var message_label: Label
var time_label: Label
var biome_label: Label
var weather_overlay: ColorRect
var airdrop_timer: Timer
var build_manager: Node2D
var current_biome := "floresta"
var day_night_overlay: ColorRect
var damage_flash: ColorRect
var vignette_material: ShaderMaterial
var inventory_panel: PanelContainer
var inventory_slots: Array[Button] = []
var inventory_status: Label
var last_health := 100.0
var message_timer := 0.0

const PANEL_COLOR := Color("#1a1512")
const PANEL_BORDER := Color("#8a5a2b")
const TEXT_COLOR := Color("#ead9bd")

func _ready() -> void:
    randomize()
    if not GameManager.load_game():
        GameManager.reset_new_game()
    _create_world()
    _create_player()
    build_manager = Node2D.new()
    build_manager.set_script(load("res://scripts/build_manager.gd"))
    add_child(build_manager)
    var weather_layer := CanvasLayer.new()
    weather_layer.set_script(load("res://scripts/weather_overlay.gd"))
    add_child(weather_layer)
    _create_hud()
    _spawn_resources()
    _spawn_animals()
    GameManager.stats_changed.connect(_refresh_hud)
    GameManager.player_died.connect(_on_player_death)
    WeatherManager.weather_changed.connect(_on_weather_changed)
    airdrop_timer = Timer.new()
    airdrop_timer.wait_time = 180.0
    airdrop_timer.one_shot = false
    airdrop_timer.timeout.connect(_spawn_airdrop)
    add_child(airdrop_timer)
    airdrop_timer.start()
    _refresh_hud()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("open_inventory"):
        _toggle_inventory()

func _process(delta: float) -> void:
    GameManager.consume_survival(delta)
    _update_weather(delta)
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
    for i in range(14):
        var fiber = RESOURCE_SCENE.instantiate()
        fiber.resource_type = "fiber"
        fiber.amount = randi_range(1, 2)
        fiber.position = Vector2(randf_range(-1100, 1100), randf_range(-850, 850))
        add_child(fiber)
    for i in range(8):
        var hide_node = RESOURCE_SCENE.instantiate()
        hide_node.resource_type = "hide"
        hide_node.amount = 1
        hide_node.position = Vector2(randf_range(-1000, 1000), randf_range(-800, 800))
        add_child(hide_node)

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
    var vignette_mat := ShaderMaterial.new()
    vignette_mat.shader = vignette_shader
    vignette.material = vignette_mat
    vignette_material = vignette_mat
    hud.add_child(vignette)

    day_night_overlay = ColorRect.new()
    day_night_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    day_night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    day_night_overlay.color = Color(0.04, 0.07, 0.16, 0.0)
    hud.add_child(day_night_overlay)

    weather_overlay = ColorRect.new()
    weather_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    weather_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    weather_overlay.color = Color(0.45, 0.72, 0.95, 0.0)
    hud.add_child(weather_overlay)

    damage_flash = ColorRect.new()
    damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    damage_flash.color = Color(0.8, 0.0, 0.0, 0.0)
    hud.add_child(damage_flash)

    var resources_panel := _make_panel(hud, Vector2(18,18), Vector2(270,72))
    var resources_box := VBoxContainer.new()
    resources_box.add_child(_make_label("MOCHILA  /  RECURSOS", 13, Color("#c69a61")))
    resource_label = _make_label("Madeira: 0     Pedra: 0", 16)
    resources_box.add_child(resource_label)
    resources_panel.add_child(resources_box)

    var phase_panel := _make_panel(hud, Vector2(530,18), Vector2(220,48))
    time_label = _make_label("DIA 01  •  DIA", 18)
    time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    phase_panel.add_child(time_label)
    var biome_panel := _make_panel(hud, Vector2(770,18), Vector2(220,48))
    biome_label = _make_label("BIOMA: FLORESTA", 15, Color("#c6d69a"))
    biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    biome_panel.add_child(biome_label)

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
    help_panel.add_child(_make_label("WASD: mover   •   E: coletar   •   Q: defesa   •   I: mochila", 12))

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

    var load_button := Button.new()
    load_button.text = "CARREGAR"
    load_button.position = Vector2(1160,68)
    load_button.custom_minimum_size = Vector2(100,38)
    load_button.pressed.connect(_load_game)
    hud.add_child(load_button)

    var build_button := Button.new()
    build_button.text = "CONSTRUIR FUNDAÇÃO"
    build_button.position = Vector2(830, 650)
    build_button.custom_minimum_size = Vector2(190, 42)
    build_button.pressed.connect(_toggle_build_mode)
    hud.add_child(build_button)

    var inventory_button := Button.new()
    inventory_button.text = "MOCHILA (I)"
    inventory_button.position = Vector2(1050,575)
    inventory_button.custom_minimum_size = Vector2(190,42)
    inventory_button.pressed.connect(_toggle_inventory)
    hud.add_child(inventory_button)

    _create_inventory_panel(hud)

func _create_inventory_panel(hud: CanvasLayer) -> void:
    inventory_panel = PanelContainer.new()
    inventory_panel.position = Vector2(350, 35)
    inventory_panel.custom_minimum_size = Vector2(580, 650)
    inventory_panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#17130f")
    style.border_color = Color("#b17a3e")
    style.set_border_width_all(3)
    style.set_corner_radius_all(8)
    style.content_margin_left = 16
    style.content_margin_right = 16
    style.content_margin_top = 14
    style.content_margin_bottom = 14
    inventory_panel.add_theme_stylebox_override("panel", style)
    hud.add_child(inventory_panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    inventory_panel.add_child(content)
    var header := HBoxContainer.new()
    header.add_child(_make_label("MOCHILA  •  20 ESPAÇOS", 20, Color("#d5a15d")))
    var close_button := Button.new()
    close_button.text = "FECHAR"
    close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    close_button.pressed.connect(_toggle_inventory)
    header.add_child(close_button)
    content.add_child(header)

    var grid := GridContainer.new()
    grid.columns = 5
    grid.add_theme_constant_override("h_separation", 7)
    grid.add_theme_constant_override("v_separation", 7)
    for i in range(GameManager.INVENTORY_CAPACITY):
        var slot := Button.new()
        slot.custom_minimum_size = Vector2(88, 55)
        slot.text = "Vazio"
        slot.focus_mode = Control.FOCUS_NONE
        grid.add_child(slot)
        inventory_slots.append(slot)
    content.add_child(grid)

    inventory_status = _make_label("Ferramenta equipada: Machado de pedra", 14)
    content.add_child(inventory_status)
    var craft_pickaxe_button := Button.new()
    craft_pickaxe_button.text = "PICARETA DE PEDRA  •  3 MADEIRAS + 2 PEDRAS"
    craft_pickaxe_button.custom_minimum_size = Vector2(0, 38)
    craft_pickaxe_button.pressed.connect(_craft_stone_pickaxe)
    content.add_child(craft_pickaxe_button)

    var craft_button := Button.new()
    craft_button.text = "MACHADO DE METAL  •  5 MADEIRAS + 8 PEDRAS"
    craft_button.custom_minimum_size = Vector2(0, 38)
    craft_button.pressed.connect(_craft_metal_axe)
    content.add_child(craft_button)

    var craft_metal_pickaxe_button := Button.new()
    craft_metal_pickaxe_button.text = "PICARETA DE METAL  •  PICARETA + 5 MADEIRAS + 8 PEDRAS"
    craft_metal_pickaxe_button.custom_minimum_size = Vector2(0, 38)
    craft_metal_pickaxe_button.pressed.connect(_craft_metal_pickaxe)
    content.add_child(craft_metal_pickaxe_button)
    var craft_coat_button := Button.new()
    craft_coat_button.text = "CASACO  •  5 COUROS + 3 FIBRAS"
    craft_coat_button.custom_minimum_size = Vector2(0, 36)
    craft_coat_button.pressed.connect(_craft_coat)
    content.add_child(craft_coat_button)
    var craft_hat_button := Button.new()
    craft_hat_button.text = "CHAPÉU  •  5 FIBRAS + 2 MADEIRAS"
    craft_hat_button.custom_minimum_size = Vector2(0, 36)
    craft_hat_button.pressed.connect(_craft_sun_hat)
    content.add_child(craft_hat_button)
    var equip_coat_button := Button.new()
    equip_coat_button.text = "EQUIPAR / TIRAR CASACO"
    equip_coat_button.custom_minimum_size = Vector2(0, 34)
    equip_coat_button.pressed.connect(_equip_armor.bind("coat"))
    content.add_child(equip_coat_button)
    var equip_hat_button := Button.new()
    equip_hat_button.text = "EQUIPAR / TIRAR CHAPÉU"
    equip_hat_button.custom_minimum_size = Vector2(0, 34)
    equip_hat_button.pressed.connect(_equip_armor.bind("sun_hat"))
    content.add_child(equip_hat_button)
    content.add_child(_make_label("Machados/picaretas melhoram a coleta. Casaco protege na neve; chapéu protege no deserto.", 11, Color("#c69a61")))

func _on_weather_changed(weather: String) -> void:
    var messages := {
        "limpo": "O céu abriu. O clima está tranquilo.",
        "chuva": "Começou a chover. Seus movimentos estão um pouco mais lentos.",
        "tempestade": "TEMPestade! Visibilidade reduzida e animais detectam você de mais perto.",
        "nevoa": "Uma névoa densa cobre a região. Cuidado ao explorar."
    }
    _show_message(str(messages.get(weather, "O clima mudou.")))

func _toggle_build_mode() -> void:
    if is_instance_valid(build_manager) and build_manager.has_method("toggle_build_mode"):
        build_manager.toggle_build_mode()
        _show_message("Modo construção: toque/clique no mapa para colocar fundações. ESC cancela.")

func _toggle_inventory() -> void:
    if inventory_panel:
        inventory_panel.visible = not inventory_panel.visible
        if inventory_panel.visible:
            _refresh_inventory_ui()

func _refresh_inventory_ui() -> void:
    if not inventory_panel:
        return
    for i in range(inventory_slots.size()):
        var slot_data := GameManager.get_inventory_slot(i)
        if slot_data.is_empty():
            inventory_slots[i].text = "Vazio"
        else:
            var item_id := str(slot_data.get("id", ""))
            inventory_slots[i].text = "%s\n×%d" % [GameManager.get_item_name(item_id), int(slot_data.get("count", 0))]
    if inventory_status:
        var armor_name := "Nenhuma"
        if GameManager.equipped_armor == "coat":
            armor_name = "Casaco"
        elif GameManager.equipped_armor == "sun_hat":
            armor_name = "Chapéu"
        inventory_status.text = "Ferramenta: %s  •  Proteção: %s" % [GameManager.get_item_name(GameManager.equipped_tool), armor_name]

func _craft_stone_pickaxe() -> void:
    if GameManager.craft_stone_pickaxe():
        _show_message("Picareta de pedra fabricada e equipada!")
    else:
        _show_message("Precisa de 3 madeiras e 2 pedras.")
    _refresh_inventory_ui()
    _refresh_hud()

func _craft_metal_axe() -> void:
    if GameManager.craft_metal_axe():
        _show_message("Machado de metal fabricado e equipado!")
    else:
        _show_message("Precisa de 5 madeiras e 8 pedras.")
    _refresh_inventory_ui()
    _refresh_hud()

func _craft_metal_pickaxe() -> void:
    if GameManager.craft_metal_pickaxe():
        _show_message("Picareta de metal fabricada e equipada!")
    else:
        _show_message("Precisa de picareta de pedra, 5 madeiras e 8 pedras.")
    _refresh_inventory_ui()
    _refresh_hud()

func _craft_coat() -> void:
    if GameManager.craft_coat():
        _show_message("Casaco fabricado! Equipe-o na mochila.")
    else:
        _show_message("Precisa de 5 couros e 3 fibras.")
    _refresh_inventory_ui()

func _craft_sun_hat() -> void:
    if GameManager.craft_sun_hat():
        _show_message("Chapéu fabricado! Equipe-o na mochila.")
    else:
        _show_message("Precisa de 5 fibras e 2 madeiras.")
    _refresh_inventory_ui()

func _equip_armor(item_id: String) -> void:
    if GameManager.equip_armor(item_id):
        _show_message("Proteção atualizada.")
    else:
        _show_message("Fabrique essa roupa primeiro.")
    _refresh_inventory_ui()

func _get_biome_at(position: Vector2) -> String:
    if position.y < -700.0:
        return "neve"
    if position.x > 850.0:
        return "deserto"
    return "floresta"

func _update_weather(delta: float) -> void:
    if not is_instance_valid(player):
        return
    var biome := _get_biome_at(player.global_position)
    GameManager.apply_climate_damage(biome, delta)
    if biome != current_biome:
        current_biome = biome
        match biome:
            "neve":
                _show_message("Região gelada: equipe um casaco para se proteger.")
            "deserto":
                _show_message("Região quente: equipe um chapéu para se proteger.")
            _:
                _show_message("Você voltou à floresta.")
    if biome_label:
        biome_label.text = "BIOMA: " + biome.to_upper()
    if weather_overlay:
        if biome == "neve":
            weather_overlay.color = Color(0.55, 0.78, 1.0, 0.10)
        elif biome == "deserto":
            weather_overlay.color = Color(1.0, 0.62, 0.25, 0.08)
        else:
            weather_overlay.color = Color(0.2, 0.3, 0.2, 0.0)

func _spawn_airdrop() -> void:
    if not is_instance_valid(player):
        return
    var direction := Vector2.RIGHT.rotated(randf_range(-PI, PI))
    var position_drop := player.global_position + direction * randf_range(480.0, 700.0)
    position_drop.x = clampf(position_drop.x, -1500.0, 1500.0)
    position_drop.y = clampf(position_drop.y, -950.0, 950.0)
    var drop := AIRDROP_SCENE.instantiate()
    drop.global_position = position_drop
    add_child(drop)
    for i in range(3):
        var animal := CharacterBody2D.new()
        animal.set_script(ANIMAL_SCRIPT)
        var offset := Vector2.RIGHT.rotated(randf_range(-PI, PI)) * randf_range(90.0, 190.0)
        animal.position = position_drop + offset
        add_child(animal)
    _show_message("SUPRIMENTOS DETECTADOS! Um lançamento chegou ao mapa.")

func _on_player_death() -> void:
    if not is_instance_valid(player):
        return
    var corpse_scene = load("res://scenes/player_corpse.tscn")
    if corpse_scene:
        var corpse = corpse_scene.instantiate()
        corpse.saved_items = GameManager.clear_inventory()
        corpse.global_position = player.global_position
        add_child(corpse)
    GameManager.health = 100.0
    GameManager.hunger = 100.0
    GameManager.thirst = 100.0
    GameManager.death_reported = false
    player.global_position = Vector2.ZERO
    _show_message("Você voltou à base. Seus itens ficaram no local da queda.")
    _refresh_hud()

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
        resource_label.text = "Madeira: %d     Pedra: %d" % [GameManager.wood, GameManager.stone]
    _refresh_inventory_ui()

func _save_game() -> void:
    GameManager.save_game()
    _show_message("Progresso salvo!")

func _load_game() -> void:
    if GameManager.load_game():
        _show_message("Progresso carregado!")
        _refresh_hud()
    else:
        _show_message("Ainda não existe um salvamento.")

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
