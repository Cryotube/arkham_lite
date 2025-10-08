extends Node3D
class_name DiceSubsystem

signal roll_started
signal roll_resolved(results: Array[int])
signal lock_state_changed(locked_indices: Array[int])
signal hold_state_changed(held_indices: Array[int])

const DICE_POOL_SIZE: int = 3
const FACES_RESOURCE_PATH: String = "res://resources/dice/dice_face_set.tres"
const DIE_SCENE_PATH: String = "res://scenes/dice/die_3d.tscn"

class DieState:
    var value: int = 1
    var locked: bool = false
    var held: bool = false
    var exhausted: bool = false

var _dice_states: Array[DieState] = []
var _cached_results: Array[int] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _faces: Array[int] = [1, 2, 3, 4, 5, 6]
var _initialized: bool = false
var _pool_cache_ref: Node = null
var _die_scene: PackedScene = null
var _dice_nodes: Array[DieController] = []
var _reduced_motion: bool = false
var _pending_roll_indices: Array[int] = []
var _rolling: bool = false

func _ready() -> void:
    _rng.randomize()
    _load_faces()
    _initialize_pool()
    _ensure_visual_dice()
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
    _pending_roll_indices.clear()
    _rolling = false
    _sync_visuals(_cached_results, false)

func request_roll() -> void:
    _ensure_initialized()
    if _rolling:
        return
    emit_signal("roll_started")
    _pending_roll_indices.clear()
    var next_results: Array[int] = []
    for index in _dice_states.size():
        var state := _dice_states[index]
        if state.exhausted:
            next_results.append(0)
            _sync_die_value(index, state.value)
            continue
        if state.locked or state.held:
            next_results.append(state.value)
            _sync_die_value(index, state.value)
            continue
        var provisional := state.value
        if not _begin_physics_roll(index):
            provisional = _roll_without_physics(index)
            state.value = provisional
        next_results.append(provisional)
    _cached_results = next_results
    if _pending_roll_indices.is_empty():
        _rolling = false
        emit_signal("roll_resolved", _cached_results.duplicate())
    else:
        _rolling = true

func set_die_locked(index: int, should_lock: bool) -> void:
    _ensure_initialized()
    if not _is_valid_index(index):
        return
    var state := _dice_states[index]
    if state.exhausted:
        return
    if state.locked == should_lock:
        return
    var previous_held := state.held
    if should_lock:
        state.held = false
    state.locked = should_lock
    _set_die_lock_visual(index, should_lock)
    _set_die_hold_visual(index, state.held)
    lock_state_changed.emit(get_locked_indices())
    if previous_held != state.held:
        hold_state_changed.emit(get_held_indices())

func set_die_held(index: int, should_hold: bool) -> void:
    _ensure_initialized()
    if not _is_valid_index(index):
        return
    var state := _dice_states[index]
    if state.exhausted:
        return
    if should_hold == state.held:
        return
    if should_hold:
        state.locked = false
    state.held = should_hold
    _set_die_hold_visual(index, should_hold)
    if not should_hold:
        _set_die_lock_visual(index, state.locked)
    hold_state_changed.emit(get_held_indices())

func is_die_locked(index: int) -> bool:
    _ensure_initialized()
    if not _is_valid_index(index):
        return false
    return _dice_states[index].locked

func is_die_held(index: int) -> bool:
    _ensure_initialized()
    if not _is_valid_index(index):
        return false
    return _dice_states[index].held

func get_locked_indices() -> Array[int]:
    _ensure_initialized()
    var locked: Array[int] = []
    for index in _dice_states.size():
        if _dice_states[index].locked and not _dice_states[index].exhausted:
            locked.append(index)
    return locked

func get_held_indices() -> Array[int]:
    _ensure_initialized()
    var held: Array[int] = []
    for index in _dice_states.size():
        if _dice_states[index].held and not _dice_states[index].exhausted:
            held.append(index)
    return held

func exhaust_locked_dice() -> Array[int]:
    _ensure_initialized()
    var exhausted_indices: Array[int] = []
    for index in _dice_states.size():
        var state := _dice_states[index]
        if state.locked and not state.exhausted:
            state.locked = false
            state.held = false
            state.exhausted = true
            exhausted_indices.append(index)
            _set_die_lock_visual(index, false)
            _set_die_hold_visual(index, false)
            _set_die_exhaust_visual(index, true)
    if not exhausted_indices.is_empty():
        hold_state_changed.emit(get_held_indices())
    return exhausted_indices

func refresh_exhausted_dice() -> void:
    _ensure_initialized()
    for state in _dice_states:
        state.exhausted = false
        state.locked = false
        state.held = false
    _cached_results = [1, 1, 1]
    for die in _dice_nodes:
        if die:
            die.clear_state()
    _sync_visuals(_cached_results, false)
    hold_state_changed.emit(get_held_indices())

func restore_die(index: int) -> void:
    if not _is_valid_index(index):
        return
    var state := _dice_states[index]
    state.exhausted = false
    state.locked = false
    state.held = false
    _set_die_exhaust_visual(index, false)
    _set_die_lock_visual(index, false)
    _set_die_hold_visual(index, false)
    hold_state_changed.emit(get_held_indices())

func get_results() -> Array[int]:
    _ensure_initialized()
    return _cached_results.duplicate()

func reset() -> void:
    _ensure_initialized()
    for state in _dice_states:
        state.locked = false
        state.held = false
        state.exhausted = false
        state.value = 1
    _cached_results = [1, 1, 1]
    _pending_roll_indices.clear()
    _rolling = false
    _sync_visuals(_cached_results, false)
    hold_state_changed.emit(get_held_indices())

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

func _ensure_visual_dice() -> void:
    if not _die_scene:
        _die_scene = load(DIE_SCENE_PATH)
    if not _die_scene:
        return
    if _dice_nodes.size() == DICE_POOL_SIZE:
        return
    for existing in _dice_nodes:
        if is_instance_valid(existing):
            existing.queue_free()
    _dice_nodes.clear()
    for index in DICE_POOL_SIZE:
        var die_instance: DieController = _die_scene.instantiate()
        if not die_instance:
            continue
        die_instance.position = Vector3((index - (DICE_POOL_SIZE - 1) * 0.5) * 1.6, 0.6, 0)
        die_instance.reduced_motion = _reduced_motion
        add_child(die_instance)
        die_instance.set_value(_dice_states[index].value, true)
        _dice_nodes.append(die_instance)

func _sync_visuals(results: Array[int], animate: bool) -> void:
    if _dice_nodes.is_empty():
        return
    for index in min(results.size(), _dice_nodes.size()):
        var die := _dice_nodes[index]
        if not die:
            continue
        var value := int(results[index])
        die.set_value(value, true)

func _sync_die_value(index: int, value: int) -> void:
    if index < 0 or index >= _dice_nodes.size():
        return
    var die := _dice_nodes[index]
    if die == null:
        return
    die.set_value(value, true)

func _begin_physics_roll(index: int) -> bool:
    if index < 0 or index >= _dice_states.size():
        return false
    if index >= _dice_nodes.size():
        return false
    var die := _dice_nodes[index]
    if die == null:
        return false
    var target_value := _faces[_rng.randi_range(0, _faces.size() - 1)]
    die.roll_completed.connect(_on_die_roll_completed.bind(index), Object.CONNECT_ONE_SHOT)
    _pending_roll_indices.append(index)
    die.roll_to(target_value)
    return true

func _roll_without_physics(index: int) -> int:
    var value := _faces[_rng.randi_range(0, _faces.size() - 1)]
    if index >= 0 and index < _dice_states.size():
        _dice_states[index].value = value
    _sync_die_value(index, value)
    return value

func _on_die_roll_completed(value: int, index: int) -> void:
    if index < 0 or index >= _dice_states.size():
        return
    var normalized := clampi(value, 1, 6)
    var state := _dice_states[index]
    state.value = normalized
    if index < _cached_results.size():
        _cached_results[index] = normalized
    _sync_die_value(index, normalized)
    _pending_roll_indices.erase(index)
    if _pending_roll_indices.is_empty():
        _rolling = false
        emit_signal("roll_resolved", _cached_results.duplicate())

func _set_die_lock_visual(index: int, locked: bool) -> void:
    if index < 0 or index >= _dice_nodes.size():
        return
    var die := _dice_nodes[index]
    if die:
        die.set_locked(locked)

func _set_die_hold_visual(index: int, held: bool) -> void:
    if index < 0 or index >= _dice_nodes.size():
        return
    var die := _dice_nodes[index]
    if die:
        if die.has_method("set_held"):
            die.set_held(held)

func _set_die_exhaust_visual(index: int, exhausted: bool) -> void:
    if index < 0 or index >= _dice_nodes.size():
        return
    var die := _dice_nodes[index]
    if die:
        die.set_exhausted(exhausted)

func set_reduced_motion(enabled: bool) -> void:
    _reduced_motion = enabled
    for die in _dice_nodes:
        if die:
            die.set_reduced_motion(enabled)
