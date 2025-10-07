extends Node

signal events_flushed(events: Array)

@export var max_buffer_size: int = 32
@export var auto_flush_seconds: float = 15.0
@export var log_path: String = "user://telemetry.log"

var _event_buffer: Array[Dictionary] = []
var _timer: Timer = null
var _sdk_callback: Callable = Callable()

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = auto_flush_seconds
	_timer.autostart = true
	_timer.one_shot = false
	_timer.timeout.connect(_on_auto_flush_timeout)
	add_child(_timer)
	_initialize_log_target()

func record(event_name: String, payload: Dictionary = {}) -> void:
	var entry := {
		"name": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"payload": payload.duplicate(true)
	}
	_event_buffer.append(entry)
	if _event_buffer.size() >= max_buffer_size:
		_flush()

func flush() -> void:
	_flush()

func get_buffer() -> Array:
	var copy: Array[Dictionary] = []
	for entry in _event_buffer:
		copy.append(entry.duplicate(true))
	return copy

func set_sdk_callback(callback: Callable) -> void:
	_sdk_callback = callback

func _flush() -> void:
	if _event_buffer.is_empty():
		return
	var batch := _event_buffer.duplicate(true)
	_event_buffer.clear()
	events_flushed.emit(batch)
	_append_to_log(batch)
	_forward_to_sdk(batch)

func _on_auto_flush_timeout() -> void:
	_flush()

func _initialize_log_target() -> void:
	var dir_path := log_path.get_base_dir()
	if dir_path.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(dir_path)

func _append_to_log(batch: Array) -> void:
	if log_path.is_empty():
		return
	var file := FileAccess.open(log_path, FileAccess.WRITE_READ)
	if file == null:
		file = FileAccess.open(log_path, FileAccess.WRITE)
	else:
		file.seek_end()
	for entry in batch:
		file.store_line(JSON.stringify(entry))
	file.flush()
	file.close()

func _forward_to_sdk(batch: Array) -> void:
	if _sdk_callback.is_null():
		return
	if _sdk_callback.is_valid():
		_sdk_callback.call(batch)
