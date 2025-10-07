extends Node
class_name TurnManager

const DiceSubsystem = preload("res://scripts/systems/dice_subsystem.gd")

enum TurnState { IDLE, ROLL_PREP, ROLLING, ACTION, RESOLUTION }

signal turn_started(state: TurnState)
signal dice_committed(results: Array[int])
signal dice_locked_changed(locked_indices: Array[int])
signal turn_completed

var _dice_subsystem = null
var _hud_controller = null
var _state: TurnState = TurnState.IDLE
var _current_results: Array[int] = []
var _exhausted_indices: Array[int] = []

func initialize(dice_subsystem, hud_controller) -> void:
	_dice_subsystem = dice_subsystem
	_hud_controller = hud_controller
	if not _dice_subsystem.roll_resolved.is_connected(_on_roll_resolved):
		_dice_subsystem.roll_resolved.connect(_on_roll_resolved)
	if not _dice_subsystem.lock_state_changed.is_connected(_on_lock_state_changed):
		_dice_subsystem.lock_state_changed.connect(_on_lock_state_changed)
	_reset_state()

func start_new_run() -> void:
	_reset_state()
	start_turn()

func start_turn() -> void:
	_state = TurnState.ROLL_PREP
	_exhausted_indices.clear()
	_dice_subsystem.reset()
	if _hud_controller != null:
		_hud_controller.reset_hud_state()
	turn_started.emit(_state)

func request_roll() -> void:
	if _state in [TurnState.RESOLUTION, TurnState.ROLLING]:
		return
	if _dice_subsystem == null:
		return
	if not _exhausted_indices.is_empty():
		_dice_subsystem.refresh_exhausted_dice()
		_exhausted_indices.clear()
	_state = TurnState.ROLLING
	_dice_subsystem.request_roll()

func toggle_lock(index: int) -> void:
	if _state != TurnState.ACTION:
		return
	if _dice_subsystem == null:
		return
	var should_lock = not _dice_subsystem.is_die_locked(index)
	_dice_subsystem.set_die_locked(index, should_lock)
	_update_hud()

func commit_dice() -> void:
	if _state != TurnState.ACTION:
		return
	if _dice_subsystem == null:
		return
	var newly_exhausted = _dice_subsystem.exhaust_locked_dice()
	for index in newly_exhausted:
		if index not in _exhausted_indices:
			_exhausted_indices.append(index)
	dice_committed.emit(_current_results.duplicate())
	_apply_roll_outcome()
	_update_hud()
	if _exhausted_indices.size() >= DiceSubsystem.DICE_POOL_SIZE:
		_state = TurnState.RESOLUTION
		turn_completed.emit()
	else:
		_state = TurnState.ROLL_PREP

func _on_roll_resolved(results: Array[int]) -> void:
	if _dice_subsystem == null:
		return
	_current_results = results.duplicate()
	_state = TurnState.ACTION
	_update_hud()

func _on_lock_state_changed(_locked: Array[int]) -> void:
	dice_locked_changed.emit(_locked.duplicate())
	_update_hud()

func _update_hud() -> void:
	if _hud_controller == null or _dice_subsystem == null:
		return
	var locked = _dice_subsystem.get_locked_indices()
	_hud_controller.update_for_roll(_current_results, locked, _exhausted_indices)

func _reset_state() -> void:
	_current_results = [1, 1, 1]
	_exhausted_indices.clear()
	_state = TurnState.IDLE

func _apply_roll_outcome() -> void:
	var ledger = _get_resource_ledger()
	if ledger:
		ledger.apply_roll_outcome(_current_results)

func _get_resource_ledger():
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null:
		return null
	var root := tree.get_root()
	if root and root.has_node("ResourceLedger"):
		return root.get_node("ResourceLedger")
	return null

func get_state() -> TurnState:
	return _state

func get_current_results() -> Array[int]:
	return _current_results.duplicate()

func get_exhausted_indices() -> Array[int]:
	return _exhausted_indices.duplicate()
