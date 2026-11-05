extends Polygon2D

var valid := true

func configure(size: Vector2, tint: Color) -> void:
    polygon = PackedVector2Array([
        Vector2(-size.x * 0.5, -size.y * 0.5),
        Vector2(size.x * 0.5, -size.y * 0.5),
        Vector2(size.x * 0.5, size.y * 0.5),
        Vector2(-size.x * 0.5, size.y * 0.5)
    ])
    color = tint
    z_index = 20

func set_valid(value: bool) -> void:
    valid = value
    color = Color(0.35, 0.9, 0.4, 0.48) if valid else Color(0.95, 0.25, 0.2, 0.48)
