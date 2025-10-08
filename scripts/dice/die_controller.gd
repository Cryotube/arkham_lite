extends Node3D
class_name DieController

const TAU := PI * 2.0
const FACE_ROTATIONS := {
	1: Vector3.ZERO,
	2: Vector3(-PI * 0.5, 0.0, 0.0),
	3: Vector3(0.0, 0.0, -PI * 0.5),
	4: Vector3(0.0, 0.0, PI * 0.5),
	5: Vector3(PI * 0.5, 0.0, 0.0),
	6: Vector3(PI, 0.0, 0.0),
}

@export var roll_duration: float = 0.8
@export var reduced_motion: bool = false

var _rng := RandomNumberGenerator.new()
var _current_value: int = 1
var _tween: Tween = null
var _locked: bool = false
var _exhausted: bool = false
var _reduced_motion_internal: bool = false

@onready var _locked_glow: MeshInstance3D = $"LockedGlow"
@onready var _exhaust_glow: MeshInstance3D = $"ExhaustGlow"

func _ready() -> void:
	_rng.randomize()
	set_reduced_motion(reduced_motion)
	set_value(_current_value, true)

func roll_to(value: int) -> void:
	_current_value = _clamp_value(value)
	if _reduced_motion_internal:
		set_value(_current_value, true)
		return
	var midpoint := Vector3(
		_rng.randf_range(-TAU, TAU),
		_rng.randf_range(-TAU, TAU),
		_rng.randf_range(-TAU, TAU)
	)
	if _tween and _tween.is_running():
		_tween.kill()
	rotation = rotation # ensures getter updates before tween start
	_tween = create_tween()
	_tween.set_parallel(false)
	_tween.tween_property(self, "rotation", midpoint, roll_duration * 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation", FACE_ROTATIONS.get(_current_value, Vector3.ZERO), roll_duration * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func set_value(value: int, instant: bool = false) -> void:
	_current_value = _clamp_value(value)
	if _tween and _tween.is_running():
		_tween.kill()
	rotation = FACE_ROTATIONS.get(_current_value, Vector3.ZERO)
	if instant:
		rotation = FACE_ROTATIONS.get(_current_value, Vector3.ZERO)

func set_locked(enabled: bool) -> void:
	_locked = enabled
	if _locked_glow:
		_locked_glow.visible = enabled and not _exhausted

func set_exhausted(enabled: bool) -> void:
	_exhausted = enabled
	if _exhaust_glow:
		_exhaust_glow.visible = enabled
	if _locked_glow and enabled:
		_locked_glow.visible = false

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion_internal = enabled
	if _reduced_motion_internal and _tween and _tween.is_running():
		_tween.kill()
		set_value(_current_value, true)

func get_value() -> int:
	return _current_value

func clear_state() -> void:
	set_locked(false)
	set_exhausted(false)

func _clamp_value(value: int) -> int:
	return clamp(value, 1, 6)
