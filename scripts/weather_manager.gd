extends Node

signal weather_changed(weather_type: String)

const WEATHER_TYPES := ["limpo", "chuva", "tempestade", "nevoa"]
var current_weather := "limpo"
var _timer := 0.0
var _next_change := 65.0

func _process(delta: float) -> void:
    if get_tree().paused:
        return
    _timer += delta
    if _timer >= _next_change:
        _timer = 0.0
        _next_change = randf_range(55.0, 95.0)
        _change_weather()

func _change_weather() -> void:
    var roll := randf()
    var season := GameManager.current_season
    if season == "inverno":
        if roll < 0.30:
            current_weather = "limpo"
        elif roll < 0.70:
            current_weather = "chuva"
        else:
            current_weather = "tempestade"
    elif season == "verao":
        current_weather = "limpo" if roll < 0.80 else "chuva"
    else:
        if roll < 0.50:
            current_weather = "limpo"
        elif roll < 0.80:
            current_weather = "chuva"
        else:
            current_weather = "tempestade"
    weather_changed.emit(current_weather)
    print("[Clima] ", current_weather, " | Estação: ", season)
