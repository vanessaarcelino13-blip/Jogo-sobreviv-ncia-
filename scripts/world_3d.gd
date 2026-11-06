extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player_3d.gd")
const ANIMAL_SCRIPT = preload("res://scripts/wild_animal_3d.gd")
const RESOURCE_SCRIPT = preload("res://scripts/resource_node_3d.gd")

func _ready() -> void:
	_build_environment()
	_spawn_player()
	_spawn_resources()
	_spawn_animals()
	_build_hud()

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
		var tree := MeshInstance3D.new()
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.18
		trunk.bottom_radius = 0.28
		trunk.height = randf_range(1.8, 2.8)
		tree.mesh = trunk
		var trunk_material := StandardMaterial3D.new()
		trunk_material.albedo_color = Color("#59412c")
		tree.material_override = trunk_material
		tree.position = Vector3(randf_range(-45.0, 45.0), trunk.height * 0.5, randf_range(-45.0, 45.0))
		add_child(tree)
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = randf_range(0.8, 1.4)
		crown_mesh.height = crown_mesh.radius * 2.0
		crown.mesh = crown_mesh
		var crown_material := StandardMaterial3D.new()
		crown_material.albedo_color = Color("#29452d")
		crown.material_override = crown_material
		crown.position = tree.position + Vector3(0.0, trunk.height * 0.65, 0.0)
		add_child(crown)

func _spawn_player() -> void:
	var player := CharacterBody3D.new()
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
	player.position = Vector3(0.0, 0.0, 0.0)
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
	var label := Label.new()
	label.text = "SOBREVIVÊNCIA 3D  |  WASD: mover  •  E: coletar  •  Animais selvagens: lobo, urso e javali"
	label.position = Vector2(18.0, 18.0)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("#f0e4c9"))
	layer.add_child(label)
