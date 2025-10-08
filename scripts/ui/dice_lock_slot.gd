extends PanelContainer
class_name DiceLockSlot

const DieToken = preload("res://scripts/ui/die_token.gd")

signal die_drop_requested(token_path: NodePath, die_index: int, slot_index: int)

@export var slot_index: int = 0

@onready var _placeholder: Label = $VBox/Placeholder

var current_token: DieToken = null

func can_drop_data(_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.get("type", "") != "die_token":
		return false
	if current_token == null:
		return true
	var die_index: int = int(data.get("die_index", -1))
	return current_token.die_index == die_index

func drop_data(_position: Vector2, data: Variant) -> void:
	if not can_drop_data(_position, data):
		return
	var token_path: NodePath = data.get("node_path", NodePath())
	var die_index: int = int(data.get("die_index", -1))
	if token_path.is_empty():
		return
	die_drop_requested.emit(token_path, die_index, slot_index)

func accept_token(token: DieToken) -> void:
	_clear_existing_reference(token)
	token.reparent(self)
	token.set_locked(true)
	current_token = token
	_update_placeholder()

func release_token(token: DieToken) -> void:
	if current_token == token:
		current_token = null
	_update_placeholder()

func clear_slot() -> void:
	if current_token != null:
		current_token = null
	_update_placeholder()

func _clear_existing_reference(token: DieToken) -> void:
	if current_token == token:
		current_token = null

func _update_placeholder() -> void:
	_placeholder.visible = current_token == null
