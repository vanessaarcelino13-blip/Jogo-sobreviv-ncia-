extends Node2D

var flicker := 0.0

func _ready() -> void:
    add_to_group("campfires")
    z_index = 5
    queue_redraw()

func _process(delta: float) -> void:
    flicker += delta * 8.0
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2(0, 5), 22, Color(0.08, 0.07, 0.05, 0.25))
    draw_line(Vector2(-16, 8), Vector2(15, -5), Color("#67452e"), 7.0)
    draw_line(Vector2(-15, -5), Vector2(16, 8), Color("#8a5a36"), 7.0)
    var flame_height := 15.0 + sin(flicker) * 3.0
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, -flame_height - 8), Vector2(-9, 3),
        Vector2(-5, 9), Vector2(7, 8), Vector2(10, 1)
    ]), Color("#e56a28"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(1, -flame_height + 1), Vector2(-4, 3),
        Vector2(1, 7), Vector2(5, 2)
    ]), Color("#ffd36a"))
