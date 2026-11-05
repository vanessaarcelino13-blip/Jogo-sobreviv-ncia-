extends CanvasLayer

var rain_lines: Array[Vector2] = []
var rain_active := false
var storm_flash := 0.0
var flash_timer := 0.0
var weather_darkness := 0.0
var fog_alpha := 0.0
var overlay_rect: ColorRect

func _ready() -> void:
    layer = 20
    process_mode = Node.PROCESS_MODE_ALWAYS
    overlay_rect = ColorRect.new()
    overlay_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay_rect.color = Color(0.06, 0.09, 0.15, 0.0)
    add_child(overlay_rect)
    WeatherManager.weather_changed.connect(_on_weather_changed)
    _on_weather_changed(WeatherManager.current_weather)
    _reset_rain()

func _reset_rain() -> void:
    rain_lines.clear()
    var size := get_viewport().get_visible_rect().size
    for i in range(120):
        rain_lines.append(Vector2(randf_range(0.0, size.x), randf_range(0.0, size.y)))

func _process(delta: float) -> void:
    var size := get_viewport().get_visible_rect().size
    if rain_active:
        for i in range(rain_lines.size()):
            rain_lines[i].y += delta * 430.0
            rain_lines[i].x -= delta * 65.0
            if rain_lines[i].y > size.y + 15.0:
                rain_lines[i] = Vector2(randf_range(0.0, size.x), randf_range(-80.0, -10.0))
    if storm_flash > 0.0:
        storm_flash = maxf(0.0, storm_flash - delta * 3.8)
    if WeatherManager.current_weather == "tempestade":
        flash_timer -= delta
        if flash_timer <= 0.0:
            flash_timer = randf_range(4.0, 9.0)
            storm_flash = 0.75
    queue_redraw()
    if overlay_rect:
        overlay_rect.color = Color(0.07, 0.10, 0.17, weather_darkness + storm_flash * 0.65 + fog_alpha)

func _on_weather_changed(weather: String) -> void:
    match weather:
        "limpo":
            rain_active = false
            weather_darkness = 0.0
            fog_alpha = 0.0
        "chuva":
            rain_active = true
            weather_darkness = 0.13
            fog_alpha = 0.025
        "tempestade":
            rain_active = true
            weather_darkness = 0.24
            fog_alpha = 0.04
        "nevoa":
            rain_active = false
            weather_darkness = 0.04
            fog_alpha = 0.20

func _draw() -> void:
    if rain_active:
        for point in rain_lines:
            draw_line(point, point + Vector2(-5, 15), Color(0.68, 0.78, 0.92, 0.45), 1.2)
