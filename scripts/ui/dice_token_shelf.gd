extends HBoxContainer
class_name DiceTokenShelf

const DieToken = preload("res://scripts/ui/die_token.gd")

signal die_released(token_path: NodePath, die_index: int)

@onready var _placeholder: Label = $Placeholder

func can_drop_data(_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.get("type", "") == "die_token"

func drop_data(_position: Vector2, data: Variant) -> void:
	if not can_drop_data(_position, data):
		return
	var token_path: NodePath = data.get("node_path", NodePath())
	var die_index: int = int(data.get("die_index", -1))
	if token_path.is_empty():
		return
	die_released.emit(token_path, die_index)

func add_token(token: DieToken) -> void:
	token.reparent(self)
	token.set_locked(false)
	_move_token_to_order(token)
	_update_placeholder()

func remove_token(token: DieToken) -> void:
	if token.get_parent() == self:
		remove_child(token)
	_update_placeholder()

func _move_token_to_order(token: DieToken) -> void:
	var max_index: int = max(get_child_count() - 2, 0)
	var target_index: int = clamp(token.die_index, 0, max_index)
	move_child(token, target_index)

func _update_placeholder() -> void:
	var visible_children: int = 0
	for child in get_children():
		if child is DieToken:
			visible_children += 1
	_placeholder.visible = visible_children == 0
