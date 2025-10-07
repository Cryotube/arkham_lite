extends Node

signal preview_updated(state: StringName, cells: Array)
signal preview_cleared()
signal feedback_played(feedback_type: StringName)

var _valid_pool: Array = []
var _invalid_pool: Array = []
var _active_overlays: Array = []

func show_valid_preview(cells: Array) -> void:
	preview_updated.emit(&"valid", _duplicate_cells(cells))

func show_invalid_preview(cells: Array) -> void:
	preview_updated.emit(&"invalid", _duplicate_cells(cells))

func clear_preview() -> void:
	preview_cleared.emit()

func play_action_feedback(feedback_type: StringName) -> void:
	feedback_played.emit(feedback_type)

func _duplicate_cells(cells: Array) -> Array:
	var copy: Array[Vector2i] = []
	for cell in cells:
		copy.append(Vector2i(cell))
	return copy
