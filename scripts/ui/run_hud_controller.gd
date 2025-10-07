extends Control
class_name RunHudController

signal roll_requested
signal confirm_requested
signal lock_requested(index: int)

var _dice_subsystem = null
@onready var _die_labels: Array[Label] = [
	$"MainLayout/DiceTray/DiceValues/Die0" as Label,
	$"MainLayout/DiceTray/DiceValues/Die1" as Label,
	$"MainLayout/DiceTray/DiceValues/Die2" as Label
]
@onready var _lock_buttons: Array[Button] = [
	$"MainLayout/DiceTray/LockRow/Lock0",
	$"MainLayout/DiceTray/LockRow/Lock1",
	$"MainLayout/DiceTray/LockRow/Lock2"
]
@onready var _roll_button: Button = $"MainLayout/ActionButtons/RollButton"
@onready var _confirm_button: Button = $"MainLayout/ActionButtons/ConfirmButton"
@onready var _exhaust_label: Label = $"MainLayout/ExhaustTray/ExhaustLabel"
@onready var _resource_panel = $"MainLayout/ResourcePanel"

var _turn_manager = null

func _ready() -> void:
	_connect_inputs()
	if _dice_subsystem == null and has_node("MainLayout/DiceTray/DiceViewportContainer/DiceViewport/DiceRoot"):
		_dice_subsystem = get_node("MainLayout/DiceTray/DiceViewportContainer/DiceViewport/DiceRoot")
	reset_hud_state()
	refresh_resource_panel()

func _connect_inputs() -> void:
	_roll_button.pressed.connect(_on_roll_pressed)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	for index in _lock_buttons.size():
		_lock_buttons[index].pressed.connect(_on_lock_button_pressed.bind(index))

func set_turn_manager(turn_manager) -> void:
	_turn_manager = turn_manager
	roll_requested.connect(_turn_manager.request_roll)
	confirm_requested.connect(_turn_manager.commit_dice)
	lock_requested.connect(_turn_manager.toggle_lock)

func get_dice_subsystem():
	if _dice_subsystem == null and has_node("MainLayout/DiceTray/DiceViewportContainer/DiceViewport/DiceRoot"):
		_dice_subsystem = get_node("MainLayout/DiceTray/DiceViewportContainer/DiceViewport/DiceRoot")
	return _dice_subsystem

func reset_hud_state() -> void:
	update_for_roll([1, 1, 1], [], [])
	refresh_resource_panel()

func update_for_roll(results: Array[int], locked: Array[int], exhausted: Array[int]) -> void:
	for index in _die_labels.size():
		var label = _die_labels[index]
		var value: int = results[index] if index < results.size() else 0
		var suffix: String = ""
		if index in locked:
			suffix = " (locked)"
		elif index in exhausted:
			suffix = " (exhausted)"
		label.text = _die_label_for_index(index, value, suffix)
		_lock_buttons[index].button_pressed = index in locked
		_lock_buttons[index].disabled = index in exhausted
	_update_exhaust_label(exhausted)

func refresh_resource_panel() -> void:
	if _resource_panel and _resource_panel.has_method("refresh"):
		_resource_panel.refresh()

func _on_roll_pressed() -> void:
	roll_requested.emit()

func _on_confirm_pressed() -> void:
	confirm_requested.emit()

func _on_lock_button_pressed(index: int) -> void:
	lock_requested.emit(index)

func _die_label_for_index(index: int, value: int, suffix: String) -> String:
	var names: Array[String] = ["Die A", "Die B", "Die C"]
	var die_name: String = names[index] if index < names.size() else "Die"
	return "%s: %d%s" % [die_name, value, suffix]

func _update_exhaust_label(exhausted: Array[int]) -> void:
	if exhausted.is_empty():
		_exhaust_label.text = "Exhausted Dice: none"
		return
	var mapping: Array[String] = ["A", "B", "C"]
	var parts: Array[String] = []
	for index in exhausted:
		if index < mapping.size():
			parts.append(mapping[index])
	_exhaust_label.text = "Exhausted Dice: %s" % ", ".join(parts)

