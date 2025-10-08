extends Control
class_name RoomOverlayController

signal room_selected(room_id)
signal overlay_closed

@export var close_on_selection: bool = true
@onready var _list_container: VBoxContainer = %RoomList
@onready var _empty_label: Label = %EmptyLabel
@onready var _close_button: Button = %CloseButton

var _rooms: Array = []

func _ready() -> void:
	hide()
	_close_button.pressed.connect(close_overlay)

func display_rooms(room_queue: Array) -> void:
	_rooms = room_queue.duplicate()
	_refresh_list()
	if _rooms.is_empty():
		hide()
	else:
		show()

func clear() -> void:
	_rooms.clear()
	_refresh_list()
	hide()

func _refresh_list() -> void:
	for child in _list_container.get_children():
		child.queue_free()
	if _rooms.is_empty():
		_empty_label.show()
		return
	_empty_label.hide()
	for room in _rooms:
		var button := _create_room_button(room)
		_list_container.add_child(button)

func _create_room_button(room: Dictionary) -> Button:
	var button := Button.new()
	button.text = room.get("display_name", room.get("name", "Room"))
	button.pressed.connect(_on_room_pressed.bind(room))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _on_room_pressed(room: Dictionary) -> void:
	room_selected.emit(room.get("id", room.get("slug", "")))
	if close_on_selection:
		hide()
		overlay_closed.emit()

func close_overlay() -> void:
	hide()
	overlay_closed.emit()
