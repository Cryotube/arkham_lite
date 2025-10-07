extends Node

signal inventory_changed(carry: Array[Dictionary], installed: Dictionary)
signal grid_updated(grid: Array)

const GRID_WIDTH: int = 6
const GRID_HEIGHT: int = 5

const ITEMS: Dictionary = {
	"ion_blaster": {
		"name": "Ion Blaster",
		"shape": [Vector2i(0, 0), Vector2i(1, 0)],
		"cost": {"materials": 1, "die": "strength"},
		"description": "Spend a Strength die to deal +2 damage."
	},
	"seeker_array": {
		"name": "Seeker Array",
		"shape": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
		"cost": {"die": "intellect"},
		"description": "Convert an Intellect die into a clue."
	},
	"oxygen_siphon": {
		"name": "Oxygen Siphon",
		"shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
		"cost": {"materials": 2},
		"description": "Recover 1 oxygen after exhausting a die."
	}
}

var _grid: Array = []
var _installed: Dictionary = {}
var _carry: Array[Dictionary] = []

func _ready() -> void:
	reset()

func reset() -> void:
	_grid = []
	for _row in GRID_HEIGHT:
		var row: Array = []
		for _col in GRID_WIDTH:
			row.append(null)
		_grid.append(row)
	_installed.clear()
	_carry.clear()
	_emit_updates()

func get_catalog() -> Dictionary:
	return ITEMS

func get_grid() -> Array:
	return _duplicate_grid()

func get_installed_items() -> Dictionary:
	return _installed.duplicate(true)

func get_carry_items() -> Array:
	var dup: Array[Dictionary] = []
	for item in _carry:
		dup.append(item.duplicate(true))
	return dup

func add_loot(item_id: String) -> void:
	if not ITEMS.has(item_id):
		return
	_carry.append(_build_carry_entry(item_id))
	_emit_updates()

func remove_installed(item_id: String) -> void:
	var entry_variant: Variant = _installed.get(item_id, null)
	if typeof(entry_variant) != TYPE_DICTIONARY:
		return
	var entry: Dictionary = entry_variant
	var cells: Array = entry.get("cells", [])
	for cell in cells:
		var grid_cell := Vector2i(cell)
		_grid[grid_cell.y][grid_cell.x] = null
	_installed.erase(item_id)
	_emit_updates()

func place_item(item_id: String, origin: Vector2i, rotation: int = 0) -> bool:
	if not _has_in_carry(item_id):
		return false
	var shape: Array[Vector2i] = _get_rotated_shape(item_id, rotation)
	if shape.is_empty():
		return false
	if not _fits(shape, origin):
		return false
	_commit_item(item_id, shape, origin, rotation)
	_remove_from_carry(item_id)
	_emit_updates()
	return true

func can_place(item_id: String, origin: Vector2i, rotation: int = 0) -> bool:
	if not _has_in_carry(item_id):
		return false
	var shape: Array[Vector2i] = _get_rotated_shape(item_id, rotation)
	if shape.is_empty():
		return false
	return _fits(shape, origin)

func _commit_item(item_id: String, shape: Array[Vector2i], origin: Vector2i, rotation: int) -> void:
	var occupied: Array[Vector2i] = []
	for offset in shape:
		var cell := origin + offset
		_grid[cell.y][cell.x] = item_id
		occupied.append(cell)
	_installed[item_id] = {
		"id": item_id,
		"name": ITEMS[item_id].get("name", item_id.capitalize()),
		"rotation": rotation,
		"cells": occupied
	}

func _fits(shape: Array[Vector2i], origin: Vector2i) -> bool:
	for offset in shape:
		var cell := origin + offset
		if cell.x < 0 or cell.x >= GRID_WIDTH:
			return false
		if cell.y < 0 or cell.y >= GRID_HEIGHT:
			return false
		if _grid[cell.y][cell.x] != null:
			return false
	return true

func _get_rotated_shape(item_id: String, rotation: int) -> Array[Vector2i]:
	var base := ITEMS.get(item_id, {}).get("shape", []) as Array
	var result: Array[Vector2i] = []
	for vec in base:
		var cell := Vector2i(vec)
		match rotation % 360:
			90, -270:
				cell = Vector2i(-vec.y, vec.x)
			180, -180:
				cell = Vector2i(-vec.x, -vec.y)
			270, -90:
				cell = Vector2i(vec.y, -vec.x)
			_:
				cell = Vector2i(vec)
		result.append(cell)
	return _normalize_shape(result)

func _normalize_shape(shape: Array[Vector2i]) -> Array[Vector2i]:
	if shape.is_empty():
		return shape
	var min_x := shape[0].x
	var min_y := shape[0].y
	for cell in shape:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
	var adjusted: Array[Vector2i] = []
	for cell in shape:
		adjusted.append(Vector2i(cell.x - min_x, cell.y - min_y))
	return adjusted

func _has_in_carry(item_id: String) -> bool:
	for entry in _carry:
		if entry.get("id", "") == item_id:
			return true
	return false

func _remove_from_carry(item_id: String) -> void:
	for index in _carry.size():
		if _carry[index].get("id", "") == item_id:
			_carry.remove_at(index)
			return

func _build_carry_entry(item_id: String) -> Dictionary:
	var data: Dictionary = ITEMS[item_id]
	return {
		"id": item_id,
		"name": data.get("name", item_id.capitalize()),
		"description": data.get("description", ""),
		"shape": data.get("shape", []),
		"cost": data.get("cost", {})
	}

func _duplicate_grid() -> Array:
	var copy: Array = []
	for row in _grid:
		copy.append(row.duplicate())
	return copy

func _emit_updates() -> void:
	inventory_changed.emit(get_carry_items(), get_installed_items())
	grid_updated.emit(get_grid())
