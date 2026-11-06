extends CharacterBody2D

@export var speed: float = 220.0
@export var pulse_radius: float = 112.0
@export var pulse_cooldown: float = 1.4
@export var flashlight_energy: float = 1.35
@export var flashlight_distance: float = 430.0

var facing: Vector2 = Vector2.DOWN
var pulse_timer := 0.0
var pulse_visual := 0.0
var flashlight: PointLight2D

func _ready() -> void:
    add_to_group("player")
    z_index = 5
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
    _create_flashlight()
    queue_redraw()

func _create_flashlight() -> void:
    flashlight = PointLight2D.new()
    flashlight.name = "Lanterna"
    flashlight.color = Color(1.0, 0.82, 0.55, 1.0)
    flashlight.energy = flashlight_energy
    flashlight.texture = _make_light_texture()
    flashlight.texture_scale = flashlight_distance / 256.0
    flashlight.shadow_enabled = false
    flashlight.blend_mode = Light2D.BLEND_MODE_ADD
    flashlight.position = Vector2(0, -5)
    add_child(flashlight)

func _make_light_texture() -> Texture2D:
    var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
    for y in range(128):
        for x in range(128):
            var distance := Vector2(x - 63.5, y - 63.5).length() / 63.5
            var alpha := pow(maxf(0.0, 1.0 - distance), 2.2)
            image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
    return ImageTexture.create_from_image(image)

func _physics_process(delta: float) -> void:
    pulse_timer = maxf(0.0, pulse_timer - delta)
    pulse_visual = maxf(0.0, pulse_visual - delta)
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if direction.length() > 0.05:
        facing = direction.normalized()
    var weather_factor := 1.0
    if WeatherManager.current_weather == "chuva" or WeatherManager.current_weather == "tempestade":
        weather_factor = 0.9
    velocity = direction * speed * weather_factor
    move_and_slide()
    if is_instance_valid(flashlight):
        flashlight.rotation = facing.angle() + PI / 2.0
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        collect_nearest_resource()
    if event.is_action_pressed("defend"):
        use_pulse()

func use_pulse() -> void:
    if pulse_timer > 0.0:
        return
    pulse_timer = pulse_cooldown
    pulse_visual = 0.28
    var camera := get_node_or_null("Camera2D")
    if camera and camera.has_method("shake"):
        camera.shake(0.16, 3.0)
    for animal in get_tree().get_nodes_in_group("wildlife"):
        if is_instance_valid(animal) and global_position.distance_to(animal.global_position) <= pulse_radius:
            if animal.has_method("scare_away"):
                animal.scare_away(global_position)
    queue_redraw()

func collect_nearest_resource() -> void:
    var closest: Area2D = null
    var closest_distance := 72.0
    for item in get_tree().get_nodes_in_group("resources"):
        if not is_instance_valid(item):
            continue
        var distance := global_position.distance_to(item.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest = item
    if closest and closest.has_method("collect"):
        closest.collect()

func _draw() -> void:
    if pulse_visual > 0.0:
        var alpha := pulse_visual / 0.28
        draw_arc(Vector2.ZERO, pulse_radius * (1.0 - alpha * 0.35), 0.0, TAU, 48, Color(0.45, 0.85, 1.0, alpha * 0.8), 3.0)
    draw_ellipse_shadow()
    # Silhueta top-down com cabeça, tronco, braços e mochila.
    draw_circle(Vector2(0, 3), 12, Color("#20251f"))
    draw_rect(Rect2(-8, -1, 16, 17), Color("#40584a"))
    draw_rect(Rect2(-5, 1, 10, 12), Color("#68745a"))
    draw_line(Vector2(-7, 2), Vector2(-12, 10), Color("#c49a72"), 4.0)
    draw_line(Vector2(7, 2), Vector2(12, 10), Color("#c49a72"), 4.0)
    draw_line(Vector2(-4, 14), Vector2(-5, 21), Color("#303a35"), 4.0)
    draw_line(Vector2(4, 14), Vector2(5, 21), Color("#303a35"), 4.0)
    draw_circle(Vector2(0, -7), 7.5, Color("#d9ad83"))
    draw_arc(Vector2(0, -7), 7.5, PI, TAU, 16, Color("#3a2b22"), 3.0)
    draw_line(Vector2.ZERO, facing * 15.0, Color("#a9eaff"), 2.5)

func draw_ellipse_shadow() -> void:
    draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.55))
    draw_circle(Vector2.ZERO, 13, Color(0, 0, 0, 0.22))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
