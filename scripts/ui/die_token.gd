extends PanelContainer
class_name DieToken

signal drag_started(token: DieToken)

@export var die_index: int = 0

@onready var _name_label: Label = $VBox/NameLabel
@onready var _value_label: Label = $VBox/ValueLabel
@onready var _status_label: Label = $VBox/StatusLabel

var _is_locked: bool = false
var _is_held: bool = false
var _is_exhausted: bool = false

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_update_status()

func set_die_name(name: String) -> void:
	_name_label.text = name

func set_value(value: int) -> void:
	_value_label.text = "%d" % value

func set_locked(locked: bool) -> void:
	_is_locked = locked
	if locked:
		_is_held = false
	_update_status()

func set_held(held: bool) -> void:
	_is_held = held
	if held:
		_is_locked = false
	_update_status()

func set_exhausted(exhausted: bool) -> void:
	_is_exhausted = exhausted
	if exhausted:
		_is_locked = false
		_is_held = false
	_update_status()

func _update_status() -> void:
	if _is_exhausted:
		_status_label.text = "Exhausted"
		_status_label.visible = true
		modulate = Color(0.6, 0.6, 0.6, 1)
	elif _is_locked:
		_status_label.text = "Locked"
		_status_label.visible = true
		modulate = Color(0.74, 0.97, 1.0, 1)
	elif _is_held:
		_status_label.text = "Held"
		_status_label.visible = true
		modulate = Color(0.49, 0.9, 0.97, 1)
	else:
		_status_label.visible = false
		modulate = Color(1, 1, 1, 1)

func _get_drag_data(_position: Vector2) -> Variant:
	if _is_exhausted:
		return null
	var data := {
		"type": "die_token",
		"die_index": die_index,
		"node_path": get_path()
	}
	var preview := duplicate()
	if preview is Control:
		preview.scale = Vector2(0.95, 0.95)
		preview.modulate = Color(1, 1, 1, 0.9)
	set_drag_preview(preview)
	drag_started.emit(self)
	return data
