extends VBoxContainer

const VALID_PREVIEW_COLOR := Color(0.24, 0.95, 0.87, 0.85)
const INVALID_PREVIEW_COLOR := Color(0.96, 0.33, 0.33, 0.85)
const OCCUPIED_COLOR := Color(0.82, 0.82, 0.82, 1.0)
const DEFAULT_COLOR := Color(1, 1, 1, 1)

@onready var _rotate_left_button: Button = $"Toolbar/RotateLeftButton"
@onready var _rotate_right_button: Button = $"Toolbar/RotateRightButton"
@onready var _remove_button: Button = $"Toolbar/RemoveButton"
@onready var _clear_button: Button = $"Toolbar/ClearButton"
@onready var _grid_container: GridContainer = $"Content/GridPanel/MatrixGrid"
@onready var _inventory_list: VBoxContainer = $"Content/InventoryPanel/InventoryScroll/InventoryList"
@onready var _burden_progress: ProgressBar = $"Content/InventoryPanel/BurdenPanel/BurdenProgress"
@onready var _burden_value: Label = $"Content/InventoryPanel/BurdenPanel/BurdenValue"
@onready var _burden_state: Label = $"Content/InventoryPanel/BurdenPanel/BurdenState"
@onready var _hint_label: Label = $"Content/InventoryPanel/HintLabel"

var _grid_buttons: Dictionary = {}
var _selected_item_id: StringName = &""
var _current_rotation: int = 0
var _hovered_cells: Array[Vector2i] = []
var _carried_catalog: Dictionary = {}
var _burden_thresholds: Dictionary = {}

func _ready() -> void:
	_populate_grid_buttons()
	_rotate_left_button.pressed.connect(_on_rotate_left)
	_rotate_right_button.pressed.connect(_on_rotate_right)
	_remove_button.pressed.connect(_on_remove_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	var inventory: Node = _get_inventory()
	if inventory != null:
		inventory.inventory_changed.connect(_on_inventory_changed)
		inventory.grid_updated.connect(_on_grid_updated)
		inventory.burden_changed.connect(_on_burden_changed)
		inventory.loadout_changed.connect(_on_loadout_changed)
		_burden_thresholds = inventory.get_burden_thresholds()
		_on_inventory_changed(inventory.get_carry_items(), inventory.get_installed_items())
		_on_grid_updated(inventory.get_grid())
		_on_burden_changed(inventory.get_total_burden(), inventory.get_burden_state())
	var feedback: Node = _get_feedback_service()
	if feedback:
		feedback.preview_cleared.connect(_clear_preview)
		feedback.preview_updated.connect(_on_feedback_preview)

func _populate_grid_buttons() -> void:
	_grid_buttons.clear()
	for child in _grid_container.get_children():
		child.queue_free()
	var inventory: Node = _get_inventory()
	var grid: Array = []
	if inventory:
		grid = inventory.get_grid()
	var height: int = 5
	var width: int = 6
	if not grid.is_empty():
		height = grid.size()
		width = (grid[0] as Array).size()
	_grid_container.columns = width
	_grid_container.custom_minimum_size = Vector2(width * 64, height * 64)
	for y in height:
		for x in width:
			var button := Button.new()
			button.focus_mode = Control.FOCUS_NONE
			button.toggle_mode = false
			button.text = ""
			button.tooltip_text = "Slot %d,%d" % [x, y]
			button.pressed.connect(_on_grid_cell_pressed.bind(Vector2i(x, y)))
			button.mouse_entered.connect(_on_grid_cell_hovered.bind(Vector2i(x, y)))
			button.mouse_exited.connect(_clear_preview)
			_grid_container.add_child(button)
			_grid_buttons[Vector2i(x, y)] = button

func _on_grid_cell_pressed(cell: Vector2i) -> void:
	var inventory: Node = _get_inventory()
	if inventory == null:
		return
	var grid: Array = inventory.get_grid()
	var feedback: Node = _get_feedback_service()
	if cell.y < grid.size():
		var row: Array = grid[cell.y] as Array
		if cell.x < row.size() and row[cell.x] != null:
			inventory.remove_installed(StringName(row[cell.x]))
			if feedback:
				feedback.play_action_feedback(&"module_removed")
			return
	if _selected_item_id.is_empty():
		return
	var result: Dictionary = inventory.evaluate_placement(_selected_item_id, cell, _current_rotation)
	if bool(result.get("valid", false)):
		inventory.place_item(_selected_item_id, cell, _current_rotation)
		_selected_item_id = StringName("")
		_refresh_inventory_selection()
		if feedback:
			feedback.play_action_feedback(&"module_equipped")
	else:
		_apply_preview(result.get("footprint", []), result.get("conflicts", []), false)
		if feedback:
			feedback.play_action_feedback(&"module_invalid")

func _on_grid_cell_hovered(cell: Vector2i) -> void:
	if _selected_item_id.is_empty():
		_clear_preview()
		return
	var inventory: Node = _get_inventory()
	if inventory == null:
		return
	var result: Dictionary = inventory.evaluate_placement(_selected_item_id, cell, _current_rotation)
	var footprint: Array = result.get("footprint", []) as Array
	var conflicts: Array = result.get("conflicts", []) as Array
	var valid: bool = bool(result.get("valid", false))
	_apply_preview(footprint, conflicts, valid)
	var feedback: Node = _get_feedback_service()
	if valid:
		if feedback:
			feedback.show_valid_preview(footprint)
	else:
		if feedback:
			feedback.show_invalid_preview(conflicts)

func _apply_preview(cells: Array, conflicts: Array, valid: bool) -> void:
	_clear_preview()
	var highlight_color := VALID_PREVIEW_COLOR if valid else INVALID_PREVIEW_COLOR
	for cell_variant in cells:
		var cell := Vector2i(cell_variant)
		var button: Button = _grid_buttons.get(cell, null)
		if button:
			button.self_modulate = highlight_color
			_hovered_cells.append(cell)
	for conflict_variant in conflicts:
		var conflict := Vector2i(conflict_variant)
		var button: Button = _grid_buttons.get(conflict, null)
		if button:
			button.self_modulate = INVALID_PREVIEW_COLOR
			if not _hovered_cells.has(conflict):
				_hovered_cells.append(conflict)

func _clear_preview() -> void:
	if _hovered_cells.is_empty():
		return
	for cell in _hovered_cells:
		var button: Button = _grid_buttons.get(cell, null)
		if button:
			button.self_modulate = DEFAULT_COLOR
	_hovered_cells.clear()

func _on_inventory_changed(carry: Array, _installed: Dictionary) -> void:
	_carried_catalog.clear()
	_clear_inventory_list()
	for entry in carry:
		var item_id := StringName(entry.get("id", ""))
		_carried_catalog[item_id] = entry
		var button := Button.new()
		button.text = "%s · %d load" % [entry.get("name", "Module"), int(entry.get("burden", 0))]
		button.size_flags_horizontal = Control.SIZE_FILL
		button.tooltip_text = _build_item_tooltip(entry)
		button.toggle_mode = true
		button.set_meta("item_id", item_id)
		button.pressed.connect(_on_inventory_item_pressed.bind(item_id))
		_inventory_list.add_child(button)
	_refresh_inventory_selection()

func _on_grid_updated(grid: Array) -> void:
	for coord in _grid_buttons.keys():
		var button: Button = _grid_buttons[coord]
		button.text = ""
		button.self_modulate = DEFAULT_COLOR
	_hovered_cells.clear()
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			var module_id = row[x]
			if module_id != null:
				var button: Button = _grid_buttons.get(Vector2i(x, y), null)
				if button:
					button.text = "●"
					button.self_modulate = OCCUPIED_COLOR

func _on_inventory_item_pressed(item_id: StringName) -> void:
	if _selected_item_id == item_id:
		_selected_item_id = StringName("")
	else:
		_selected_item_id = item_id
		var entry: Dictionary = _carried_catalog.get(item_id, {})
		_hint_label.text = "%s\nDice: %s" % [
			entry.get("description", ""),
			_format_costs(entry.get("dice_costs", []))
		]
	_refresh_inventory_selection()
	_clear_preview()

func _refresh_inventory_selection() -> void:
	for child in _inventory_list.get_children():
		if child is Button:
			var button: Button = child
			var item_id: StringName = StringName(button.get_meta("item_id", ""))
			button.button_pressed = (item_id == _selected_item_id)

func _on_rotate_left() -> void:
	_current_rotation = int((_current_rotation + 270) % 360)
	_hint_label.text = "Rotation: %d°" % _current_rotation

func _on_rotate_right() -> void:
	_current_rotation = int((_current_rotation + 90) % 360)
	_hint_label.text = "Rotation: %d°" % _current_rotation

func _on_remove_pressed() -> void:
	if _selected_item_id.is_empty():
		return
	var inventory: Node = _get_inventory()
	if inventory == null:
		return
	inventory.remove_installed(_selected_item_id)
	_selected_item_id = StringName("")
	_refresh_inventory_selection()
	_clear_preview()

func _on_clear_pressed() -> void:
	var inventory: Node = _get_inventory()
	if inventory == null:
		return
	var installed: Dictionary = inventory.get_installed_items()
	for module_id in installed.keys():
		inventory.remove_installed(StringName(module_id))
	_clear_preview()

func _on_burden_changed(total: int, state: StringName) -> void:
	var critical := int(_burden_thresholds.get("critical", max(1, total)))
	_burden_progress.max_value = max(critical, total)
	_burden_progress.value = total
	_burden_value.text = "%d load" % total
	_burden_state.text = state.capitalize()
	match state:
		&"critical":
			_burden_state.modulate = Color(0.87, 0.23, 0.33)
		&"strained":
			_burden_state.modulate = Color(0.96, 0.68, 0.17)
		_:
			_burden_state.modulate = Color(0.35, 0.87, 0.62)

func _on_loadout_changed(loadout: Dictionary) -> void:
	var installed := loadout.get("installed", {}) as Dictionary
	if installed.is_empty():
		_hint_label.text = "Select equipment to preview placement."
		return
	var lines: Array[String] = []
	for module_id in installed.keys():
		var module: Dictionary = installed[module_id]
		lines.append("%s → %s" % [module.get("name", module_id), _format_costs(module.get("dice_costs", []))])
	_hint_label.text = "\n".join(lines)

func _on_feedback_preview(_state: StringName, _cells: Array) -> void:
	# Preview already handled locally; hook retained for overlay pooling.
	pass

func _build_item_tooltip(entry: Dictionary) -> String:
	var burden := int(entry.get("burden", 0))
	var dice_costs := _format_costs(entry.get("dice_costs", []))
	var passive := _format_costs(entry.get("passive_slots", []))
	var lines: Array[String] = []
	lines.append(entry.get("description", ""))
	lines.append("Load: %d" % burden)
	if not dice_costs.is_empty():
		lines.append("Dice: %s" % dice_costs)
	if not passive.is_empty():
		lines.append("Passive: %s" % passive)
	return "\n".join(lines)

func _format_costs(costs: Array) -> String:
	if costs.is_empty():
		return ""
	var parts: Array[String] = []
	for cost in costs:
		parts.append(String(cost).capitalize())
	return ", ".join(parts)

func _clear_inventory_list() -> void:
	for node in _inventory_list.get_children():
		node.queue_free()

func _get_inventory():
	var tree := get_tree()
	if tree:
		var root := tree.get_root()
		var path := NodePath("EquipmentInventoryModel")
		if root.has_node(path):
			return root.get_node(path)
	return null

func _get_feedback_service():
	var tree := get_tree()
	if tree:
		var root := tree.get_root()
		var path := NodePath("EquipmentFeedbackService")
		if root.has_node(path):
			return root.get_node(path)
	return null
