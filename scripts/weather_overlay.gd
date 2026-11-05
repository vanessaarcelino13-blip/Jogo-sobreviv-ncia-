extends CanvasLayer

var rain_nodes: Array[ColorRect] = []
var rain_active := false
var storm_flash := 0.0
var flash_timer := 0.0
var weather_darkness := 0.0
var fog_alpha := 0.0
var dark_rect: ColorRect
var fog_rect: ColorRect
var lightning_rect: ColorRect

func _ready() -> void:
    layer = 5
    process_mode = Node.PROCESS_MODE_ALWAYS

    dark_rect = ColorRect.new()
    dark_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dark_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dark_rect.color = Color(0.06, 0.09, 0.15, 0.0)
    add_child(dark_rect)

    fog_rect = ColorRect.new()
    fog_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fog_rect.color = Color(0.78, 0.82, 0.80, 0.0)
    add_child(fog_rect)

    lightning_rect = ColorRect.new()
    lightning_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    lightning_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lightning_rect.color = Color(1.0, 1.0, 1.0, 0.0)
    add_child(lightning_rect)

    var screen_size := get_viewport().get_visible_rect().size
    for i in range(100):
        var streak := ColorRect.new()
        streak.size = Vector2(2.0, randf_range(9.0, 17.0))
        streak.color = Color(0.70, 0.80, 0.94, 0.46)
        streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
        streak.position = Vector2(randf_range(0.0, screen_size.x), randf_range(0.0, screen_size.y))
        streak.rotation = -0.18
        add_child(streak)
        rain_nodes.append(streak)

    WeatherManager.weather_changed.connect(_on_weather_changed)
    _on_weather_changed(WeatherManager.current_weather)

func _process(delta: float) -> void:
    var screen_size := get_viewport().get_visible_rect().size
    if rain_active:
        for streak in rain_nodes:
            streak.position.y += delta * 430.0
            streak.position.x -= delta * 65.0
            if streak.position.y > screen_size.y + 20.0:
                streak.position = Vector2(randf_range(0.0, screen_size.x), randf_range(-80.0, -10.0))

    if WeatherManager.current_weather == "tempestade":
        flash_timer -= delta
        if flash_timer <= 0.0:
            flash_timer = randf_range(4.0, 9.0)
            storm_flash = 0.75
    storm_flash = maxf(0.0, storm_flash - delta * 3.8)

    if dark_rect:
        dark_rect.color = Color(0.07, 0.10, 0.17, weather_darkness)
    if fog_rect:
        fog_rect.color = Color(0.78, 0.82, 0.80, fog_alpha)
    if lightning_rect:
        lightning_rect.color = Color(1.0, 1.0, 1.0, storm_flash * 0.65)

func _on_weather_changed(weather: String) -> void:
    match weather:
        "limpo":
            rain_active = false
            weather_darkness = 0.0
            fog_alpha = 0.0
        "chuva":
            rain_active = true
            weather_darkness = 0.12
            fog_alpha = 0.02
        "tempestade":
            rain_active = true
            weather_darkness = 0.22
            fog_alpha = 0.035
        "nevoa":
            rain_active = false
            weather_darkness = 0.025
            fog_alpha = 0.24
    for streak in rain_nodes:
        streak.visible = rain_active
