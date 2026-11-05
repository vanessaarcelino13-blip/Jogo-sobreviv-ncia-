extends CanvasLayer

var chest_id: String = "base_chest"
var inv_list: VBoxContainer
var chest_list: VBoxContainer

func _ready() -> void:
    add_to_group("storage_ui")
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_interface()
    _refresh()

func _build_interface() -> void:
    var shade := ColorRect.new()
    shade.color = Color(0, 0, 0, 0.72)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(shade)

    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-360, -245)
    panel.custom_minimum_size = Vector2(720, 490)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#1a1512")
    style.border_color = Color("#a8753e")
    style.set_border_width_all(3)
    style.set_corner_radius_all(8)
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 10)
    panel.add_child(layout)
    var title := Label.new()
    title.text = "BAÚ DE ARMAZENAMENTO"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    layout.add_child(title)

    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(columns)

    var left := VBoxContainer.new()
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(left)
    var inv_title := Label.new()
    inv_title.text = "MOCHILA — clique para guardar"
    left.add_child(inv_title)
    var inv_scroll := ScrollContainer.new()
    inv_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    left.add_child(inv_scroll)
    inv_list = VBoxContainer.new()
    inv_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inv_scroll.add_child(inv_list)

    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(right)
    var chest_title := Label.new()
    chest_title.text = "BAÚ — clique para retirar"
    right.add_child(chest_title)
    var chest_scroll := ScrollContainer.new()
    chest_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(chest_scroll)
    chest_list = VBoxContainer.new()
    chest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    chest_scroll.add_child(chest_list)

    var close := Button.new()
    close.text = "FECHAR"
    close.custom_minimum_size = Vector2(0, 42)
    close.pressed.connect(_close)
    layout.add_child(close)

func _refresh() -> void:
    _clear_list(inv_list)
    _clear_list(chest_list)
    var backpack := GameManager.get_inventory_contents()
    for item_id in backpack:
        var count := int(backpack[item_id])
        var button := Button.new()
        button.text = "%s × %d  → Guardar" % [GameManager.get_item_name(item_id), count]
        button.pressed.connect(_transfer_to_chest.bind(item_id, count))
        inv_list.add_child(button)
    var stored := StorageManager.get_chest(chest_id).duplicate()
    for item_id in stored:
        var count := int(stored[item_id])
        var button := Button.new()
        button.text = "%s × %d  ← Retirar" % [GameManager.get_item_name(item_id), count]
        button.pressed.connect(_transfer_to_bag.bind(item_id, count))
        chest_list.add_child(button)
    if inv_list.get_child_count() == 0:
        inv_list.add_child(_empty_label("Mochila vazia"))
    if chest_list.get_child_count() == 0:
        chest_list.add_child(_empty_label("Baú vazio"))

func _empty_label(value: String) -> Label:
    var label := Label.new()
    label.text = value
    return label

func _clear_list(list: VBoxContainer) -> void:
    for child in list.get_children():
        list.remove_child(child)
        child.queue_free()

func _transfer_to_chest(item_id: String, quantity: int) -> void:
    if GameManager.remove_item(item_id, quantity):
        StorageManager.save_to_chest(chest_id, item_id, quantity)
        GameManager.save_game()
    _refresh()

func _transfer_to_bag(item_id: String, quantity: int) -> void:
    if not GameManager.add_item(item_id, quantity):
        return
    StorageManager.take_from_chest(chest_id, item_id, quantity)
    GameManager.save_game()
    _refresh()

func _close() -> void:
    get_tree().paused = false
    queue_free()
