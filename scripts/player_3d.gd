extends CharacterBody3D

@export var move_speed: float = 5.0
@export var rotation_speed: float = 9.0
@export var interaction_distance: float = 2.4
@export var attack_distance: float = 2.0
@export var attack_damage: float = 18.0

var health: float = 100.0
var facing := Vector3.FORWARD
var touch_input := Vector2.ZERO
var attack_cooldown := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 3
	add_to_group("player")
	_setup_camera()
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_SPACE
		InputMap.action_add_event("attack", key)

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

func set_touch_input(value: Vector2) -> void:
	touch_input = value.limit_length(1.0)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var input_2d := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_input.length() > 0.08:
		input_2d = touch_input
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var camera_basis := camera.global_basis
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
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	move_and_slide()
	if Input.is_action_just_pressed("attack"):
		attack_nearest_animal()

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

func attack_nearest_animal() -> void:
	if attack_cooldown > 0.0:
		return
	var closest: Node3D
	var closest_distance := attack_distance
	for animal in get_tree().get_nodes_in_group("wildlife_3d"):
		if not is_instance_valid(animal):
			continue
		var distance := global_position.distance_to(animal.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = animal
	if closest and closest.has_method("take_damage"):
		closest.take_damage(attack_damage)
		attack_cooldown = 0.65

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if has_node("/root/GameManager"):
		GameManager.health = health
		GameManager.stats_changed.emit()
	if health <= 0.0:
		print("O sobrevivente foi derrotado. Reinicie a cena para testar novamente.")
