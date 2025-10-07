extends VBoxContainer

signal placement_failed(reason: String)

const GRID_WIDTH: int = 6
const GRID_HEIGHT: int = 5

@onready var _rotation_option: OptionButton = $"Toolbar/RotationOption"
@onready var _clear_button: Button = $"Toolbar/ClearButton"
@onready var _grid_container: GridContainer = $"Content/GridPanel/MatrixGrid"
@onready var _inventory_list: VBoxContainer = $"Content/InventoryPanel/InventoryScroll/InventoryList"

var _selected_item_id: String = ""
var _grid_buttons: Dictionary = {}

func _ready() -> void:
	_rotation_option.clear()
	_rotation_option.add_item("0°", 0)
	_rotation_option.add_item("90°", 1)
	_rotation_option.select(0)
	_populate_grid_buttons()
	_rotation_option.item_selected.connect(_on_rotation_changed)
	_clear_button.pressed.connect(_on_clear_pressed)
	var inventory: Node = _get_inventory()
	if inventory != null:
		inventory.inventory_changed.connect(_on_inventory_changed)
		inventory.grid_updated.connect(_on_grid_updated)
		_on_inventory_changed(inventory.get_carry_items(), inventory.get_installed_items())
		_on_grid_updated(inventory.get_grid())

func _populate_grid_buttons() -> void:
	_grid_container.columns = GRID_WIDTH
	_grid_container.custom_minimum_size = Vector2(360, 240)
	_grid_buttons.clear()
	for y in GRID_HEIGHT:
		for x in GRID_WIDTH:
			var btn := Button.new()
			btn.focus_mode = Control.FOCUS_NONE
			btn.toggle_mode = true
			btn.text = ""
			btn.tooltip_text = "Slot %d,%d" % [x, y]
			btn.pressed.connect(_on_grid_cell_pressed.bind(Vector2i(x, y)))
			_grid_container.add_child(btn)
			_grid_buttons[Vector2i(x, y)] = btn

func _on_grid_cell_pressed(cell: Vector2i) -> void:
	if _selected_item_id.is_empty():
		return
	var inventory: Node = _get_inventory()
	if inventory == null:
		return
	var rotation := _current_rotation()
	if inventory.can_place(_selected_item_id, cell, rotation):
		inventory.place_item(_selected_item_id, cell, rotation)
		_selected_item_id = ""
		_refresh_inventory_selection()
	else:
		placement_failed.emit("Cannot place item at that location.")

func _on_rotation_changed(_index: int) -> void:
	# Rotation is applied on placement; no immediate action needed.
	pass

func _on_clear_pressed() -> void:
	var inventory: Node = _get_inventory()
	if inventory == null:
		return
	var installed: Dictionary = inventory.get_installed_items()
	for item_id in installed.keys():
		inventory.remove_installed(item_id)

func _on_inventory_changed(carry: Array, installed: Dictionary) -> void:
	_clear_inventory_list()
	for entry in carry:
		var button := Button.new()
		button.text = entry.get("name", entry.get("id", "Equipment"))
		button.size_flags_horizontal = Control.SIZE_FILL
		button.tooltip_text = entry.get("description", "")
		button.toggle_mode = true
		button.set_meta("item_id", entry.get("id", ""))
		button.pressed.connect(_on_inventory_item_pressed.bind(String(entry.get("id", ""))))
		_inventory_list.add_child(button)
	_refresh_inventory_selection()

func _on_grid_updated(grid: Array) -> void:
	for cell in _grid_buttons.keys():
		var btn: Button = _grid_buttons[cell]
		btn.text = ""
		btn.disabled = false
	for y in grid.size():
		var row: Array = grid[y] as Array
		for x in row.size():
			var item_id = row[x]
			if item_id != null:
				var btn: Button = _grid_buttons.get(Vector2i(x, y))
				if btn:
					btn.text = "●"
					btn.disabled = true

func _on_inventory_item_pressed(item_id: String) -> void:
	if _selected_item_id == item_id:
		_selected_item_id = ""
	else:
		_selected_item_id = item_id
	_refresh_inventory_selection()

func _refresh_inventory_selection() -> void:
	for child in _inventory_list.get_children():
		if child is Button:
			var btn: Button = child
			var item_id: String = String(btn.get_meta("item_id", ""))
			btn.button_pressed = (item_id == _selected_item_id)

func _current_rotation() -> int:
	if _rotation_option.selected == 0:
		return 0
	return 90

func _clear_inventory_list() -> void:
	for node in _inventory_list.get_children():
		node.queue_free()

func _get_inventory() -> Node:
	var tree := get_tree()
	if tree and tree.get_root().has_node("EquipmentInventoryModel"):
		return tree.get_root().get_node("EquipmentInventoryModel")
	return null
