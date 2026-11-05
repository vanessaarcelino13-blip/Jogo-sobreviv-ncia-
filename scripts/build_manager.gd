extends Node2D

const FLOOR_SCENE := preload("res://scenes/floor.tscn")
const TILE_SIZE := 64.0

var building := false
var preview: Polygon2D

func _ready() -> void:
    for saved_floor in GameManager.built_floors:
        var restored_floor := FLOOR_SCENE.instantiate()
        restored_floor.global_position = Vector2(float(saved_floor.get("x", 0.0)), float(saved_floor.get("y", 0.0)))
        get_tree().current_scene.call_deferred("add_child", restored_floor)
    preview = Polygon2D.new()
    preview.polygon = PackedVector2Array([
        Vector2(-30, -30), Vector2(30, -30),
        Vector2(30, 30), Vector2(-30, 30)
    ])
    preview.color = Color(0.55, 0.85, 0.45, 0.42)
    preview.z_index = 5
    preview.visible = false
    add_child(preview)

func toggle_build_mode() -> void:
    building = not building
    preview.visible = building
    if building:
        print("[Construção] Toque/clique para colocar uma fundação. ESC cancela.")
    else:
        print("[Construção] Modo de construção encerrado.")

func _process(_delta: float) -> void:
    if building:
        preview.global_position = _snapped_position(get_global_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
    if not building:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        toggle_build_mode()
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _place_floor(_snapped_position(get_global_mouse_position()))
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch and event.pressed:
        var world_position := get_viewport().get_canvas_transform().affine_inverse() * event.position
        _place_floor(_snapped_position(world_position))
        get_viewport().set_input_as_handled()

func _snapped_position(position: Vector2) -> Vector2:
    return Vector2(
        roundf(position.x / TILE_SIZE) * TILE_SIZE,
        roundf(position.y / TILE_SIZE) * TILE_SIZE
    )

func _place_floor(position: Vector2) -> void:
    for existing in get_tree().get_nodes_in_group("floors"):
        if is_instance_valid(existing) and existing.global_position.distance_to(position) < 8.0:
            print("[Construção] Já existe uma fundação nesse espaço.")
            return
    if not GameManager.remove_item("wood", 2):
        print("[Construção] Você precisa de 2 madeiras.")
        return
    var floor := FLOOR_SCENE.instantiate()
    floor.global_position = position
    get_tree().current_scene.add_child(floor)
    GameManager.built_floors.append({"x": position.x, "y": position.y})
    GameManager.save_game()
    print("[Construção] Fundação colocada.")
