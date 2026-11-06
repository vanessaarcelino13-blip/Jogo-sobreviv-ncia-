extends Area2D

@export_enum("wood", "stone", "fiber", "hide") var resource_type: String = "wood"
@export var amount: int = 2
var available := true

func _ready() -> void:
    add_to_group("resources")
    queue_redraw()

func collect() -> void:
    if not available:
        return
    if not GameManager.can_harvest(resource_type):
        return
    var harvest_amount := GameManager.get_harvest_amount(resource_type, amount)
    if not GameManager.add_resource(resource_type, harvest_amount):
        return
    available = false
    queue_redraw()

func _draw() -> void:
    if not available:
        draw_circle(Vector2.ZERO, 8, Color(0.2, 0.22, 0.18, 0.35))
        return
    if resource_type == "wood":
        # Sombra e tronco alinhado à base para evitar aparência de árvore-caixa.
        draw_set_transform(Vector2(0, 15), 0.0, Vector2(1.0, 0.45))
        draw_circle(Vector2.ZERO, 19, Color(0.0, 0.0, 0.0, 0.22))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        draw_rect(Rect2(-5, 0, 10, 25), Color("#5b3928"))
        draw_rect(Rect2(-2, 2, 3, 20), Color("#946344"))
        draw_circle(Vector2(-10, -13), 15, Color("#315b37"))
        draw_circle(Vector2(8, -17), 17, Color("#416e3e"))
        draw_circle(Vector2(0, -29), 16, Color("#527d45"))
        draw_circle(Vector2(-5, -31), 6, Color("#6b9250"))
        draw_circle(Vector2(11, -19), 5, Color("#638a4d"))
    elif resource_type == "stone":
        draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.5))
        draw_circle(Vector2.ZERO, 17, Color(0, 0, 0, 0.22))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        var rock_points := PackedVector2Array([Vector2(-17, 5), Vector2(-13, -8), Vector2(-4, -17), Vector2(9, -15), Vector2(18, -3), Vector2(14, 10), Vector2(-3, 15)])
        draw_colored_polygon(rock_points, Color("#68716e"))
        draw_line(Vector2(-10, -5), Vector2(-3, -13), Color("#a5aaa1"), 3.0)
        draw_line(Vector2(4, -9), Vector2(11, -3), Color("#89938c"), 2.0)
    elif resource_type == "fiber":
        draw_line(Vector2(-8, 8), Vector2(-2, -10), Color("#b4a56a"), 3.0)
        draw_line(Vector2(0, 9), Vector2(3, -12), Color("#d1bd79"), 3.0)
        draw_line(Vector2(7, 8), Vector2(10, -7), Color("#8e9d55"), 3.0)
        draw_line(Vector2(-3, 7), Vector2(-12, -3), Color("#9eaa61"), 2.0)
    else:
        draw_circle(Vector2.ZERO, 13, Color("#92704f"))
        draw_circle(Vector2(-4, -3), 5, Color("#b28c65"))
        draw_circle(Vector2(5, 4), 4, Color("#684d38"))
