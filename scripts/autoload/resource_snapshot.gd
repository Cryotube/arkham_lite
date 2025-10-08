extends RefCounted
class_name ResourceSnapshot

var health: int
var max_health: int
var materials: int
var max_materials: int
var oxygen: int
var max_oxygen: int
var threat: int
var max_threat: int
var threshold_states: Dictionary[StringName, StringName]

func _init(
	health_value: int = 0,
	max_health_value: int = 0,
	materials_value: int = 0,
	max_materials_value: int = 0,
	oxygen_value: int = 0,
	max_oxygen_value: int = 0,
	threat_value: int = 0,
	max_threat_value: int = 0,
	states: Dictionary = {}
) -> void:
	health = health_value
	max_health = max_health_value
	materials = materials_value
	max_materials = max_materials_value
	oxygen = oxygen_value
	max_oxygen = max_oxygen_value
	threat = threat_value
	max_threat = max_threat_value
	threshold_states = {}
	for key in states.keys():
		var name_key: StringName = key
		threshold_states[name_key] = StringName(states[key])

func to_dictionary() -> Dictionary:
	return {
		"health": health,
		"max_health": max_health,
		"materials": materials,
		"max_materials": max_materials,
		"oxygen": oxygen,
		"max_oxygen": max_oxygen,
		"threat": threat,
		"max_threat": max_threat,
		"threshold_states": threshold_states.duplicate(true),
	}

func state_for(key: StringName) -> StringName:
	return threshold_states.get(key, "normal")
