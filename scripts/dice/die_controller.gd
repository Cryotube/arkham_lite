extends RigidBody3D
class_name DieController

signal roll_completed(value: int)

const TAU := PI * 2.0
const FACE_ROTATIONS := {
    1: Vector3.ZERO,
    2: Vector3(-PI * 0.5, 0.0, 0.0),
    3: Vector3(0.0, 0.0, -PI * 0.5),
    4: Vector3(0.0, 0.0, PI * 0.5),
    5: Vector3(PI * 0.5, 0.0, 0.0),
    6: Vector3(PI, 0.0, 0.0),
}
const FACE_NORMALS := {
    1: Vector3.UP,
    2: Vector3.FORWARD,
    3: Vector3.RIGHT,
    4: Vector3.LEFT,
    5: Vector3.BACK,
    6: Vector3.DOWN,
}

@export var roll_impulse_strength: float = 6.5
@export var torque_impulse_strength: float = 7.5
@export var settle_linear_threshold: float = 0.25
@export var settle_angular_threshold: float = 0.3
@export var settle_time: float = 0.18
@export var launch_height: float = 2.0
@export var lateral_spread: float = 0.6
@export var reduced_motion: bool = false
@export var pull_force: float = 36.0
@export var roll_linear_damp: float = 3.2
@export var roll_angular_damp: float = 3.4
@export var max_roll_time: float = 0.55

var _rng := RandomNumberGenerator.new()
var _current_value: int = 1
var _rolling: bool = false
var _settle_timer: float = 0.0
var _roll_timer: float = 0.0
var _rest_transform: Transform3D
var _locked: bool = false
var _held: bool = false
var _exhausted: bool = false
var _reduced_motion_internal: bool = false
var _base_linear_damp: float = 0.0
var _base_angular_damp: float = 0.0

@onready var _locked_glow: MeshInstance3D = $"LockedGlow"
@onready var _hold_glow: MeshInstance3D = $"HoldGlow"
@onready var _exhaust_glow: MeshInstance3D = $"ExhaustGlow"

func _ready() -> void:
    _rng.randomize()
    _rest_transform = global_transform
    _reduced_motion_internal = reduced_motion
    _base_linear_damp = linear_damp
    _base_angular_damp = angular_damp
    freeze = true
    sleeping = true
    set_value(_current_value, true)

func _physics_process(delta: float) -> void:
    if not _rolling:
        return
    _roll_timer += delta
    if linear_velocity.length() < settle_linear_threshold and angular_velocity.length() < settle_angular_threshold:
        _settle_timer += delta
        if _settle_timer >= settle_time:
            _finish_roll()
    else:
        _settle_timer = 0.0
    if _rolling and pull_force > 0.0:
        apply_central_force(Vector3.DOWN * pull_force)
    if _rolling and max_roll_time > 0.0 and _roll_timer >= max_roll_time:
        _finish_roll()

func roll_to(target_value: int) -> void:
    if _reduced_motion_internal:
        _current_value = _clamp_value(target_value)
        set_value(_current_value, true)
        roll_completed.emit(_current_value)
        return
    _start_physics_roll()

func _start_physics_roll() -> void:
    linear_damp = roll_linear_damp
    angular_damp = roll_angular_damp
    freeze = false
    sleeping = false
    _rolling = true
    _settle_timer = 0.0
    _roll_timer = 0.0
    global_transform.origin = _rest_transform.origin + Vector3(
        _rng.randf_range(-lateral_spread, lateral_spread),
        launch_height,
        _rng.randf_range(-lateral_spread, lateral_spread)
    )
    global_transform.basis = Basis.from_euler(Vector3(
        _rng.randf_range(0.0, TAU),
        _rng.randf_range(0.0, TAU),
        _rng.randf_range(0.0, TAU)
    ))
    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO
    apply_impulse(Vector3.ZERO, Vector3(
        _rng.randf_range(-roll_impulse_strength, roll_impulse_strength),
        -roll_impulse_strength,
        _rng.randf_range(-roll_impulse_strength, roll_impulse_strength)
    ))
    apply_torque_impulse(Vector3(
        _rng.randf_range(-torque_impulse_strength, torque_impulse_strength),
        _rng.randf_range(-torque_impulse_strength, torque_impulse_strength),
        _rng.randf_range(-torque_impulse_strength, torque_impulse_strength)
    ))

func set_value(value: int, instant: bool = false) -> void:
    _current_value = _clamp_value(value)
    var face_rotation: Vector3 = FACE_ROTATIONS.get(_current_value, Vector3.ZERO)
    var basis: Basis = Basis.from_euler(face_rotation)
    if instant:
        linear_velocity = Vector3.ZERO
        angular_velocity = Vector3.ZERO
        global_transform = Transform3D(basis, _rest_transform.origin)
        freeze = true
        sleeping = true
    else:
        global_transform = Transform3D(basis, global_transform.origin)

func set_locked(enabled: bool) -> void:
    _locked = enabled
    if _locked_glow:
        _locked_glow.visible = enabled and not _exhausted
    if enabled and _hold_glow:
        _hold_glow.visible = false
    elif _hold_glow and _held:
        _hold_glow.visible = true

func set_held(enabled: bool) -> void:
    _held = enabled
    if _hold_glow:
        _hold_glow.visible = enabled and not _exhausted and not _locked

func set_exhausted(enabled: bool) -> void:
    _exhausted = enabled
    if _exhaust_glow:
        _exhaust_glow.visible = enabled
    if _locked_glow and enabled:
        _locked_glow.visible = false
    if _hold_glow and enabled:
        _hold_glow.visible = false

func set_reduced_motion(enabled: bool) -> void:
    _reduced_motion_internal = enabled
    if enabled and _rolling:
        _finish_roll()

func get_value() -> int:
    return _current_value

func clear_state() -> void:
    set_locked(false)
    set_held(false)
    set_exhausted(false)

func _finish_roll() -> void:
    _rolling = false
    freeze = true
    sleeping = true
    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO
    _settle_timer = 0.0
    _roll_timer = 0.0
    var resolved := _resolve_face_from_orientation()
    _current_value = resolved
    set_value(_current_value, true)
    linear_damp = _base_linear_damp
    angular_damp = _base_angular_damp
    call_deferred("_deferred_emit_roll_completed", _current_value)

func _deferred_emit_roll_completed(value: int) -> void:
    var tree := get_tree()
    if tree == null:
        roll_completed.emit(value)
        return
    var timer := tree.create_timer(0.0, false, true)
    timer.timeout.connect(_on_roll_completed_timeout.bind(value), Object.CONNECT_ONE_SHOT)

func _on_roll_completed_timeout(value: int) -> void:
    roll_completed.emit(value)

func _resolve_face_from_orientation() -> int:
    var basis: Basis = global_transform.basis
    var best_face := 1
    var best_dot: float = -INF
    for face in FACE_NORMALS.keys():
        var face_normal: Vector3 = FACE_NORMALS.get(face, Vector3.UP)
        var world_dir: Vector3 = basis * face_normal
        var dot: float = world_dir.dot(Vector3.UP)
        if dot > best_dot:
            best_dot = dot
            best_face = face
    return best_face

func _clamp_value(value: int) -> int:
    return clamp(value, 1, 6)
