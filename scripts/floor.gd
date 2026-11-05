extends StaticBody2D

func _ready() -> void:
    add_to_group("floors")
    z_index = 4
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-32, -32, 64, 64), Color("#765338"))
    draw_rect(Rect2(-32, -32, 64, 64), Color("#b58a5c"), false, 2.0)
    for y in [-16.0, 0.0, 16.0]:
        draw_line(Vector2(-30, y), Vector2(30, y), Color("#4b3526"), 2.0)
    draw_line(Vector2(0, -30), Vector2(0, -18), Color("#4b3526"), 1.0)
    draw_line(Vector2(-12, 2), Vector2(-12, 14), Color("#4b3526"), 1.0)
    draw_line(Vector2(18, -14), Vector2(18, -2), Color("#4b3526"), 1.0)
