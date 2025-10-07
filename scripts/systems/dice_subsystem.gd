extends Node3D
class_name DiceSubsystem

signal roll_started
signal roll_resolved(results: Array[int])
signal lock_state_changed(locked_indices: Array[int])

const DICE_POOL_SIZE: int = 3
const FACES_RESOURCE_PATH: String = "res://resources/dice/dice_face_set.tres"

class DieState:
    var value: int = 1
    var locked: bool = false
    var exhausted: bool = false

var _dice_states: Array[DieState] = []
var _cached_results: Array[int] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _faces: Array[int] = [1, 2, 3, 4, 5, 6]
var _initialized: bool = false
var _pool_cache_ref: Node = null

func _ready() -> void:
    _rng.randomize()
    _load_faces()
    _initialize_pool()
    set_physics_process(false)
    _initialized = true

func _load_faces() -> void:
    var resource := load(FACES_RESOURCE_PATH)
    if resource and resource.has_method("get_faces"):
        var faces: Array = resource.get_faces()
        if faces.size() > 0:
            _faces = faces.duplicate()

func _initialize_pool() -> void:
    _dice_states.clear()
    var templates := _ensure_pool_templates()
    for index in DICE_POOL_SIZE:
        var state := DieState.new()
        if index < templates.size():
            var template := templates[index]
            state.value = int(template.get("value", 1))
        _dice_states.append(state)
    _cached_results = [1, 1, 1]
    _initialized = true

func request_roll() -> void:
    _ensure_initialized()
    emit_signal("roll_started")
    _cached_results.clear()
    for index in _dice_states.size():
        var state := _dice_states[index]
        if state.exhausted:
            _cached_results.append(0)
            continue
        if not state.locked:
            state.value = _faces[_rng.randi_range(0, _faces.size() - 1)]
        _cached_results.append(state.value)
    emit_signal("roll_resolved", _cached_results.duplicate())

func set_die_locked(index: int, should_lock: bool) -> void:
    _ensure_initialized()
    if not _is_valid_index(index):
        return
    var state := _dice_states[index]
    if state.exhausted:
        return
    state.locked = should_lock
    lock_state_changed.emit(get_locked_indices())

func is_die_locked(index: int) -> bool:
    _ensure_initialized()
    if not _is_valid_index(index):
        return false
    return _dice_states[index].locked

func get_locked_indices() -> Array[int]:
    _ensure_initialized()
    var locked: Array[int] = []
    for index in _dice_states.size():
        if _dice_states[index].locked and not _dice_states[index].exhausted:
            locked.append(index)
    return locked

func exhaust_locked_dice() -> Array[int]:
    _ensure_initialized()
    var exhausted_indices: Array[int] = []
    for index in _dice_states.size():
        var state := _dice_states[index]
        if state.locked and not state.exhausted:
            state.locked = false
            state.exhausted = true
            exhausted_indices.append(index)
    return exhausted_indices

func refresh_exhausted_dice() -> void:
    _ensure_initialized()
    for state in _dice_states:
        state.exhausted = false
        state.locked = false
    _cached_results = [1, 1, 1]

func restore_die(index: int) -> void:
    if not _is_valid_index(index):
        return
    var state := _dice_states[index]
    state.exhausted = false
    state.locked = false

func get_results() -> Array[int]:
    _ensure_initialized()
    return _cached_results.duplicate()

func reset() -> void:
    _ensure_initialized()
    for state in _dice_states:
        state.locked = false
        state.exhausted = false
        state.value = 1
    _cached_results = [1, 1, 1]

func _ensure_pool_templates() -> Array[Dictionary]:
    if _pool_cache_ref == null or not is_instance_valid(_pool_cache_ref):
        _pool_cache_ref = _find_pool_cache()
    if _pool_cache_ref and _pool_cache_ref.has_method("ensure_pool"):
        return _pool_cache_ref.ensure_pool(DICE_POOL_SIZE)
    return []

func _find_pool_cache() -> Node:
    var tree := get_tree()
    if tree and tree.get_root().has_node("DicePoolCache"):
        return tree.get_root().get_node("DicePoolCache")
    return null

func _is_valid_index(index: int) -> bool:
    return index >= 0 and index < _dice_states.size()

func _ensure_initialized() -> void:
    if _dice_states.is_empty():
        _initialize_pool()
