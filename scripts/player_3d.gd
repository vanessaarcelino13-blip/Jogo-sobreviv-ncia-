extends CharacterBody3D

@export var move_speed: float = 5.0
@export var rotation_speed: float = 9.0
@export var interaction_distance: float = 2.4
var health: float = 100.0
var facing := Vector3.FORWARD
var nearby_resource: Node3D

func _ready() -> void:
	add_to_group("player")
	_setup_camera()

func _setup_camera() -> void:
	var pivot := Node3D.new()
	pivot.name = "CameraPivot"
	pivot.rotation_degrees = Vector3(-48.0, 45.0, 0.0)
	add_child(pivot)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17.0
	camera.position = Vector3(0.0, 0.0, 16.0)
	pivot.add_child(camera)
	camera.current = true

func _physics_process(delta: float) -> void:
	var input_2d := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var camera_basis := get_viewport().get_camera_3d().global_basis
	var forward := -camera_basis.z
	var right := camera_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var direction := (right * input_2d.x + forward * -input_2d.y).normalized()
	if direction.length() > 0.05:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		facing = direction
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		collect_nearest_resource()

func collect_nearest_resource() -> void:
	var closest: Node3D
	var closest_distance := interaction_distance
	for resource in get_tree().get_nodes_in_group("resources_3d"):
		if not is_instance_valid(resource):
			continue
		var distance := global_position.distance_to(resource.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = resource
	if closest and closest.has_method("collect"):
		closest.collect()

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	print("Vida do sobrevivente: ", roundi(health))
	if health <= 0.0:
		print("O sobrevivente foi derrotado. Reinicie a cena para testar novamente.")
