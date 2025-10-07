extends Node

signal event_presented(event_data: Dictionary)
signal event_resolved(result: Dictionary)

var _active_event: Dictionary = {}

func present_event(event_data: Dictionary) -> void:
	_active_event = event_data.duplicate(true)
	event_presented.emit(_active_event.duplicate(true))

func resolve_choice(choice_id: String) -> Dictionary:
	if _active_event.is_empty():
		return {}
	var choices := _active_event.get("choices", []) as Array
	for choice in choices:
		if choice.get("id", "") == choice_id:
			var outcome := choice.get("outcome", {}) as Dictionary
			_active_event.clear()
			event_resolved.emit(outcome.duplicate(true))
			return outcome.duplicate(true)
	_active_event.clear()
	event_resolved.emit({})
	return {}

func get_active_event() -> Dictionary:
	return _active_event.duplicate(true)

func has_active_event() -> bool:
	return not _active_event.is_empty()
