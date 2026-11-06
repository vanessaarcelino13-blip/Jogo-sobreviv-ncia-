extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player_3d.gd")
const ANIMAL_SCRIPT = preload("res://scripts/wild_animal_3d.gd")
const RESOURCE_SCRIPT = preload("res://scripts/resource_node_3d.gd")
const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")
const BUILD_SCRIPT = preload("res://scripts/build_system_3d.gd")

var player: CharacterBody3D
var build_manager: Node3D
var stats_label: Label
var inventory_label: Label
var survival_tick := 0.0
var navigation_region: NavigationRegion3D

func _ready() -> void:
	randomize()
	_build_environment()
	await _bake_navigation()
	_spawn_player()
	_spawn_resources()
	_spawn_animals()
	_spawn_build_manager()
	_build_hud()
	if has_node("/root/GameManager"):
		GameManager.stats_changed.connect(_refresh_hud)
	_refresh_hud()

func _process(delta: float) -> void:
	survival_tick += delta
	if survival_tick >= 1.0:
		survival_tick = 0.0
		if has_node("/root/GameManager"):
			GameManager.consume_survival(1.0)
	_refresh_hud()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#263b43")
	sky_material.sky_horizon_color = Color("#a4a17d")
	sky_material.ground_bottom_color = Color("#202b22")
	sky_material.ground_horizon_color = Color("#69745a")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b8c4a4")
	environment.ambient_light_energy = 0.7
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "NavigationRegion3D"
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.45
	nav_mesh.agent_height = 1.5
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.2
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav_mesh.filter_baking_aabb = AABB(Vector3(-50.0, -2.0, -50.0), Vector3(100.0, 8.0, 100.0))
	navigation_region.navigation_mesh = nav_mesh
	add_child(navigation_region)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100.0, 100.0)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("#40563a")
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	ground.position.y = -0.12
	navigation_region.add_child(ground)
	var ground_body := StaticBody3D.new()
	var ground_collision := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(100.0, 0.2, 100.0)
	ground_collision.shape = ground_box
	ground_collision.position.y = -0.1
	ground_body.add_child(ground_collision)
	navigation_region.add_child(ground_body)

	for i in range(55):
		var tree := StaticBody3D.new()
		tree.name = "TreeObstacle_%02d" % i
		tree.collision_layer = 2
		tree.collision_mask = 1
		var trunk_node := MeshInstance3D.new()
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.18
		trunk.bottom_radius = 0.28
		trunk.height = randf_range(1.8, 2.8)
		trunk_node.mesh = trunk
		var trunk_material := StandardMaterial3D.new()
		trunk_material.albedo_color = Color("#59412c")
		trunk_node.material_override = trunk_material
		trunk_node.position.y = trunk.height * 0.5
		tree.add_child(trunk_node)
		var trunk_collision := CollisionShape3D.new()
		var trunk_shape := CylinderShape3D.new()
		trunk_shape.radius = 0.32
		trunk_shape.height = trunk.height
		trunk_collision.shape = trunk_shape
		trunk_collision.position.y = trunk.height * 0.5
		tree.add_child(trunk_collision)
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = randf_range(0.8, 1.4)
		crown_mesh.height = crown_mesh.radius * 2.0
		crown.mesh = crown_mesh
		var crown_material := StandardMaterial3D.new()
		crown_material.albedo_color = Color("#29452d")
		crown.material_override = crown_material
		crown.position.y = trunk.height * 1.15
		tree.add_child(crown)
		tree.position = Vector3(randf_range(-45.0, 45.0), 0.0, randf_range(-45.0, 45.0))
		navigation_region.add_child(tree)

func _bake_navigation() -> void:
	if navigation_region and navigation_region.navigation_mesh:
		navigation_region.bake_navigation_mesh(true)
		await navigation_region.bake_finished
		print("Navegação do ambiente preparada.")

func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PLAYER_SCRIPT)
	var visual := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	visual.mesh = capsule
	visual.position.y = 0.85
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#78816a")
	visual.material_override = material
	player.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.7
	collision.shape = shape
	collision.position.y = 0.85
	player.add_child(collision)
	add_child(player)

func _spawn_resources() -> void:
	for i in range(18):
		var node := StaticBody3D.new()
		node.set_script(RESOURCE_SCRIPT)
		node.set("resource_kind", "Madeira" if i % 3 != 0 else "Fibra")
		node.position = Vector3(randf_range(-25.0, 25.0), 0.0, randf_range(-25.0, 25.0))
		add_child(node)
	for i in range(12):
		var node := StaticBody3D.new()
		node.set_script(RESOURCE_SCRIPT)
		node.set("resource_kind", "Pedra")
		node.position = Vector3(randf_range(-25.0, 25.0), 0.0, randf_range(-25.0, 25.0))
		add_child(node)

func _spawn_animals() -> void:
	var kinds := ["Lobo", "Urso", "Javali"]
	for i in range(8):
		var animal := CharacterBody3D.new()
		animal.set_script(ANIMAL_SCRIPT)
		animal.set("animal_kind", kinds[i % kinds.size()])
		animal.position = Vector3(randf_range(-22.0, 22.0), 0.0, randf_range(-22.0, 22.0))
		add_child(animal)

func _spawn_build_manager() -> void:
	build_manager = Node3D.new()
	build_manager.name = "BuildManager"
	build_manager.set_script(BUILD_SCRIPT)
	add_child(build_manager)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16.0, 14.0)
	panel.custom_minimum_size = Vector2(350.0, 112.0)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "SOBREVIVÊNCIA  |  DIA 1"
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)
	stats_label = Label.new()
	column.add_child(stats_label)
	inventory_label = Label.new()
	column.add_child(inventory_label)
	var help := Label.new()
	help.text = "WASD mover • E coletar • Espaço atacar • ESC cancelar"
	help.position = Vector2(18.0, 138.0)
	layer.add_child(help)

	var joystick = JOYSTICK_SCRIPT.new()
	joystick.position = Vector2(24.0, -174.0)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.size = Vector2(150.0, 150.0)
	joystick.vector_changed.connect(Callable(player, "set_touch_input"))
	layer.add_child(joystick)

	_add_action_button(layer, "COLETAR", Vector2(-154.0, -160.0), Callable(player, "collect_nearest_resource"))
	_add_action_button(layer, "ATACAR", Vector2(-154.0, -106.0), Callable(player, "attack_nearest_animal"))
	_add_action_button(layer, "PAREDE", Vector2(-154.0, -52.0), Callable(build_manager, "start_building").bind("wall"))
	_add_action_button(layer, "BASE", Vector2(-154.0, 2.0), Callable(build_manager, "start_building").bind("foundation"))
	_add_action_button(layer, "COLOCAR", Vector2(-294.0, -52.0), Callable(build_manager, "place_from_player"))

func _add_action_button(layer: CanvasLayer, button_text: String, button_position: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.text = button_text
	button.position = button_position
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.size = Vector2(126.0, 46.0)
	button.pressed.connect(callback)
	layer.add_child(button)

func _refresh_hud() -> void:
	if not is_instance_valid(stats_label) or not has_node("/root/GameManager"):
		return
	stats_label.text = "Vida: %d  Fome: %d  Sede: %d" % [roundi(GameManager.health), roundi(GameManager.hunger), roundi(GameManager.thirst)]
	var contents := GameManager.get_inventory_contents()
	inventory_label.text = "Mochila: Madeira %d | Pedra %d | Fibra %d | Couro %d" % [
		int(contents.get("wood", 0)), int(contents.get("stone", 0)),
		int(contents.get("fiber", 0)), int(contents.get("hide", 0))
	]
