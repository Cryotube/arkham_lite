extends Node

signal step_changed(step: Dictionary)
signal tutorial_completed()

@export var onboarding_steps: Array[Dictionary] = [
	{
		"id": "welcome",
		"title": "Welcome",
		"body": "Roll the dice with the bottom buttons. Lock dice before committing if you like the result."
	},
	{
		"id": "resources",
		"title": "Monitor Resources",
		"body": "Health, materials, oxygen, and threat live in the top bar. Keep oxygen above zero to survive."
	},
	{
		"id": "room_queue",
		"title": "Explore Rooms",
		"body": "Rooms on the left queue drive the run. Enter to claim rewards or cycle to push your luck."
	}
]

var _current_index: int = -1
var _completed: bool = false

func start_onboarding(force: bool = false) -> void:
	if _completed and not force:
		return
	_current_index = 0
	_emit_current_step()

func advance() -> void:
	if not _has_active_step():
		return
	_current_index += 1
	if _current_index >= onboarding_steps.size():
		_complete()
		return
	_emit_current_step()

func skip() -> void:
	_complete()

func restart() -> void:
	_completed = false
	start_onboarding(true)

func is_active() -> bool:
	return _has_active_step()

func has_completed() -> bool:
	return _completed

func _emit_current_step() -> void:
	if not _has_active_step():
		return
	var step: Dictionary = onboarding_steps[_current_index]
	step_changed.emit(step.duplicate(true))

func _complete() -> void:
	_completed = true
	_current_index = -1
	tutorial_completed.emit()

func _has_active_step() -> bool:
	return _current_index >= 0 and _current_index < onboarding_steps.size()
