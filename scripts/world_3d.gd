extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player_3d.gd")
const ANIMAL_SCRIPT = preload("res://scripts/wild_animal_3d.gd")
const RESOURCE_SCRIPT = preload("res://scripts/resource_node_3d.gd")
const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")

var player: CharacterBody3D
var stats_label: Label
var inventory_label: Label
var message_label: Label
var survival_tick := 0.0

func _ready() -> void:
	randomize()
	_build_environment()
	_spawn_player()
	_spawn_resources()
	_spawn_animals()
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
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100.0, 100.0)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("#40563a")
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	ground.position.y = -0.12
	add_child(ground)
	var ground_body := StaticBody3D.new()
	var ground_collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 0.2, 100.0)
	ground_collision.shape = box
	ground_collision.position.y = -0.1
	ground_body.add_child(ground_collision)
	add_child(ground_body)
	for i in range(55):
		var tree := Node3D.new()
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
		add_child(tree)

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
		node.resource_kind = "Madeira" if i % 3 != 0 else "Fibra"
		node.position = Vector3(randf_range(-25.0, 25.0), 0.0, randf_range(-25.0, 25.0))
		add_child(node)
	for i in range(12):
		var node := StaticBody3D.new()
		node.set_script(RESOURCE_SCRIPT)
		node.resource_kind = "Pedra"
		node.position = Vector3(randf_range(-25.0, 25.0), 0.0, randf_range(-25.0, 25.0))
		add_child(node)

func _spawn_animals() -> void:
	var kinds := ["Lobo", "Urso", "Javali"]
	for i in range(8):
		var animal := CharacterBody3D.new()
		animal.set_script(ANIMAL_SCRIPT)
		animal.animal_kind = kinds[i % kinds.size()]
		animal.position = Vector3(randf_range(-22.0, 22.0), 0.0, randf_range(-22.0, 22.0))
		add_child(animal)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16.0, 14.0)
	panel.custom_minimum_size = Vector2(330.0, 112.0)
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
	message_label = Label.new()
	message_label.text = "WASD mover • E coletar • Espaço atacar"
	message_label.position = Vector2(18.0, 138.0)
	layer.add_child(message_label)
	var joystick = JOYSTICK_SCRIPT.new()
	joystick.position = Vector2(24.0, -174.0)
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.size = Vector2(150.0, 150.0)
	joystick.vector_changed.connect(player.set_touch_input)
	layer.add_child(joystick)
	var collect_button := Button.new()
	collect_button.text = "COLETAR"
	collect_button.position = Vector2(-154.0, -104.0)
	collect_button.anchor_left = 1.0
	collect_button.anchor_right = 1.0
	collect_button.anchor_top = 1.0
	collect_button.anchor_bottom = 1.0
	collect_button.size = Vector2(128.0, 48.0)
	collect_button.pressed.connect(player.collect_nearest_resource)
	layer.add_child(collect_button)
	var attack_button := Button.new()
	attack_button.text = "ATACAR"
	attack_button.position = Vector2(-154.0, -48.0)
	attack_button.anchor_left = 1.0
	attack_button.anchor_right = 1.0
	attack_button.anchor_top = 1.0
	attack_button.anchor_bottom = 1.0
	attack_button.size = Vector2(128.0, 48.0)
	attack_button.pressed.connect(player.attack_nearest_animal)
	layer.add_child(attack_button)

func _refresh_hud() -> void:
	if not is_instance_valid(stats_label) or not has_node("/root/GameManager"):
		return
	stats_label.text = "Vida: %d  Fome: %d  Sede: %d" % [roundi(GameManager.health), roundi(GameManager.hunger), roundi(GameManager.thirst)]
	var contents := GameManager.get_inventory_contents()
	var wood := int(contents.get("wood", 0))
	var stone := int(contents.get("stone", 0))
	var fiber := int(contents.get("fiber", 0))
	var hide := int(contents.get("hide", 0))
	inventory_label.text = "Mochila: Madeira %d | Pedra %d | Fibra %d | Couro %d" % [wood, stone, fiber, hide]
