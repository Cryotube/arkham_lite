extends Control
class_name ContextActionPopup

signal action_chosen(action_id)
signal popup_closed

@export var auto_close: bool = true
@onready var _actions_container: VBoxContainer = %ActionsContainer
@onready var _title_label: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton

func _ready() -> void:
	hide()
	_close_button.pressed.connect(close_popup)

func present(actions: Array[Dictionary], title: String = "Actions") -> void:
	_title_label.text = title
	_clear_actions()
	for action in actions:
		var button := _create_action_button(action)
		_actions_container.add_child(button)
	if actions.is_empty():
		hide()
	else:
		show()

func close_popup() -> void:
	hide()
	popup_closed.emit()

func _clear_actions() -> void:
	for child in _actions_container.get_children():
		child.queue_free()

func _create_action_button(action: Dictionary) -> Button:
	var button := Button.new()
	button.text = action.get("label", "Action")
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var action_id: String = String(action.get("id", action.get("action_id", "unknown")))
	button.disabled = action.get("disabled", false)
	button.pressed.connect(_on_action_pressed.bind(action_id))
	return button

func _on_action_pressed(action_id) -> void:
	action_chosen.emit(action_id)
	if auto_close:
		close_popup()
