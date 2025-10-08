extends Control
class_name ThreatOverlayController

signal threat_selected(threat_id)
signal overlay_closed

@export var close_on_focus_loss: bool = true
@onready var _threat_list: VBoxContainer = %ThreatList
@onready var _empty_label: Label = %EmptyLabel
@onready var _close_button: Button = %CloseButton

var _threats: Array = []

func _ready() -> void:
	hide()
	_close_button.pressed.connect(close_overlay)

func display_threats(threat_queue: Array) -> void:
	_threats = threat_queue.duplicate()
	_refresh()
	if _threats.is_empty():
		hide()
	else:
		show()

func clear() -> void:
	_threats.clear()
	_refresh()
	hide()

func _refresh() -> void:
	for child in _threat_list.get_children():
		child.queue_free()
	if _threats.is_empty():
		_empty_label.show()
		return
	_empty_label.hide()
	for threat in _threats:
		var row := _create_threat_button(threat)
		_threat_list.add_child(row)

func _create_threat_button(threat: Dictionary) -> Button:
	var button := Button.new()
	button.text = threat.get("display_name", threat.get("name", "Threat"))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_threat_pressed.bind(threat))
	return button

func _on_threat_pressed(threat: Dictionary) -> void:
	threat_selected.emit(threat.get("id", threat.get("slug", "")))
	if close_on_focus_loss:
		hide()
		overlay_closed.emit()

func close_overlay() -> void:
	hide()
	overlay_closed.emit()
