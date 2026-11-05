extends Node

signal stats_changed
var health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var wood: int = 0
var stone: int = 0
var day: int = 1
var elapsed: float = 0.0

func reset_new_game() -> void:
    health = 100.0
    hunger = 100.0
    thirst = 100.0
    wood = 0
    stone = 0
    day = 1
    elapsed = 0.0
    stats_changed.emit()

func add_resource(kind: String, amount: int) -> void:
    if kind == "wood":
        wood += amount
    elif kind == "stone":
        stone += amount
    stats_changed.emit()

func consume_survival(delta: float) -> void:
    elapsed += delta
    hunger = maxf(0.0, hunger - delta * 0.22)
    thirst = maxf(0.0, thirst - delta * 0.34)
    if hunger <= 0.0 or thirst <= 0.0:
        health = maxf(0.0, health - delta * 1.8)
    if elapsed >= 180.0:
        elapsed = 0.0
        day += 1
    stats_changed.emit()

func save_game() -> void:
    var data := {"health": health, "hunger": hunger, "thirst": thirst, "wood": wood, "stone": stone, "day": day, "elapsed": elapsed}
    var file := FileAccess.open("user://survival_save.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func load_game() -> bool:
    if not FileAccess.file_exists("user://survival_save.json"):
        return false
    var file := FileAccess.open("user://survival_save.json", FileAccess.READ)
    if file == null:
        return false
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return false
    health = float(parsed.get("health", 100.0))
    hunger = float(parsed.get("hunger", 100.0))
    thirst = float(parsed.get("thirst", 100.0))
    wood = int(parsed.get("wood", 0))
    stone = int(parsed.get("stone", 0))
    day = int(parsed.get("day", 1))
    elapsed = float(parsed.get("elapsed", 0.0))
    stats_changed.emit()
    return true
