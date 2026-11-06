extends CharacterBody3D

@export_enum("Lobo", "Urso", "Javali") var animal_kind: String = "Lobo"
@export var detection_radius: float = 12.0
@export var move_speed: float = 3.2
@export var attack_damage: float = 8.0
@export var attack_distance: float = 1.7
@export var attack_cooldown: float = 1.6
@export var max_health: float = 35.0

var health: float = 35.0
var player: Node3D
var attack_timer := 0.0
var wander_timer := 0.0
var wander_direction := Vector3.ZERO
var nav_agent: NavigationAgent3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 3
	add_to_group("wildlife_3d")
	health = max_health
	_build_visual()
	_setup_navigation()
	wander_timer = randf_range(1.0, 3.0)

func _setup_navigation() -> void:
	nav_agent = NavigationAgent3D.new()
	nav_agent.name = "NavigationAgent3D"
	nav_agent.path_desired_distance = 0.6
	nav_agent.target_desired_distance = 1.2
	nav_agent.radius = 0.45
	nav_agent.avoidance_enabled = true
	nav_agent.max_speed = move_speed
	nav_agent.neighbor_distance = 5.0
	nav_agent.max_neighbors = 8
	add_child(nav_agent)
	nav_agent.velocity_computed.connect(_on_velocity_computed)

func _build_visual() -> void:
	var body_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.48 if animal_kind == "Urso" else 0.32
	capsule.height = 1.15 if animal_kind == "Urso" else 0.8
	body_mesh.mesh = capsule
	body_mesh.position.y = 0.62
	var material := StandardMaterial3D.new()
	match animal_kind:
		"Urso": material.albedo_color = Color("#493a2d")
		"Javali": material.albedo_color = Color("#70513b")
		_: material.albedo_color = Color("#77716a")
	body_mesh.material_override = material
	add_child(body_mesh)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	head.mesh = head_mesh
	head.position = Vector3(0.0, 0.85, -0.42)
	head.material_override = material
	add_child(head)
	var shape := CollisionShape3D.new()
	var collision := CapsuleShape3D.new()
	collision.radius = 0.38
	collision.height = 1.2
	shape.shape = collision
	shape.position.y = 0.6
	add_child(shape)

func _physics_process(delta: float) -> void:
	attack_timer = maxf(0.0, attack_timer - delta)
	if not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player = players[0]

	var destination := global_position
	var pursuing := false
	if is_instance_valid(player):
		var distance := global_position.distance_to(player.global_position)
		if distance <= detection_radius:
			pursuing = true
			destination = player.global_position
			if distance <= attack_distance and attack_timer <= 0.0:
				if player.has_method("take_damage"):
					player.take_damage(attack_damage)
				attack_timer = attack_cooldown
	if not pursuing:
		_update_wander_target(delta)
		destination = global_position + wander_direction * 4.0

	if nav_agent.is_navigation_finished() or pursuing:
		nav_agent.target_position = destination
	if NavigationServer3D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
		move_and_slide()
		return

	var next_position := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)
	direction.y = 0.0
	if direction.length() > 0.08:
		nav_agent.velocity = direction.normalized() * move_speed
	else:
		nav_agent.velocity = Vector3.ZERO
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	move_and_slide()
	if direction.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 7.0 * delta)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

func _update_wander_target(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(2.0, 5.0)
		wander_direction = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		if has_node("/root/GameManager"):
			GameManager.add_item("hide", 2 if animal_kind == "Urso" else 1)
		queue_free()
