extends Node3D

const PIECE_SCRIPT = preload("res://scripts/build_piece_3d.gd")
const GRID_SIZE := 2.0
const WALL_WOOD_COST := 4
const FOUNDATION_WOOD_COST := 3
const FOUNDATION_STONE_COST := 2

var build_mode := ""
var preview: MeshInstance3D
var preview_valid := false
var player: Node3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func start_building(kind: String) -> void:
	if kind not in ["wall", "foundation"]:
		return
	cancel_building()
	build_mode = kind
	preview = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 0.25, 2.0) if kind == "foundation" else Vector3(2.0, 2.0, 0.2)
	preview.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.85, 0.35, 0.45)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview.material_override = material
	add_child(preview)
	preview_valid = false

func _process(_delta: float) -> void:
	if build_mode == "" or not is_instance_valid(preview):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var screen_point := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(screen_point)
	var end := origin + camera.project_ray_normal(screen_point) * 500.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		preview_valid = false
		return
	var p: Vector3 = hit.position
	preview.global_position = Vector3(round(p.x / GRID_SIZE) * GRID_SIZE, 0.0, round(p.z / GRID_SIZE) * GRID_SIZE)
	preview_valid = not _overlaps_obstacle(preview.global_position)

func place_from_player() -> void:
	if build_mode == "" or not is_instance_valid(preview):
		return
	if is_instance_valid(player):
		var target := player.global_position + (-player.global_basis.z * 3.0)
		preview.global_position = Vector3(round(target.x / GRID_SIZE) * GRID_SIZE, 0.0, round(target.z / GRID_SIZE) * GRID_SIZE)
		preview_valid = not _overlaps_obstacle(preview.global_position)
	_place()

func _unhandled_input(event: InputEvent) -> void:
	if build_mode == "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_place()
	elif event.is_action_pressed("ui_cancel"):
		cancel_building()

func _place() -> void:
	if not preview_valid:
		return
	var wood_cost := WALL_WOOD_COST if build_mode == "wall" else FOUNDATION_WOOD_COST
	var stone_cost := 0 if build_mode == "wall" else FOUNDATION_STONE_COST
	if not has_node("/root/GameManager"):
		return
	if GameManager.get_item_count("wood") < wood_cost or GameManager.get_item_count("stone") < stone_cost:
		print("Materiais insuficientes para construir.")
		return
	GameManager.remove_item("wood", wood_cost)
	if stone_cost > 0:
		GameManager.remove_item("stone", stone_cost)
	var piece := StaticBody3D.new()
	piece.set_script(PIECE_SCRIPT)
	piece.piece_type = build_mode
	piece.global_position = preview.global_position
	get_tree().current_scene.add_child(piece)
	GameManager.stats_changed.emit()
	print("Construção concluída: ", build_mode)
	cancel_building()

func _overlaps_obstacle(at_position: Vector3) -> bool:
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.85, 2.0, 0.3) if build_mode == "wall" else Vector3(1.85, 0.3, 1.85)
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis.IDENTITY, at_position + Vector3.UP * (1.0 if build_mode == "wall" else 0.15))
	params.collision_mask = 2
	params.exclude = [preview.get_rid()]
	return not get_world_3d().direct_space_state.intersect_shape(params, 8).is_empty()

func cancel_building() -> void:
	build_mode = ""
	preview_valid = false
	if is_instance_valid(preview):
		preview.queue_free()
	preview = null
