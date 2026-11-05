extends Node2D

const FLOOR_SCENE: PackedScene = preload("res://scenes/floor.tscn")
const WALL_SCENE: PackedScene = preload("res://scenes/wall.tscn")
const CAMPFIRE_SCENE: PackedScene = preload("res://scenes/campfire.tscn")
const PREVIEW_SCENE: PackedScene = preload("res://scenes/build_preview.tscn")
const TILE_SIZE := 64.0

const BUILDABLES := {
    "fundacao": {"scene": "floor", "cost": {"wood": 2}, "size": Vector2(64, 64)},
    "parede": {"scene": "wall", "cost": {"wood": 3, "stone": 1}, "size": Vector2(60, 20)},
    "fogueira": {"scene": "campfire", "cost": {"wood": 5, "stone": 3}, "size": Vector2(48, 48)}
}

var building := false
var current_item := "fundacao"
var preview: Node2D

func _ready() -> void:
    _restore_buildings()
    preview = PREVIEW_SCENE.instantiate() as Node2D
    add_child(preview)
    preview.call("configure", Vector2(64, 64), Color(0.35, 0.9, 0.4, 0.48))
    preview.visible = false

func _restore_buildings() -> void:
    for saved_floor in GameManager.built_floors:
        var restored_floor := FLOOR_SCENE.instantiate() as Node2D
        restored_floor.global_position = Vector2(float(saved_floor.get("x", 0.0)), float(saved_floor.get("y", 0.0)))
        get_tree().current_scene.call_deferred("add_child", restored_floor)
    for saved in GameManager.built_objects:
        var scene := _scene_for(str(saved.get("kind", "")))
        if scene == null:
            continue
        var obj := scene.instantiate() as Node2D
        obj.global_position = Vector2(float(saved.get("x", 0.0)), float(saved.get("y", 0.0)))
        get_tree().current_scene.call_deferred("add_child", obj)

func _scene_for(kind: String) -> PackedScene:
    match kind:
        "fundacao": return FLOOR_SCENE
        "parede": return WALL_SCENE
        "fogueira": return CAMPFIRE_SCENE
        _: return null

func select_building(kind: String) -> void:
    if not BUILDABLES.has(kind):
        return
    current_item = kind
    building = true
    preview.visible = true
    var size: Vector2 = BUILDABLES[kind]["size"]
    preview.call("configure", size, Color(0.35, 0.9, 0.4, 0.48))
    print("[Construção] Selecionado: ", kind)

func toggle_build_mode() -> void:
    if building:
        cancel_build_mode()
    else:
        select_building(current_item)

func cancel_build_mode() -> void:
    building = false
    if is_instance_valid(preview):
        preview.visible = false

func _process(_delta: float) -> void:
    if not building:
        return
    var target := _snapped_position(get_global_mouse_position())
    preview.global_position = target
    preview.call("set_valid", _can_place(current_item, target))

func _unhandled_input(event: InputEvent) -> void:
    if not building:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        cancel_build_mode()
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _place_selected(_snapped_position(get_global_mouse_position()))
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch and event.pressed:
        var world_position: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
        _place_selected(_snapped_position(world_position))
        get_viewport().set_input_as_handled()

func _snapped_position(position: Vector2) -> Vector2:
    return Vector2(roundf(position.x / TILE_SIZE) * TILE_SIZE, roundf(position.y / TILE_SIZE) * TILE_SIZE)

func _can_place(kind: String, position: Vector2) -> bool:
    if not BUILDABLES.has(kind):
        return false
    var cost: Dictionary = BUILDABLES[kind]["cost"]
    for item_id in cost:
        if GameManager.get_item_count(str(item_id)) < int(cost[item_id]):
            return false
    if kind == "fundacao":
        for existing in get_tree().get_nodes_in_group("floors"):
            if is_instance_valid(existing) and existing.global_position.distance_to(position) < 8.0:
                return false
    else:
        var has_floor := false
        for floor_node in get_tree().get_nodes_in_group("floors"):
            if is_instance_valid(floor_node) and floor_node.global_position.distance_to(position) < 42.0:
                has_floor = true
                break
        if not has_floor:
            return false
        for group_name in ["built_walls", "campfires"]:
            for existing in get_tree().get_nodes_in_group(group_name):
                if is_instance_valid(existing) and existing.global_position.distance_to(position) < 28.0:
                    return false
    return true

func _place_selected(position: Vector2) -> void:
    if not _can_place(current_item, position):
        print("[Construção] Recursos insuficientes ou local inválido. Paredes e fogueiras precisam de fundação.")
        return
    var data: Dictionary = BUILDABLES[current_item]
    for item_id in data["cost"]:
        if not GameManager.remove_item(str(item_id), int(data["cost"][item_id])):
            return
    var scene := _scene_for(current_item)
    if scene == null:
        return
    var obj := scene.instantiate() as Node2D
    obj.global_position = position
    get_tree().current_scene.add_child(obj)
    if current_item == "fundacao":
        GameManager.built_floors.append({"x": position.x, "y": position.y})
    else:
        GameManager.built_objects.append({"kind": current_item, "x": position.x, "y": position.y})
    GameManager.save_game()
    print("[Construção] Construído: ", current_item)
