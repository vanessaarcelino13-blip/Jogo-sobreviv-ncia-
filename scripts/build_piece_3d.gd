extends StaticBody3D

@export_enum("wall", "foundation") var piece_type: String = "wall"

func _ready() -> void:
	add_to_group("buildings_3d")
	collision_layer = 2
	collision_mask = 1
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	if piece_type == "foundation":
		box_mesh.size = Vector3(2.0, 0.25, 2.0)
		box_shape.size = box_mesh.size
		mesh_instance.position.y = 0.125
		collision.position.y = 0.125
	else:
		box_mesh.size = Vector3(2.0, 2.0, 0.2)
		box_shape.size = box_mesh.size
		mesh_instance.position.y = 1.0
		collision.position.y = 1.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#806044")
	material.roughness = 0.9
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	add_child(mesh_instance)
	collision.shape = box_shape
	add_child(collision)
