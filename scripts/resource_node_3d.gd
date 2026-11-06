extends StaticBody3D

@export_enum("Madeira", "Pedra", "Fibra") var resource_kind: String = "Madeira"
@export var harvests_left: int = 3
@export var amount_per_harvest: int = 1

func _ready() -> void:
	add_to_group("resources_3d")
	_build_visual()

func _build_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	if resource_kind == "Madeira":
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.28
		cylinder.bottom_radius = 0.38
		cylinder.height = 2.4
		mesh_instance.mesh = cylinder
		mesh_instance.position.y = 1.2
		material.albedo_color = Color("#65452d")
	else:
		var rock := SphereMesh.new()
		rock.radius = 0.7
		rock.height = 1.0
		mesh_instance.mesh = rock
		mesh_instance.position.y = 0.5
		material.albedo_color = Color("#77796d") if resource_kind == "Pedra" else Color("#647b42")
	mesh_instance.material_override = material
	add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 2.4 if resource_kind == "Madeira" else 1.0
	collision.shape = shape
	collision.position.y = shape.height * 0.5
	add_child(collision)

func collect() -> void:
	if harvests_left <= 0 or not has_node("/root/GameManager"):
		return
	var item_id := "wood"
	match resource_kind:
		"Pedra": item_id = "stone"
		"Fibra": item_id = "fiber"
	var amount := amount_per_harvest
	if resource_kind in ["Madeira", "Pedra"]:
		amount = GameManager.get_harvest_amount(item_id, amount_per_harvest)
	if not GameManager.add_resource(item_id, amount):
		print("Inventário cheio! Libere espaço antes de coletar.")
		return
	harvests_left -= 1
	print("+", amount, " ", GameManager.get_item_name(item_id), " | Coletas restantes: ", harvests_left)
	if harvests_left == 0:
		queue_free()
