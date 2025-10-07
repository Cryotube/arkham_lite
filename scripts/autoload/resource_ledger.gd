extends Node
class_name ResourceLedgerSingleton

signal health_changed(current: int, max: int)
signal materials_changed(current: int, max: int)
signal oxygen_changed(current: int, max: int)
signal threat_changed(current: int, max: int)
signal threat_threshold_crossed(level: StringName)

@export var max_health: int = 8
@export var max_materials: int = 12
@export var max_oxygen: int = 6
@export var max_threat: int = 100

var _health: int = 0
var _materials: int = 0
var _oxygen: int = 0
var _threat: int = 0

var _threshold_states: Dictionary[StringName, StringName] = {
	"health": "normal",
	"materials": "normal",
	"oxygen": "normal",
	"threat": "normal",
}

var _warning_threshold: float = 0.5
var _critical_threshold: float = 0.25
var _threat_warning_threshold: float = 0.6
var _threat_critical_threshold: float = 0.85

var _save_service: Node = null

func _ready() -> void:
	_resolve_save_service()
	var service = _save_service_stub()
	if service and service.has_method("has_run_snapshot") and service.has_run_snapshot():
		_apply_snapshot(service.get_run_snapshot())
	else:
		reset()

func set_save_service(service: Node) -> void:
	_save_service = service

func reset() -> void:
	_health = max_health
	_materials = max_materials
	_oxygen = max_oxygen
	_threat = 0
	_emit_all_changes()
	_persist_state()

func start_new_run(force_reset: bool = false) -> void:
	_resolve_save_service()
	var service = _save_service_stub()
	if force_reset or not service or not (service.has_method("has_run_snapshot") and service.has_run_snapshot()):
		reset()
		return
	_apply_snapshot(service.get_run_snapshot())

func set_health(value: int) -> void:
	var clamped: int = clamp(value, 0, max_health)
	var out_of_bounds: bool = value != clamped
	if clamped == _health and not out_of_bounds:
		return
	_health = clamped
	health_changed.emit(_health, max_health)
	_update_threshold_state("health", _health, max_health)
	_persist_state()

func adjust_health(delta: int) -> void:
	set_health(_health + delta)

func set_materials(value: int) -> void:
	var clamped: int = clamp(value, 0, max_materials)
	var out_of_bounds: bool = value != clamped
	if clamped == _materials and not out_of_bounds:
		return
	_materials = clamped
	materials_changed.emit(_materials, max_materials)
	_update_threshold_state("materials", _materials, max_materials)
	_persist_state()

func adjust_materials(delta: int) -> void:
	set_materials(_materials + delta)

func set_oxygen(value: int) -> void:
	var clamped: int = clamp(value, 0, max_oxygen)
	var out_of_bounds: bool = value != clamped
	if clamped == _oxygen and not out_of_bounds:
		return
	_oxygen = clamped
	oxygen_changed.emit(_oxygen, max_oxygen)
	_update_threshold_state("oxygen", _oxygen, max_oxygen)
	_persist_state()

func adjust_oxygen(delta: int) -> void:
	set_oxygen(_oxygen + delta)

func set_threat(value: int) -> void:
	var clamped: int = clamp(value, 0, max_threat)
	var out_of_bounds: bool = value != clamped
	if clamped == _threat and not out_of_bounds:
		return
	var previous_state: StringName = _threshold_states.get("threat", "normal")
	_threat = clamped
	threat_changed.emit(_threat, max_threat)
	_update_threshold_state("threat", _threat, max_threat)
	var current_state: StringName = _threshold_states.get("threat", "normal")
	if current_state != previous_state:
		threat_threshold_crossed.emit(current_state)
	_persist_state()

func adjust_threat(delta: int) -> void:
	set_threat(_threat + delta)

func apply_roll_outcome(results: Array[int]) -> void:
	# Basic placeholder logic: dice sum translates to material gains,
	# spending oxygen each action and slowly advancing threat.
	var earned_materials: int = 0
	for value in results:
		earned_materials += int(value)
	if earned_materials > 0:
		adjust_materials(earned_materials / 3)
	adjust_oxygen(-1)
	adjust_threat(1)

func get_snapshot() -> Dictionary:
	return {
		"health": _health,
		"materials": _materials,
		"oxygen": _oxygen,
		"threat": _threat,
	}

func get_health() -> int:
	return _health

func get_materials() -> int:
	return _materials

func get_oxygen() -> int:
	return _oxygen

func get_threat() -> int:
	return _threat

func _apply_snapshot(snapshot: Dictionary) -> void:
	_health = clamp(int(snapshot.get("health", max_health)), 0, max_health)
	_materials = clamp(int(snapshot.get("materials", max_materials)), 0, max_materials)
	_oxygen = clamp(int(snapshot.get("oxygen", max_oxygen)), 0, max_oxygen)
	_threat = clamp(int(snapshot.get("threat", 0)), 0, max_threat)
	_emit_all_changes()

func _emit_all_changes() -> void:
	health_changed.emit(_health, max_health)
	materials_changed.emit(_materials, max_materials)
	oxygen_changed.emit(_oxygen, max_oxygen)
	threat_changed.emit(_threat, max_threat)
	_update_threshold_state("health", _health, max_health, true)
	_update_threshold_state("materials", _materials, max_materials, true)
	_update_threshold_state("oxygen", _oxygen, max_oxygen, true)
	_update_threshold_state("threat", _threat, max_threat, true)

func _update_threshold_state(key: StringName, current: int, max_value: int, force: bool = false) -> void:
	var ratio: float = 0.0
	if max_value > 0:
		ratio = float(current) / float(max_value)
	var state: StringName = "normal"
	if key == "threat":
		if ratio >= _threat_critical_threshold:
			state = "critical"
		elif ratio >= _threat_warning_threshold:
			state = "warning"
	else:
		if ratio <= _critical_threshold:
			state = "critical"
		elif ratio <= _warning_threshold:
			state = "warning"
	if force or _threshold_states.get(key, "normal") != state:
		_threshold_states[key] = state

func _persist_state() -> void:
	var service = _save_service_stub()
	if service and service.has_method("store_run_snapshot"):
		service.store_run_snapshot(get_snapshot())

func _resolve_save_service() -> void:
	if _save_service != null:
		return
	var tree := get_tree()
	if tree == null:
		return
	var root := tree.get_root()
	if root and root.has_node("SaveService"):
		_save_service = root.get_node("SaveService")

func _save_service_stub():
	return _save_service
