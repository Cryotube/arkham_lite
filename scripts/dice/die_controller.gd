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

var _rng := RandomNumberGenerator.new()
var _current_value: int = 1
var _rolling: bool = false
var _settle_timer: float = 0.0
var _rest_transform: Transform3D
var _locked: bool = false
var _held: bool = false
var _exhausted: bool = false
var _reduced_motion_internal: bool = false

@onready var _locked_glow: MeshInstance3D = $"LockedGlow"
@onready var _hold_glow: MeshInstance3D = $"HoldGlow"
@onready var _exhaust_glow: MeshInstance3D = $"ExhaustGlow"

func _ready() -> void:
	_rng.randomize()
	_rest_transform = global_transform
	_reduced_motion_internal = reduced_motion
	freeze = true
	sleeping = true
	set_value(_current_value, true)

func _physics_process(delta: float) -> void:
	if not _rolling:
		return
	if linear_velocity.length() < settle_linear_threshold and angular_velocity.length() < settle_angular_threshold:
		_settle_timer += delta
		if _settle_timer >= settle_time:
			_finish_roll()
	else:
		_settle_timer = 0.0

func roll_to(target_value: int) -> void:
	if _reduced_motion_internal:
		_current_value = _clamp_value(target_value)
		set_value(_current_value, true)
		roll_completed.emit(_current_value)
		return
	_start_physics_roll()

func _start_physics_roll() -> void:
	freeze = false
	sleeping = false
	_rolling = true
	_settle_timer = 0.0
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
	var basis := Basis.from_euler(FACE_ROTATIONS.get(_current_value, Vector3.ZERO))
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
	var resolved := _resolve_face_from_orientation()
	_current_value = resolved
	set_value(_current_value, true)
	roll_completed.emit(_current_value)

func _resolve_face_from_orientation() -> int:
	var basis := global_transform.basis
	var best_face := 1
	var best_dot := -INF
	for face in FACE_NORMALS.keys():
		var world_dir := basis * FACE_NORMALS[face]
		var dot := world_dir.dot(Vector3.UP)
		if dot > best_dot:
			best_dot = dot
			best_face = face
	return best_face

func _clamp_value(value: int) -> int:
	return clamp(value, 1, 6)
