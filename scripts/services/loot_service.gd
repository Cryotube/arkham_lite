extends Node

signal loot_awarded(loot: Dictionary)

const RARITY_TABLE: Dictionary = {
	"common": ["ion_blaster", "oxygen_siphon"],
	"uncommon": ["seeker_array"]
}

const ROOM_TAG_LOOT: Dictionary = {
	"cache": ["ion_blaster", "oxygen_siphon"],
	"clue": ["seeker_array"],
	"materials": ["ion_blaster"],
	"resource_gain": ["oxygen_siphon"]
}

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func roll_loot_for_room(room: Dictionary) -> Dictionary:
	var tags: Array = room.get("tags", []) as Array
	var candidates: Array[String] = []
	for tag in tags:
		var items: Array = ROOM_TAG_LOOT.get(tag, []) as Array
		for item in items:
			if item is String and not candidates.has(item):
				candidates.append(item)
	if candidates.is_empty():
		for pool_variant in RARITY_TABLE.values():
			var pool: Array = pool_variant as Array
			for item in pool:
				if item is String and not candidates.has(item):
					candidates.append(item)
	if candidates.is_empty():
		return {}
	var choice: String = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var rarity := _find_rarity(choice)
	var loot := {
		"id": choice,
		"rarity": rarity,
		"source_room": room.get("id", "")
	}
	loot_awarded.emit(loot)
	return loot

func _find_rarity(item_id: String) -> String:
	for rarity in RARITY_TABLE.keys():
		var pool := RARITY_TABLE[rarity] as Array
		if pool.has(item_id):
			return rarity
	return "unknown"
