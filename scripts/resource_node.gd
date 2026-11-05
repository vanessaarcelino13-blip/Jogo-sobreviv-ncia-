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
        draw_circle(Vector2(0, 5), 18, Color("253d2e"))
        draw_circle(Vector2(-7, -4), 12, Color("477b49"))
        draw_circle(Vector2(7, -7), 13, Color("5d9255"))
        draw_rect(Rect2(-3, 4, 6, 17), Color("795239"))
    elif resource_type == "stone":
        draw_circle(Vector2.ZERO, 16, Color("737b78"))
        draw_circle(Vector2(-5, -4), 6, Color("a3aaa4"))
        draw_circle(Vector2(6, 5), 4, Color("555f5b"))
    elif resource_type == "fiber":
        draw_line(Vector2(-8, 8), Vector2(-2, -10), Color("#b4a56a"), 3.0)
        draw_line(Vector2(0, 9), Vector2(3, -12), Color("#d1bd79"), 3.0)
        draw_line(Vector2(7, 8), Vector2(10, -7), Color("#8e9d55"), 3.0)
    else:
        draw_circle(Vector2.ZERO, 13, Color("#92704f"))
        draw_circle(Vector2(-4, -3), 5, Color("#b28c65"))
        draw_circle(Vector2(5, 4), 4, Color("#684d38"))
