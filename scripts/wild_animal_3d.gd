extends CharacterBody3D

@export_enum("Lobo", "Urso", "Javali") var animal_kind: String = "Lobo"
@export var detection_radius: float = 10.0
@export var move_speed: float = 2.8
@export var attack_damage: float = 8.0
@export var attack_distance: float = 1.7
@export var attack_cooldown: float = 1.6
var player: Node3D
var attack_timer := 0.0
var wander_timer := 0.0
var wander_direction := Vector3.ZERO

func _ready() -> void:
	add_to_group("wildlife_3d")
	_build_visual()
	wander_timer = randf_range(1.0, 3.0)

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
		if players.size() > 0:
			player = players[0]
	var direction := Vector3.ZERO
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= detection_radius:
		direction = global_position.direction_to(player.global_position)
		if global_position.distance_to(player.global_position) <= attack_distance and attack_timer <= 0.0:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
			attack_timer = attack_cooldown
	else:
		wander_timer -= delta
		if wander_timer <= 0.0:
			wander_timer = randf_range(1.5, 4.0)
			wander_direction = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
		direction = wander_direction
	if direction.length() > 0.05:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 5.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	move_and_slide()
