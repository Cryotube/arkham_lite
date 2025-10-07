extends VBoxContainer
class_name ThreatMeterController

const NORMAL_COLOR: Color = Color("4ade80")
const WARNING_COLOR: Color = Color("facc15")
const CRITICAL_COLOR: Color = Color("ef4444")

@export var warning_audio: AudioStream
@export var critical_audio: AudioStream

@onready var _bar: ProgressBar = $"ThreatProgressBar"
@onready var _value_label: Label = $"ThreatValueLabel"
@onready var _status_label: Label = $"ThreatStatusLabel"

var _thresholds: Dictionary = {}
var _audio_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

func _ready() -> void:
	_ensure_audio_pool()

func configure(thresholds: Dictionary) -> void:
	_thresholds = thresholds.get("threat", {
		"warning": 0.6,
		"critical": 0.85,
	})

func update_threat(current: int, max_value: int) -> void:
	if max_value <= 0:
		_bar.value = 0.0
		_value_label.text = "0 / 0"
		_status_label.text = "Threat: Safe"
		return
	_bar.max_value = float(max_value)
	_bar.value = float(current)
	_value_label.text = "%d / %d" % [current, max_value]
	var ratio := float(current) / float(max_value)
	var status := _status_for_ratio(ratio)
	_status_label.text = "Threat: %s" % status.capitalize()
	_bar.modulate = _color_for_status(status)

func handle_threshold_cross(level: StringName) -> void:
	_status_label.text = "Threat: %s" % str(level).capitalize()
	if level == "warning":
		_play_warning_cue()
	elif level == "critical":
		_play_critical_cue()

func _status_for_ratio(ratio: float) -> StringName:
	var warning := float(_thresholds.get("warning", 0.6))
	var critical := float(_thresholds.get("critical", 0.85))
	if ratio >= critical:
		return "critical"
	if ratio >= warning:
		return "warning"
	return "stable"

func _color_for_status(status: StringName) -> Color:
	match status:
		"critical":
			return CRITICAL_COLOR
		"warning":
			return WARNING_COLOR
		_:
			return NORMAL_COLOR

func _play_warning_cue() -> void:
	var player := _next_audio_player()
	if warning_audio:
		player.stream = warning_audio
		player.play()
	else:
		print_debug("Threat warning threshold crossed.")

func _play_critical_cue() -> void:
	var player := _next_audio_player()
	if critical_audio:
		player.stream = critical_audio
		player.play()
	else:
		print_debug("Threat critical threshold crossed.")

func _ensure_audio_pool() -> void:
	if not _audio_pool.is_empty():
		return
	for _i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "UI"
		add_child(player)
		_audio_pool.append(player)

func _next_audio_player() -> AudioStreamPlayer:
	_ensure_audio_pool()
	var player := _audio_pool[_pool_index]
	_pool_index = (_pool_index + 1) % _audio_pool.size()
	return player
