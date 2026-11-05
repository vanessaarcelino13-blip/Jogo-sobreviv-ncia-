extends Node

# Dados persistentes por identificador de baú: { "base_chest": { "wood": 20 } }
var chests_data: Dictionary = {}

func get_chest(chest_id: String) -> Dictionary:
    if not chests_data.has(chest_id):
        chests_data[chest_id] = {}
    return chests_data[chest_id]

func save_to_chest(chest_id: String, item_id: String, quantity: int) -> void:
    if quantity <= 0:
        return
    var chest := get_chest(chest_id)
    chest[item_id] = int(chest.get(item_id, 0)) + quantity

func take_from_chest(chest_id: String, item_id: String, quantity: int) -> bool:
    var chest := get_chest(chest_id)
    if quantity <= 0 or int(chest.get(item_id, 0)) < quantity:
        return false
    chest[item_id] = int(chest[item_id]) - quantity
    if int(chest[item_id]) <= 0:
        chest.erase(item_id)
    return true
