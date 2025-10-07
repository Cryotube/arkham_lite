extends Node

signal inventory_changed(carry: Array[Dictionary], installed: Dictionary)
signal grid_updated(grid: Array)
signal loadout_changed(loadout: Dictionary)
signal burden_changed(total_burden: int, state: StringName)
signal dice_binding_updated(slot: StringName, module_id: StringName)
signal placement_invalid(module_id: StringName, reason: StringName, conflicts: Array)

const ROTATIONS: Array[int] = [0, 90, 180, 270]

@export var config_path: String = "res://resources/config/equipment_matrix.tres"
@export var modules_path: String = "res://resources/equipment"

var _config: EquipmentMatrixConfig
var _catalog: Dictionary[StringName, EquipmentModuleResource] = {}
var _grid_width: int = 0
var _grid_height: int = 0
var _grid: Array = []
var _carry: Array[Dictionary] = []
var _installed: Dictionary[StringName, Dictionary] = {}
var _total_burden: int = 0
var _burden_state: StringName = &"safe"
var _telemetry_hub: Node = null

func _ready() -> void:
	_load_config()
	_load_catalog()
	reset()

func reset() -> void:
	_grid_width = max(1, _config.grid_width)
	_grid_height = max(1, _config.grid_height)
	_grid = []
	for _y in _grid_height:
		var row: Array = []
		for _x in _grid_width:
			row.append(null)
		_grid.append(row)
	_carry.clear()
	_installed.clear()
	_total_burden = max(0, _config.base_burden)
	_burden_state = _evaluate_burden_state(_total_burden)
	_emit_all()

func get_catalog() -> Dictionary:
	var result: Dictionary = {}
	for module_id in _catalog.keys():
		var module: EquipmentModuleResource = _catalog[module_id]
		result[module_id] = _module_to_dictionary(module)
	return result

func get_grid() -> Array:
	var duplicate_grid: Array = []
	for row in _grid:
		duplicate_grid.append(row.duplicate())
	return duplicate_grid

func get_carry_items() -> Array:
	var copy: Array[Dictionary] = []
	for entry in _carry:
		copy.append(entry.duplicate(true))
	return copy

func get_installed_items() -> Dictionary:
	return _installed.duplicate(true)

func get_total_burden() -> int:
	return _total_burden

func get_burden_state() -> StringName:
	return _burden_state

func add_loot(module_id: StringName) -> void:
	var normalized_id: StringName = _normalize_module_id(module_id)
	var module: EquipmentModuleResource = _catalog.get(normalized_id, null)
	if module == null:
		return
	_carry.append(_module_to_dictionary(module))
	_emit_inventory()

func remove_installed(module_id: StringName) -> void:
	var normalized_id: StringName = _normalize_module_id(module_id)
	var installed_entry: Dictionary = _installed.get(normalized_id, {})
	if installed_entry.is_empty():
		return
	var cells: Array = installed_entry.get("cells", [])
	for cell_variant in cells:
		var cell := Vector2i(cell_variant)
		if _is_cell_inside(cell):
			_grid[cell.y][cell.x] = null
	_installed.erase(normalized_id)
	_apply_burden_delta(-int(installed_entry.get("burden", 0)))
	_emit_inventory()
	_emit_grid()
	_emit_loadout()

func can_place(module_id: StringName, origin: Vector2i, rotation: int = 0) -> bool:
	var normalized_id: StringName = _normalize_module_id(module_id)
	var result: Dictionary = evaluate_placement(normalized_id, origin, rotation)
	return bool(result.get("valid", false))

func place_item(module_id: StringName, origin: Vector2i, rotation: int = 0) -> bool:
	var normalized_id: StringName = _normalize_module_id(module_id)
	var result: Dictionary = evaluate_placement(normalized_id, origin, rotation)
	if not result.get("valid", false):
		placement_invalid.emit(normalized_id, result.get("reason", "invalid"), result.get("conflicts", []))
		return false
	_commit_placement(normalized_id, result)
	return true

func evaluate_placement(module_id: StringName, origin: Vector2i, rotation: int) -> Dictionary:
	var normalized_id: StringName = _normalize_module_id(module_id)
	var module: EquipmentModuleResource = _catalog.get(normalized_id, null)
	if module == null:
		return {
			"valid": false,
			"reason": "unknown_module",
			"footprint": [],
			"conflicts": [],
		}
	var normalized_rotation := _normalize_rotation(rotation)
	if not _config.can_rotate(normalized_id) and normalized_rotation != 0:
		return {
			"valid": false,
			"reason": "rotation_locked",
			"footprint": [],
			"conflicts": [],
		}
	var offsets: Array[Vector2i] = _get_rotated_mask(module, normalized_rotation)
	var footprint: Array[Vector2i] = []
	var conflicts: Array[Vector2i] = []
	var reason: StringName = &"valid"
	for offset in offsets:
		var cell := origin + offset
		footprint.append(cell)
		if not _is_cell_inside(cell):
			conflicts.append(cell)
			reason = &"out_of_bounds"
		elif _grid[cell.y][cell.x] != null:
			conflicts.append(cell)
			reason = &"occupied"
	if not conflicts.is_empty():
		return {
			"valid": false,
			"reason": reason,
			"footprint": footprint,
			"conflicts": conflicts,
		}
	return {
		"valid": true,
		"reason": &"valid",
		"footprint": footprint,
		"conflicts": [],
		"rotation": normalized_rotation,
	}

func get_snapshot() -> Dictionary:
	return {
		"carry": get_carry_items(),
		"installed": get_installed_items(),
		"grid": get_grid(),
		"total_burden": _total_burden,
		"burden_state": String(_burden_state),
	}

func apply_snapshot(snapshot: Dictionary) -> void:
	reset()
	var carry_snapshot := snapshot.get("carry", []) as Array
	_carry.clear()
	for entry in carry_snapshot:
		if typeof(entry) == TYPE_DICTIONARY:
			_carry.append((entry as Dictionary).duplicate(true))
	var installed_snapshot := snapshot.get("installed", {}) as Dictionary
	_installed.clear()
	for module_id in installed_snapshot.keys():
		var entry: Dictionary = installed_snapshot.get(module_id, {})
		var cells: Array = entry.get("cells", [])
		for cell_variant in cells:
			var cell := Vector2i(cell_variant)
			if _is_cell_inside(cell):
				_grid[cell.y][cell.x] = module_id
		_installed[module_id] = entry.duplicate(true)
	_total_burden = int(snapshot.get("total_burden", _config.base_burden))
	_burden_state = StringName(snapshot.get("burden_state", "safe"))
	_emit_all()

func get_slot_bindings() -> Dictionary:
	var bindings: Dictionary = {}
	for module_id in _installed.keys():
		bindings[module_id] = _config.get_slot_tags(module_id)
	return bindings

func get_burden_thresholds() -> Dictionary:
	return {
		"strained": _config.strained_threshold,
		"critical": _config.critical_threshold,
	}

func _commit_placement(module_id: StringName, result: Dictionary) -> void:
	var module: EquipmentModuleResource = _catalog[module_id]
	var rotation: int = int(result.get("rotation", 0))
	var footprint: Array = result.get("footprint", [])
	for cell_variant in footprint:
		var cell := Vector2i(cell_variant)
		if _is_cell_inside(cell):
			_grid[cell.y][cell.x] = module_id
	var origin_cell := Vector2i.ZERO
	if not footprint.is_empty():
		origin_cell = Vector2i(footprint[0])
	var installed_entry := {
		"id": String(module.module_id),
		"name": module.display_name,
		"rotation": rotation,
		"origin": origin_cell,
		"cells": footprint,
		"burden": module.burden,
		"dice_costs": module.dice_costs.duplicate(),
		"passive_slots": module.passive_slots.duplicate(),
	}
	_installed[module_id] = installed_entry
	_remove_from_carry(module_id)
	_apply_burden_delta(module.burden)
	_emit_inventory()
	_emit_grid()
	_emit_loadout()
	_emit_slot_bindings(module_id)
	_record_telemetry("matrix_module_equipped", {
		"module_id": String(module.module_id),
		"rotation": rotation,
		"burden_total": _total_burden,
	})

func _emit_slot_bindings(module_id: StringName) -> void:
	var bindings := _config.get_slot_tags(module_id)
	for slot in bindings:
		dice_binding_updated.emit(slot, module_id)

func _apply_burden_delta(delta: int) -> void:
	if delta == 0:
		return
	_total_burden = max(0, _total_burden + delta)
	var previous_state := _burden_state
	_burden_state = _evaluate_burden_state(_total_burden)
	if previous_state != _burden_state or delta != 0:
		burden_changed.emit(_total_burden, _burden_state)
		_record_telemetry("matrix_burden_changed", {
			"total": _total_burden,
			"state": String(_burden_state),
			"delta": delta,
		})

func _emit_inventory() -> void:
	inventory_changed.emit(get_carry_items(), get_installed_items())

func _emit_grid() -> void:
	grid_updated.emit(get_grid())

func _emit_loadout() -> void:
	var loadout := {
		"total_burden": _total_burden,
		"state": String(_burden_state),
		"installed": get_installed_items(),
	}
	loadout_changed.emit(loadout)

func _emit_all() -> void:
	_emit_inventory()
	_emit_grid()
	_emit_loadout()
	burden_changed.emit(_total_burden, _burden_state)

func _get_rotated_mask(module: EquipmentModuleResource, rotation: int) -> Array[Vector2i]:
	var base_mask := module.get_mask()
	var rotated: Array[Vector2i] = []
	for cell in base_mask:
		var rotated_cell := _rotate_cell(cell, rotation)
		rotated.append(rotated_cell)
	return _normalize_mask(rotated)

func _normalize_mask(mask: Array[Vector2i]) -> Array[Vector2i]:
	if mask.is_empty():
		return mask
	var min_x := mask[0].x
	var min_y := mask[0].y
	for cell in mask:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
	var normalized: Array[Vector2i] = []
	for cell in mask:
		normalized.append(Vector2i(cell.x - min_x, cell.y - min_y))
	return normalized

func _rotate_cell(cell: Vector2i, rotation: int) -> Vector2i:
	match rotation:
		90:
			return Vector2i(-cell.y, cell.x)
		180:
			return Vector2i(-cell.x, -cell.y)
		270:
			return Vector2i(cell.y, -cell.x)
		_:
			return Vector2i(cell)

func _is_cell_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < _grid_width and cell.y >= 0 and cell.y < _grid_height

func _remove_from_carry(module_id: StringName) -> void:
	for index in _carry.size():
		var entry: Dictionary = _carry[index]
		if _normalize_module_id(entry.get("id", "")) == module_id:
			_carry.remove_at(index)
			return

func _normalize_rotation(rotation: int) -> int:
	var normalized: int = abs(rotation) % 360
	if normalized == 0:
		return 0
	if normalized == 90 or normalized == 180 or normalized == 270:
		return normalized
	return 0

func _evaluate_burden_state(total: int) -> StringName:
	if total >= _config.critical_threshold:
		return &"critical"
	if total >= _config.strained_threshold:
		return &"strained"
	return &"safe"

func _module_to_dictionary(module: EquipmentModuleResource) -> Dictionary:
	return {
		"id": String(module.module_id),
		"name": module.display_name,
		"description": module.description,
		"shape": module.get_mask(),
		"burden": module.burden,
		"dice_costs": module.dice_costs.duplicate(),
		"passive_slots": module.passive_slots.duplicate(),
		"allow_rotation": module.allow_rotation,
	}

func _load_config() -> void:
	var resource := load(config_path)
	if resource is EquipmentMatrixConfig:
		_config = resource
	else:
		_config = EquipmentMatrixConfig.new()

func _load_catalog() -> void:
	_catalog.clear()
	var dir := DirAccess.open(modules_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if dir.current_is_dir():
			continue
		if not (entry.ends_with(".tres") or entry.ends_with(".res")):
			continue
		var resource := load("%s/%s" % [modules_path, entry])
		if resource is EquipmentModuleResource:
			var module: EquipmentModuleResource = resource
			_catalog[module.module_id] = module
	dir.list_dir_end()

func _record_telemetry(event_name: String, payload: Dictionary) -> void:
	if _telemetry_hub == null or not is_instance_valid(_telemetry_hub):
		_telemetry_hub = _resolve_node("TelemetryHub")
	if _telemetry_hub and _telemetry_hub.has_method("record"):
		_telemetry_hub.call("record", event_name, payload.duplicate(true))

func _resolve_node(node_name: StringName) -> Node:
	if get_tree() == null:
		return null
	var root := get_tree().get_root()
	if root == null:
		return null
	var path := NodePath(String(node_name))
	if root.has_node(path):
		return root.get_node(path)
	return null

func _normalize_module_id(module_id: Variant) -> StringName:
	return StringName(module_id)
