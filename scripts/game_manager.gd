extends Node

signal stats_changed
signal player_died
signal season_changed(new_season: String)

const DAYS_PER_SEASON := 3
const SEASON_ORDER := ["primavera", "verao", "outono", "inverno"]
const SEASON_DATA := {
    "primavera": {"thirst_mult": 1.0, "temp": "ameno"},
    "verao": {"thirst_mult": 2.0, "temp": "quente"},
    "outono": {"thirst_mult": 1.0, "temp": "ameno"},
    "inverno": {"thirst_mult": 0.8, "temp": "frio"}
}

var death_reported := false

const INVENTORY_CAPACITY := 20
const STACK_LIMIT := 20
const TOOL_STONE := "stone_axe"
const TOOL_METAL := "metal_axe"
const PICKAXE_STONE := "stone_pickaxe"
const PICKAXE_METAL := "metal_pickaxe"

var health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var wood: int = 0
var stone: int = 0
var day: int = 1
var current_season: String = "primavera"
var elapsed: float = 0.0
var inventory: Array[Dictionary] = []
var equipped_tool: String = TOOL_STONE
var equipped_armor: String = ""
var built_floors: Array[Dictionary] = []
var built_objects: Array[Dictionary] = []

func _ready() -> void:
    _reset_inventory()

func _reset_inventory() -> void:
    inventory.clear()
    for i in range(INVENTORY_CAPACITY):
        inventory.append({})
    wood = 0
    stone = 0

func reset_new_game() -> void:
    death_reported = false
    health = 100.0
    hunger = 100.0
    thirst = 100.0
    day = 1
    current_season = "primavera"
    elapsed = 0.0
    equipped_tool = TOOL_STONE
    equipped_armor = ""
    built_floors.clear()
    built_objects.clear()
    _reset_inventory()
    add_item(TOOL_STONE, 1)
    stats_changed.emit()

func _count_item(item_id: String) -> int:
    var total := 0
    for slot in inventory:
        if slot.get("id", "") == item_id:
            total += int(slot.get("count", 0))
    return total

func _sync_resource_totals() -> void:
    wood = _count_item("wood")
    stone = _count_item("stone")

func add_item(item_id: String, amount: int) -> bool:
    if amount <= 0:
        return true
    var free_capacity := 0
    for slot in inventory:
        if slot.is_empty():
            free_capacity += STACK_LIMIT
        elif slot.get("id", "") == item_id:
            free_capacity += STACK_LIMIT - int(slot.get("count", 0))
    if free_capacity < amount:
        return false
    var remaining := amount
    for i in range(inventory.size()):
        if inventory[i].get("id", "") == item_id and int(inventory[i].get("count", 0)) < STACK_LIMIT:
            var room := STACK_LIMIT - int(inventory[i]["count"])
            var added := mini(room, remaining)
            inventory[i]["count"] = int(inventory[i]["count"]) + added
            remaining -= added
            if remaining <= 0:
                break
    for i in range(inventory.size()):
        if remaining <= 0:
            break
        if inventory[i].is_empty():
            var added := mini(STACK_LIMIT, remaining)
            inventory[i] = {"id": item_id, "count": added}
            remaining -= added
    _sync_resource_totals()
    stats_changed.emit()
    return true

func add_resource(kind: String, amount: int) -> bool:
    return add_item(kind, amount)

func get_inventory_slot(index: int) -> Dictionary:
    if index < 0 or index >= inventory.size():
        return {}
    return inventory[index].duplicate()

func get_item_count(item_id: String) -> int:
    return _count_item(item_id)

func remove_item(item_id: String, amount: int) -> bool:
    var removed := _remove_item(item_id, amount)
    if removed:
        stats_changed.emit()
    return removed

func get_inventory_contents() -> Dictionary:
    var contents: Dictionary = {}
    for slot in inventory:
        var item_id := str(slot.get("id", ""))
        var count := int(slot.get("count", 0))
        if item_id != "" and count > 0:
            contents[item_id] = int(contents.get(item_id, 0)) + count
    return contents

func clear_inventory() -> Dictionary:
    var dropped := get_inventory_contents()
    _reset_inventory()
    equipped_tool = ""
    equipped_armor = ""
    stats_changed.emit()
    return dropped

func get_item_name(item_id: String) -> String:
    match item_id:
        "wood": return "Madeira"
        "stone": return "Pedra"
        "stone_axe": return "Machado de pedra"
        "metal_axe": return "Machado de metal"
        "stone_pickaxe": return "Picareta de pedra"
        "metal_pickaxe": return "Picareta de metal"
        "fiber": return "Fibra vegetal"
        "hide": return "Couro"
        "coat": return "Casaco"
        "sun_hat": return "Chapéu"
        "airdrop_chip": return "Componente raro"
        _: return item_id

func get_harvest_amount(resource_type: String, base_amount: int) -> int:
    var multiplier := 1
    if resource_type == "wood":
        if equipped_tool == TOOL_METAL:
            multiplier = 4
        elif equipped_tool == TOOL_STONE:
            multiplier = 2
    elif resource_type == "stone":
        if equipped_tool == PICKAXE_METAL:
            multiplier = 4
        elif equipped_tool == PICKAXE_STONE:
            multiplier = 2
    return base_amount * multiplier

func can_harvest(resource_type: String) -> bool:
    return resource_type in ["wood", "stone", "fiber", "hide"]

func equip_armor(item_id: String) -> bool:
    if item_id not in ["coat", "sun_hat"] or get_item_count(item_id) < 1:
        return false
    equipped_armor = "" if equipped_armor == item_id else item_id
    stats_changed.emit()
    return true

func craft_coat() -> bool:
    if get_item_count("hide") < 5 or get_item_count("fiber") < 3:
        return false
    _remove_item("hide", 5)
    _remove_item("fiber", 3)
    if not add_item("coat", 1):
        return false
    stats_changed.emit()
    return true

func craft_sun_hat() -> bool:
    if get_item_count("fiber") < 5 or get_item_count("wood") < 2:
        return false
    _remove_item("fiber", 5)
    _remove_item("wood", 2)
    if not add_item("sun_hat", 1):
        return false
    stats_changed.emit()
    return true

func apply_climate_damage(biome: String, delta: float) -> void:
    var damage_per_second := 0.0
    if biome == "neve" and equipped_armor != "coat":
        damage_per_second = 1.2
    elif biome == "deserto" and equipped_armor != "sun_hat":
        damage_per_second = 0.8
    if damage_per_second > 0.0:
        health = maxf(0.0, health - damage_per_second * delta)
        if health <= 0.0 and not death_reported:
            death_reported = true
            player_died.emit()
        stats_changed.emit()

func craft_stone_pickaxe() -> bool:
    if get_item_count(PICKAXE_STONE) > 0:
        return false
    if get_item_count("wood") < 3 or get_item_count("stone") < 2:
        return false
    _remove_item("wood", 3)
    _remove_item("stone", 2)
    if not add_item(PICKAXE_STONE, 1):
        return false
    equipped_tool = PICKAXE_STONE
    stats_changed.emit()
    return true

func craft_metal_axe() -> bool:
    if get_item_count(TOOL_METAL) > 0:
        return false
    if get_item_count("wood") < 5 or get_item_count("stone") < 8:
        return false
    _remove_item("wood", 5)
    _remove_item("stone", 8)
    if not add_item(TOOL_METAL, 1):
        return false
    equipped_tool = TOOL_METAL
    stats_changed.emit()
    return true

func craft_metal_pickaxe() -> bool:
    if get_item_count(PICKAXE_METAL) > 0:
        return false
    if get_item_count(PICKAXE_STONE) < 1 or get_item_count("wood") < 5 or get_item_count("stone") < 8:
        return false
    _remove_item(PICKAXE_STONE, 1)
    _remove_item("wood", 5)
    _remove_item("stone", 8)
    if not add_item(PICKAXE_METAL, 1):
        return false
    equipped_tool = PICKAXE_METAL
    stats_changed.emit()
    return true

func _remove_item(item_id: String, amount: int) -> bool:
    if _count_item(item_id) < amount:
        return false
    var remaining := amount
    for i in range(inventory.size()):
        if inventory[i].get("id", "") != item_id:
            continue
        var take := mini(int(inventory[i]["count"]), remaining)
        inventory[i]["count"] = int(inventory[i]["count"]) - take
        remaining -= take
        if int(inventory[i]["count"]) <= 0:
            inventory[i] = {}
        if remaining <= 0:
            break
    _sync_resource_totals()
    return true

func get_season_thirst_multiplier() -> float:
    return float(SEASON_DATA.get(current_season, SEASON_DATA["primavera"]).get("thirst_mult", 1.0))

func get_season_temperature() -> String:
    return str(SEASON_DATA.get(current_season, SEASON_DATA["primavera"]).get("temp", "ameno"))

func _check_season_change() -> void:
    if day % DAYS_PER_SEASON != 0:
        return
    var current_index := SEASON_ORDER.find(current_season)
    if current_index < 0:
        current_index = 0
    current_season = SEASON_ORDER[(current_index + 1) % SEASON_ORDER.size()]
    season_changed.emit(current_season)
    print("[Estação] Mudou para: ", current_season)

func consume_survival(delta: float) -> void:
    elapsed += delta
    hunger = maxf(0.0, hunger - delta * 0.22)
    var thirst_mult := get_season_thirst_multiplier()
    thirst = maxf(0.0, thirst - delta * 0.34 * thirst_mult)
    if hunger <= 0.0 or thirst <= 0.0:
        health = maxf(0.0, health - delta * 1.8)
    if health <= 0.0 and not death_reported:
        death_reported = true
        player_died.emit()
    if elapsed >= 180.0:
        elapsed = 0.0
        day += 1
        _check_season_change()
    stats_changed.emit()

func save_game() -> void:
    var data := {
        "health": health, "hunger": hunger, "thirst": thirst,
        "wood": wood, "stone": stone, "day": day, "elapsed": elapsed,
        "current_season": current_season,
        "inventory": inventory, "equipped_tool": equipped_tool,
        "storage": StorageManager.chests_data,
        "equipped_armor": equipped_armor,
        "built_floors": built_floors,
        "built_objects": built_objects
    }
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
    day = int(parsed.get("day", 1))
    current_season = str(parsed.get("current_season", "primavera"))
    if current_season not in SEASON_ORDER:
        current_season = "primavera"
    elapsed = float(parsed.get("elapsed", 0.0))
    equipped_tool = str(parsed.get("equipped_tool", TOOL_STONE))
    equipped_armor = str(parsed.get("equipped_armor", ""))
    built_floors.clear()
    var saved_floors = parsed.get("built_floors", [])
    if saved_floors is Array:
        for saved_floor in saved_floors:
            if saved_floor is Dictionary:
                built_floors.append(saved_floor.duplicate())
    built_objects.clear()
    var saved_objects = parsed.get("built_objects", [])
    if saved_objects is Array:
        for saved_object in saved_objects:
            if saved_object is Dictionary:
                built_objects.append(saved_object.duplicate())
    StorageManager.chests_data = parsed.get("storage", {}) as Dictionary
    _reset_inventory()
    var saved_inventory = parsed.get("inventory", [])
    if saved_inventory is Array and not saved_inventory.is_empty():
        for i in range(mini(saved_inventory.size(), INVENTORY_CAPACITY)):
            if saved_inventory[i] is Dictionary:
                inventory[i] = saved_inventory[i].duplicate()
    else:
        add_item("stone_axe", 1)
        add_item("wood", int(parsed.get("wood", 0)))
        add_item("stone", int(parsed.get("stone", 0)))
    _sync_resource_totals()
    death_reported = health <= 0.0
    stats_changed.emit()
    return true

# Pequena pausa visual para destacar a ativação de uma habilidade.
func hit_stop(duration: float = 0.04) -> void:
    if Engine.time_scale == 0.0:
        return
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
