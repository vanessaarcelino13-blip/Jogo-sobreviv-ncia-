extends StaticBody2D

func _ready() -> void:
    add_to_group("built_walls")
    z_index = 6
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-30, -10, 60, 20), Color("#765039"))
    draw_rect(Rect2(-30, -10, 60, 20), Color("#bd9565"), false, 2.0)
    for x in [-18.0, 0.0, 18.0]:
        draw_line(Vector2(x, -8), Vector2(x, 8), Color("#4b3021"), 2.0)
