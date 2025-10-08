extends RefCounted
class_name ResourceTelemetryPayload

var category: StringName
var current: int
var max_value: int
var state: StringName
var extra: Dictionary[StringName, Variant]

func _init(
	category_name: StringName,
	current_value: int,
	maximum_value: int,
	state_name: StringName = "stable",
	extra_payload: Dictionary = {}
) -> void:
	category = category_name
	current = current_value
	max_value = maximum_value
	state = state_name
	extra = {}
	for key in extra_payload.keys():
		extra[StringName(key)] = extra_payload[key]

func to_dictionary() -> Dictionary:
	var payload := {
		"category": String(category),
		"current": current,
		"max": max_value,
		"state": String(state),
	}
	if not extra.is_empty():
		payload["extra"] = extra.duplicate(true)
	return payload
