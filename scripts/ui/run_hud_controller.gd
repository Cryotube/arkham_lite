extends Control
class_name RunHudController

const DieToken = preload("res://scripts/ui/die_token.gd")
const DiceTokenShelf = preload("res://scripts/ui/dice_token_shelf.gd")
const DiceLockSlot = preload("res://scripts/ui/dice_lock_slot.gd")
const TurnManager = preload("res://scripts/systems/turn_manager.gd")

const COLOR_SELECTED_ROOM := Color(0.49, 0.901961, 0.968627, 1.0)
const COLOR_SELECTED_THREAT := Color(0.960784, 0.501961, 0.27451, 1.0)

signal roll_requested
signal confirm_requested
signal hold_requested(index: int, should_hold: bool)

var _dice_subsystem = null
var _rolling: bool = false
var _last_locked: Array[int] = []
var _last_held: Array[int] = []
var _last_exhausted: Array[int] = []
@onready var _dice_token_shelf: DiceTokenShelf = $"MainLayout/DiceDock/DiceViewportFrame/ViewportOverlay/DiceOverlay/OverlayVBox/AvailableDiceRow"
@onready var _dice_tokens: Array[DieToken] = [
	$"MainLayout/DiceDock/DiceViewportFrame/ViewportOverlay/DiceOverlay/OverlayVBox/AvailableDiceRow/DieToken0",
	$"MainLayout/DiceDock/DiceViewportFrame/ViewportOverlay/DiceOverlay/OverlayVBox/AvailableDiceRow/DieToken1",
	$"MainLayout/DiceDock/DiceViewportFrame/ViewportOverlay/DiceOverlay/OverlayVBox/AvailableDiceRow/DieToken2"
]
@onready var _lock_slots: Array[DiceLockSlot] = [
	$"MainLayout/DiceDock/LockColumn/LockTray/LockSlot0",
	$"MainLayout/DiceDock/LockColumn/LockTray/LockSlot1",
	$"MainLayout/DiceDock/LockColumn/LockTray/LockSlot2"
]
@onready var _roll_button: Button = $"MainLayout/DiceDock/LockColumn/ActionButtons/RollButton"
@onready var _confirm_button: Button = $"MainLayout/DiceDock/LockColumn/ActionButtons/ConfirmButton"
@onready var _exhaust_label: Label = $"MainLayout/DiceDock/LockColumn/ExhaustTray/ExhaustLabel"
@onready var _overlay_hint: Label = $"MainLayout/DiceDock/DiceViewportFrame/ViewportOverlay/DiceOverlay/OverlayVBox/OverlayHint"
@onready var _resource_panel = $"MainLayout/ResourcePanel"
@onready var _context_info: RichTextLabel = $"MainLayout/MainBody/RightColumn/ContextPane/ContextMargin/ContextVBox/ContextScroll/ContextInfo"
@onready var _enter_room_button: Button = $"MainLayout/MainBody/RightColumn/ContextPane/ContextMargin/ContextVBox/ContextActions/EnterButton"
@onready var _cycle_room_button: Button = $"MainLayout/MainBody/RightColumn/ContextPane/ContextMargin/ContextVBox/ContextActions/CycleButton"
@onready var _scout_room_button: Button = $"MainLayout/MainBody/RightColumn/ContextPane/ContextMargin/ContextVBox/ContextActions/ScoutButton"
@onready var _banner_panel: PanelContainer = $"MainLayout/MessageBanner"
@onready var _banner_label: Label = $"MainLayout/MessageBanner/BannerVBox/BannerLabel"
@onready var _banner_timer: Timer = $"MainLayout/MessageTimer"
@onready var _event_overlay: PanelContainer = $"EventOverlay"
@onready var _event_title: Label = $"EventOverlay/EventVBox/EventTitle"
@onready var _event_body: RichTextLabel = $"EventOverlay/EventVBox/EventBody"
@onready var _event_choices: VBoxContainer = $"EventOverlay/EventVBox/Choices"
@onready var _equipment_tab: Node = $"MainLayout/MainBody/RightColumn/TabContainer/Equipment"
@onready var _tutorial_overlay: PanelContainer = $"TutorialOverlay"
@onready var _tutorial_title: Label = $"TutorialOverlay/TutorialVBox/TutorialTitle"
@onready var _tutorial_body: RichTextLabel = $"TutorialOverlay/TutorialVBox/TutorialBody"
@onready var _tutorial_skip: Button = $"TutorialOverlay/TutorialVBox/TutorialActions/TutorialSkip"
@onready var _tutorial_next: Button = $"TutorialOverlay/TutorialVBox/TutorialActions/TutorialNext"
@onready var _room_list_container: VBoxContainer = $"MainLayout/MainBody/LeftDock/RoomPanel/RoomMargin/RoomVBox/RoomScroll/RoomList/RoomItems"
@onready var _room_empty_label: Label = $"MainLayout/MainBody/LeftDock/RoomPanel/RoomMargin/RoomVBox/RoomScroll/RoomList/RoomEmptyLabel"
@onready var _threat_list_container: VBoxContainer = $"MainLayout/MainBody/LeftDock/ThreatPanel/ThreatMargin/ThreatVBox/ThreatScroll/ThreatList/ThreatItems"
@onready var _threat_empty_label: Label = $"MainLayout/MainBody/LeftDock/ThreatPanel/ThreatMargin/ThreatVBox/ThreatScroll/ThreatList/ThreatEmptyLabel"
@onready var _context_actions: HBoxContainer = $"MainLayout/MainBody/RightColumn/ContextPane/ContextMargin/ContextVBox/ContextActions"

var _turn_manager: TurnManager = null
var _room_queue_service: Node = null
var _threat_service: Node = null
var _event_resolver: Node = null
var _selected_room: Dictionary = {}
var _selected_room_index: int = -1
var _current_queue: Array[Dictionary] = []
var _current_threats: Array[Dictionary] = []
var _last_scouted_room: Dictionary = {}
var _selected_threat_id: String = ""
var _tutorial_service: Node = null
var _telemetry_hub: Node = null
var _die_slot_map: Dictionary = {}

func _ready() -> void:
	_connect_inputs()
	_connect_services()
	if _equipment_tab != null and _equipment_tab.has_signal("placement_failed"):
		_equipment_tab.placement_failed.connect(_on_equipment_placement_failed)
	if _dice_subsystem == null and has_node("MainLayout/DiceDock/DiceViewportFrame/DiceViewportContainer/DiceViewport/DiceRoot"):
		_dice_subsystem = get_node("MainLayout/DiceDock/DiceViewportFrame/DiceViewportContainer/DiceViewport/DiceRoot")
	_wire_dice_signals()
	reset_hud_state()
	refresh_resource_panel()

func _connect_inputs() -> void:
	_roll_button.pressed.connect(_on_roll_pressed)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	for slot in _lock_slots:
		if slot and not slot.die_drop_requested.is_connected(_on_lock_slot_drop):
			slot.die_drop_requested.connect(_on_lock_slot_drop)
	if _dice_token_shelf and not _dice_token_shelf.die_released.is_connected(_on_die_released):
		_dice_token_shelf.die_released.connect(_on_die_released)
	for token in _dice_tokens:
		if token:
			token.set_die_name(_die_name_for_index(token.die_index))
	_enter_room_button.pressed.connect(_on_enter_room_pressed)
	_cycle_room_button.pressed.connect(_on_cycle_room_pressed)
	_scout_room_button.pressed.connect(_on_scout_room_pressed)
	_banner_timer.timeout.connect(_on_banner_timer_timeout)
	_tutorial_next.pressed.connect(_on_tutorial_next_pressed)
	_tutorial_skip.pressed.connect(_on_tutorial_skip_pressed)
	_context_actions.visible = false

func _connect_services() -> void:
	_room_queue_service = _get_room_service()
	if _room_queue_service != null:
		if not _room_queue_service.queue_updated.is_connected(_on_room_queue_updated):
			_room_queue_service.queue_updated.connect(_on_room_queue_updated)
		_on_room_queue_updated(_room_queue_service.get_queue())
	_threat_service = _get_threat_service()
	if _threat_service != null:
		if not _threat_service.threats_updated.is_connected(_on_threats_updated):
			_threat_service.threats_updated.connect(_on_threats_updated)
		_on_threats_updated(_threat_service.get_threats())
	_event_resolver = _get_event_resolver()
	if _event_resolver != null:
		if not _event_resolver.event_presented.is_connected(_on_event_presented):
			_event_resolver.event_presented.connect(_on_event_presented)
		if not _event_resolver.event_resolved.is_connected(_on_event_resolved):
			_event_resolver.event_resolved.connect(_on_event_resolved)
	_tutorial_service = _get_tutorial_service()
	if _tutorial_service != null:
		if _tutorial_service.has_signal("step_changed") and not _tutorial_service.step_changed.is_connected(_on_tutorial_step_changed):
			_tutorial_service.step_changed.connect(_on_tutorial_step_changed)
		if _tutorial_service.has_signal("tutorial_completed") and not _tutorial_service.tutorial_completed.is_connected(_on_tutorial_completed):
			_tutorial_service.tutorial_completed.connect(_on_tutorial_completed)
		if _tutorial_service.has_method("start_onboarding") and not _tutorial_service.has_completed():
			_tutorial_service.start_onboarding()
	_telemetry_hub = _get_telemetry_hub()

func set_turn_manager(turn_manager) -> void:
	_turn_manager = turn_manager
	roll_requested.connect(_turn_manager.request_roll)
	confirm_requested.connect(_turn_manager.commit_dice)
	hold_requested.connect(_on_hold_request)
	if not _turn_manager.room_entered.is_connected(_on_room_entered):
		_turn_manager.room_entered.connect(_on_room_entered)
	if not _turn_manager.room_cycled.is_connected(_on_room_cycled):
		_turn_manager.room_cycled.connect(_on_room_cycled)
	if not _turn_manager.room_scouted.is_connected(_on_room_scouted):
		_turn_manager.room_scouted.connect(_on_room_scouted)
	if not _turn_manager.clue_milestone_reached.is_connected(_on_clue_milestone):
		_turn_manager.clue_milestone_reached.connect(_on_clue_milestone)
	if not _turn_manager.milestone_event_resolved.is_connected(_on_milestone_event_resolved):
		_turn_manager.milestone_event_resolved.connect(_on_milestone_event_resolved)
	if not _turn_manager.threat_attack_processed.is_connected(_on_threat_attack_processed):
		_turn_manager.threat_attack_processed.connect(_on_threat_attack_processed)
	if not _turn_manager.loot_awarded.is_connected(_on_loot_awarded):
		_turn_manager.loot_awarded.connect(_on_loot_awarded)
	_wire_dice_signals()
	_update_action_buttons()
	_update_overlay_hint()

func get_dice_subsystem():
	if _dice_subsystem == null:
		var path_new := NodePath("MainLayout/DiceDock/DiceViewportFrame/DiceViewportContainer/DiceViewport/DiceRoot")
		var path_legacy := NodePath("MainLayout/DiceSection/DiceViewportFrame/DiceViewportContainer/DiceViewport/DiceRoot")
		var path_older := NodePath("MainLayout/DiceSection/DiceViewportContainer/DiceViewport/DiceRoot")
		if has_node(path_new):
			_dice_subsystem = get_node(path_new)
		elif has_node(path_legacy):
			_dice_subsystem = get_node(path_legacy)
		elif has_node(path_older):
			_dice_subsystem = get_node(path_older)
	return _dice_subsystem

func _wire_dice_signals() -> void:
	var dice = get_dice_subsystem()
	if dice == null:
		return
	if dice.has_signal("roll_started") and not dice.roll_started.is_connected(_on_dice_roll_started):
		dice.roll_started.connect(_on_dice_roll_started)
	if dice.has_signal("roll_resolved") and not dice.roll_resolved.is_connected(_on_dice_roll_resolved):
		dice.roll_resolved.connect(_on_dice_roll_resolved)

func reset_hud_state() -> void:
	_reset_lock_ui()
	_last_locked.clear()
	_last_held.clear()
	_last_exhausted.clear()
	_rolling = false
	update_for_roll([1, 1, 1], [], [], [])
	_update_action_buttons()
	_update_overlay_hint()
	refresh_resource_panel()

func update_for_roll(results: Array[int], locked: Array[int], exhausted: Array[int], held: Array[int] = []) -> void:
	var locked_lookup: Dictionary = {}
	for index in locked:
		locked_lookup[index] = true
	var held_lookup: Dictionary = {}
	for index in held:
		held_lookup[index] = true
	_last_locked = locked.duplicate()
	_last_held = held.duplicate()
	_last_exhausted = exhausted.duplicate()
	for slot in _lock_slots:
		if slot == null:
			continue
		var token := slot.current_token
		if token and not locked_lookup.has(token.die_index) and not held_lookup.has(token.die_index):
			slot.release_token(token)
			_die_slot_map.erase(token.die_index)
			_ensure_token_in_shelf(token)
	var available_slots: Array[int] = []
	for slot_index in _lock_slots.size():
		var slot := _lock_slots[slot_index]
		if slot and slot.current_token == null:
			available_slots.append(slot_index)
	for token in _dice_tokens:
		if token == null:
			continue
		var die_index: int = token.die_index
		var value: int = results[die_index] if die_index < results.size() else 0
		var is_exhausted: bool = die_index in exhausted
		var should_lock: bool = locked_lookup.has(die_index) and not is_exhausted
		var should_hold: bool = held_lookup.has(die_index) and not is_exhausted
		token.set_value(value)
		if should_lock or should_hold:
			var slot_index: int = int(_die_slot_map.get(die_index, -1))
			if slot_index < 0 or slot_index >= _lock_slots.size() or _lock_slots[slot_index].current_token != token:
				if slot_index >= 0 and slot_index < _lock_slots.size():
					_lock_slots[slot_index].release_token(token)
				slot_index = 0 if available_slots.is_empty() else available_slots.pop_front()
				_assign_token_to_slot(token, slot_index)
			if should_lock:
				token.set_locked(true)
				token.set_held(false)
			else:
				token.set_locked(false)
				token.set_held(true)
		else:
			_ensure_token_in_shelf(token)
			token.set_held(false)
			token.set_locked(false)
			_die_slot_map.erase(die_index)
		token.set_exhausted(is_exhausted)
	_update_exhaust_label(exhausted)
	_update_action_buttons()
	_update_overlay_hint()

func refresh_resource_panel() -> void:
	if _resource_panel and _resource_panel.has_method("refresh"):
		_resource_panel.refresh()

func _on_roll_pressed() -> void:
	roll_requested.emit()

func _on_confirm_pressed() -> void:
	confirm_requested.emit()

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

func _update_action_buttons() -> void:
	var state := _current_turn_state()
	_roll_button.disabled = _rolling or _turn_manager == null
	if not _roll_button.disabled and (state == TurnManager.TurnState.ROLLING or state == TurnManager.TurnState.RESOLUTION):
		_roll_button.disabled = true
	_confirm_button.disabled = _rolling or _turn_manager == null or state != TurnManager.TurnState.ACTION

func _update_overlay_hint() -> void:
	if _overlay_hint == null:
		return
	if _rolling:
		_overlay_hint.text = "Rolling..."
		return
	var state := _current_turn_state()
	match state:
		TurnManager.TurnState.ACTION:
			if not _last_locked.is_empty():
				_overlay_hint.text = "Confirm to commit locked dice."
			elif not _last_held.is_empty():
				_overlay_hint.text = "Held dice stay between rolls."
			elif _last_exhausted.size() >= _dice_tokens.size():
				_overlay_hint.text = "Confirm to refresh your dice."
			else:
				_overlay_hint.text = "Drag dice into the lock zone to hold them."
		TurnManager.TurnState.ROLL_PREP:
			_overlay_hint.text = "Tap Roll to start the turn."
		TurnManager.TurnState.RESOLUTION:
			_overlay_hint.text = "Resolve the encounter, then roll again."
		_:
			_overlay_hint.text = "Tap Roll to start the turn."

func _current_turn_state() -> int:
	if _turn_manager == null:
		return TurnManager.TurnState.IDLE
	return _turn_manager.get_state()

func _set_rolling(enabled: bool) -> void:
	if _rolling == enabled:
		return
	_rolling = enabled
	_update_action_buttons()
	_update_overlay_hint()

func _on_dice_roll_started() -> void:
	_set_rolling(true)

func _on_dice_roll_resolved(_results: Array[int]) -> void:
	_set_rolling(false)

func _reset_lock_ui() -> void:
	_die_slot_map.clear()
	for slot in _lock_slots:
		if slot:
			slot.clear_slot()
	if _dice_token_shelf:
		for token in _dice_tokens:
			if token:
				token.set_locked(false)
				token.set_held(false)
				token.set_exhausted(false)
				_dice_token_shelf.add_token(token)

func _assign_token_to_slot(token: DieToken, slot_index: int) -> void:
	if token == null:
		return
	if slot_index < 0 or slot_index >= _lock_slots.size():
		return
	var slot := _lock_slots[slot_index]
	if slot == null:
		return
	_release_token_from_slots(token)
	if token.get_parent() == _dice_token_shelf:
		_dice_token_shelf.remove_token(token)
	slot.accept_token(token)
	_die_slot_map[token.die_index] = slot_index

func _release_token_from_slots(token: DieToken) -> void:
	for slot in _lock_slots:
		if slot and slot.current_token == token:
			slot.release_token(token)

func _ensure_token_in_shelf(token: DieToken) -> void:
	if token == null or _dice_token_shelf == null:
		return
	_release_token_from_slots(token)
	_die_slot_map.erase(token.die_index)
	if token.get_parent() != _dice_token_shelf:
		_dice_token_shelf.add_token(token)
	else:
		token.set_held(false)
		token.set_locked(false)

func _refresh_room_list() -> void:
	for child in _room_list_container.get_children():
		child.queue_free()
	if _current_queue.is_empty():
		_room_empty_label.show()
		return
	_room_empty_label.hide()
	for index in _current_queue.size():
		var button := _create_room_button(index, _current_queue[index])
		_room_list_container.add_child(button)

func _create_room_button(index: int, room: Dictionary) -> Button:
	var button := Button.new()
	var label := String(room.get("display_name", room.get("name", "Room")))
	if index == 0:
		label = "Top: %s" % label
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	if index == _selected_room_index:
		button.add_theme_color_override("font_color", COLOR_SELECTED_ROOM)
	button.pressed.connect(_on_room_button_pressed.bind(index))
	return button

func _on_room_button_pressed(index: int) -> void:
	if index < 0 or index >= _current_queue.size():
		return
	_select_room_index(index)

func _select_room_index(index: int) -> void:
	if index < 0 or index >= _current_queue.size():
		return
	_selected_room_index = index
	var room_copy := _current_queue[index].duplicate(true)
	_on_room_selected(index, room_copy)
	_refresh_room_list()

func _refresh_threat_list() -> void:
	for child in _threat_list_container.get_children():
		child.queue_free()
	if _current_threats.is_empty():
		_threat_empty_label.show()
		return
	_threat_empty_label.hide()
	for index in _current_threats.size():
		var button := _create_threat_button(index, _current_threats[index])
		_threat_list_container.add_child(button)

func _create_threat_button(index: int, threat: Dictionary) -> Button:
	var button := Button.new()
	button.text = String(threat.get("display_name", threat.get("name", "Threat")))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	var threat_id := String(threat.get("id", threat.get("slug", "")))
	if threat_id == _selected_threat_id:
		button.add_theme_color_override("font_color", COLOR_SELECTED_THREAT)
	button.pressed.connect(_on_threat_button_pressed.bind(index))
	return button

func _on_threat_button_pressed(index: int) -> void:
	if index < 0 or index >= _current_threats.size():
		return
	_select_threat_index(index)

func _select_threat_index(index: int) -> void:
	if index < 0 or index >= _current_threats.size():
		return
	var threat_copy := _current_threats[index].duplicate(true)
	_selected_threat_id = String(threat_copy.get("id", threat_copy.get("slug", "")))
	_on_threat_selected(threat_copy)
	_refresh_threat_list()

func _die_name_for_index(index: int) -> String:
	var names: Array[String] = ["Die A", "Die B", "Die C"]
	return names[index] if index < names.size() else "Die"

func _resolve_token_from_path(token_path: NodePath) -> DieToken:
	if token_path.is_empty():
		return null
	if not has_node(token_path):
		return null
	var node := get_node(token_path)
	if node is DieToken:
		return node
	return null

func _on_lock_slot_drop(token_path: NodePath, die_index: int, slot_index: int) -> void:
	var token := _resolve_token_from_path(token_path)
	if token == null:
		return
	if _turn_manager and _turn_manager.has_method("get_state"):
		if _turn_manager.get_state() != TurnManager.TurnState.ACTION:
			_ensure_token_in_shelf(token)
			return
	_assign_token_to_slot(token, slot_index)
	hold_requested.emit(die_index, true)

func _on_die_released(token_path: NodePath, die_index: int) -> void:
	var token := _resolve_token_from_path(token_path)
	if token == null:
		return
	_ensure_token_in_shelf(token)
	hold_requested.emit(die_index, false)

func _on_hold_request(index: int, should_hold: bool) -> void:
	if _turn_manager == null:
		return
	if _turn_manager.has_method("set_hold"):
		_turn_manager.set_hold(index, should_hold)
	elif _turn_manager.has_method("toggle_hold"):
		var subsystem = get_dice_subsystem()
		var currently_held: bool = subsystem != null and subsystem.has_method("is_die_held") and subsystem.is_die_held(index)
		if currently_held != should_hold:
			_turn_manager.toggle_hold(index)

func _on_room_queue_updated(queue: Array[Dictionary]) -> void:
	_current_queue.clear()
	for room in queue:
		_current_queue.append(room.duplicate(true))
	if queue.is_empty():
		_selected_room = {}
		_selected_room_index = -1
		_context_info.text = "No rooms queued. Explore the board to reveal new encounters."
		_update_context_buttons()
		_context_actions.visible = false
		_refresh_room_list()
		return
	var preferred_id: String = String(_selected_room.get("id", _selected_room.get("slug", "")))
	var resolved_index: int = -1
	for index in queue.size():
		var room_id: String = String(queue[index].get("id", queue[index].get("slug", "")))
		if not preferred_id.is_empty() and room_id == preferred_id:
			resolved_index = index
			break
	if resolved_index == -1:
		resolved_index = 0
	_select_room_index(resolved_index)

func _on_threats_updated(threats: Array[Dictionary]) -> void:
	_current_threats.clear()
	_selected_threat_id = ""
	if threats.is_empty():
		_refresh_threat_list()
		return
	for threat in threats:
		_current_threats.append(threat.duplicate(true))
	_refresh_threat_list()
	if _selected_room.is_empty() and not _current_threats.is_empty():
		_select_threat_index(0)

func _on_room_selected(index: int, room: Dictionary) -> void:
	_selected_room = room
	var summary: String = String(room.get("summary", "Uncharted module."))
	var tags: Array = room.get("tags", []) as Array
	var header := "[b]%s[/b]" % room.get("name", "Unknown Compartment")
	var tags_line := ""
	if not tags.is_empty():
		tags_line = "\nTags: %s" % ", ".join(tags)
	var rewards := "\nRewards → Clues: %d, Materials: %d, Oxygen Cost: %d" % [
		int(room.get("clue_reward", 0)),
		int(room.get("materials_reward", 0)),
		int(room.get("oxygen_cost", 0))
	]
	_context_info.text = "%s\n%s%s%s" % [header, summary, tags_line, rewards]
	_update_context_buttons()
	_context_actions.visible = true

func _on_threat_selected(threat: Dictionary) -> void:
	var header := "[b]%s[/b]" % threat.get("name", "Unknown Threat")
	var timer := int(threat.get("timer", 0))
	var severity: String = String(threat.get("severity", "moderate"))
	var description: String = String(threat.get("summary", "Threat details pending."))
	var statuses: Array = threat.get("status_effects", []) as Array
	var status_line := ""
	if not statuses.is_empty():
		var pieces: Array[String] = []
		for status in statuses:
			pieces.append("%s (%d)" % [status.get("label", "Effect"), int(status.get("duration", 0))])
		status_line = "\nStatuses: %s" % ", ".join(pieces)
	_context_info.text = "%s\nSeverity: %s\nTimer: %d\n%s%s" % [header, severity.capitalize(), timer, description, status_line]

func _clear_children(container: Node) -> void:
	var to_free: Array[Node] = []
	for child in container.get_children():
		to_free.append(child)
	for node in to_free:
		node.queue_free()

func _get_room_service():
	var tree := get_tree()
	if tree and tree.get_root().has_node("RoomQueueService"):
		return tree.get_root().get_node("RoomQueueService")
	return null

func _get_threat_service():
	var tree := get_tree()
	if tree and tree.get_root().has_node("ThreatService"):
		return tree.get_root().get_node("ThreatService")
	return null

func _get_event_resolver():
	var tree := get_tree()
	if tree and tree.get_root().has_node("EventResolver"):
		return tree.get_root().get_node("EventResolver")
	return null

func _get_inventory_model() -> Node:
	var tree := get_tree()
	if tree and tree.get_root().has_node("EquipmentInventoryModel"):
		return tree.get_root().get_node("EquipmentInventoryModel")
	return null

func _get_tutorial_service() -> Node:
	var tree := get_tree()
	if tree and tree.get_root().has_node("TutorialService"):
		return tree.get_root().get_node("TutorialService")
	return null

func _get_telemetry_hub() -> Node:
	var tree := get_tree()
	if tree and tree.get_root().has_node("TelemetryHub"):
		return tree.get_root().get_node("TelemetryHub")
	return null

func _record_ui_event(event_name: String, payload: Dictionary) -> void:
	if _telemetry_hub and _telemetry_hub.has_method("record"):
		_telemetry_hub.record(event_name, payload)

func _on_enter_room_pressed() -> void:
	if _turn_manager == null:
		return
	_turn_manager.enter_next_room()

func _on_cycle_room_pressed() -> void:
	if _turn_manager == null:
		return
	_turn_manager.cycle_top_room()
	_show_banner("Top room cycled (oxygen -1, threat +1).", false)

func _on_scout_room_pressed() -> void:
	if _turn_manager == null:
		return
	_turn_manager.scout_next_room()
	_show_banner("Scouting top room (oxygen -1).", false)

func _update_context_buttons() -> void:
	var top_room: Dictionary = {}
	if not _current_queue.is_empty():
		top_room = _current_queue[0]
	var can_enter: bool = not top_room.is_empty() and not _selected_room.is_empty() and top_room.get("id", "") == _selected_room.get("id", "")
	_enter_room_button.disabled = not can_enter
	_cycle_room_button.disabled = top_room.is_empty()
	_scout_room_button.disabled = top_room.is_empty()
	_context_actions.visible = not top_room.is_empty()

func _show_banner(text: String, critical: bool) -> void:
	_banner_label.text = text
	_banner_panel.visible = true
	if critical:
		_banner_panel.modulate = Color(0.658824, 0.203922, 0.231373, 0.92)
	else:
		_banner_panel.modulate = Color(0.137255, 0.203922, 0.313726, 0.92)
	_banner_timer.start()

func _on_banner_timer_timeout() -> void:
	_banner_panel.visible = false

func _on_room_entered(room: Dictionary) -> void:
	_selected_room = {}
	_selected_room_index = -1
	var summary: String = String(room.get("summary", ""))
	_context_info.text = "[b]%s entered[/b]\n%s" % [room.get("name", "Room"), summary]
	_show_banner("Room entered: %s" % room.get("name", "Room"), false)
	_update_context_buttons()

func _on_room_cycled(room: Dictionary) -> void:
	_selected_room = {}
	_selected_room_index = -1
	_context_info.text = "Cycled room: %s" % room.get("name", "Unknown")
	_update_context_buttons()

func _on_room_scouted(room: Dictionary) -> void:
	_last_scouted_room = room
	var tags: Array = room.get("tags", []) as Array
	var preview: String = "Scouted room: [b]%s[/b]\nTags: %s" % [room.get("name", "Unknown"), ", ".join(tags)]
	_context_info.text = preview
	_show_banner("Scouted upcoming room.", false)

func _on_clue_milestone(milestone: int, _event_id: String) -> void:
	_show_banner("Clue milestone reached (%d). Make a strategic choice." % milestone, false)

func _on_milestone_event_resolved(_event_id: String, outcome: Dictionary) -> void:
	var message := String(outcome.get("message", "Milestone resolved."))
	_show_banner(message, false)

func _on_threat_attack_processed(threat_id: String, attack: Dictionary) -> void:
	var damage: int = int(attack.get("damage", 0))
	var threat_delta: int = int(attack.get("threat_delta", 0))
	var statuses: Array = attack.get("statuses", []) as Array
	var status_text: String = ""
	if not statuses.is_empty():
		var parts: Array = []
		for status in statuses:
			parts.append(status.get("label", "Status"))
		status_text = " Status effects: %s." % ", ".join(parts)
	var text: String = "Threat %s attacks! Damage %d, threat %+d.%s" % [threat_id, damage, threat_delta, status_text]
	_show_banner(text, true)

func _on_event_presented(event_data: Dictionary) -> void:
	_event_overlay.visible = true
	_clear_children(_event_choices)
	_event_title.text = String(event_data.get("title", "Milestone Event"))
	_event_body.text = String(event_data.get("description", "Make your choice."))
	var choices: Array = event_data.get("choices", []) as Array
	for choice in choices:
		var button := Button.new()
		button.text = String(choice.get("label", "Choose"))
		button.size_flags_horizontal = Control.SIZE_FILL
		button.pressed.connect(_on_event_choice_pressed.bind(String(choice.get("id", ""))))
		_event_choices.add_child(button)

func _on_event_choice_pressed(choice_id: String) -> void:
	if _event_resolver:
		_event_resolver.resolve_choice(choice_id)

func _on_event_resolved(_result: Dictionary) -> void:
	_event_overlay.visible = false

func _on_loot_awarded(loot: Dictionary) -> void:
	var item_id: String = String(loot.get("id", ""))
	var display_name: String = item_id
	var inventory: Node = _get_inventory_model()
	if inventory and inventory.has_method("get_catalog"):
		var catalog: Dictionary = inventory.get_catalog()
		if catalog.has(item_id):
			display_name = catalog[item_id].get("name", item_id.capitalize())
	_show_banner("Loot acquired: %s" % display_name, false)

func _on_equipment_placement_failed(reason: String) -> void:
	_show_banner(reason, true)

func _on_tutorial_step_changed(step: Dictionary) -> void:
	_tutorial_title.text = String(step.get("title", "Tutorial"))
	_tutorial_body.text = String(step.get("body", ""))
	_tutorial_overlay.visible = true
	_show_banner("Tutorial: %s" % step.get("title", ""), false)
	_record_ui_event("tutorial_step", step)

func _on_tutorial_completed() -> void:
	_tutorial_overlay.visible = false
	_show_banner("Tutorial complete. Good luck!", false)
	_record_ui_event("tutorial_completed", {})

func _on_tutorial_next_pressed() -> void:
	if _tutorial_service and _tutorial_service.has_method("advance"):
		_tutorial_service.advance()
	_record_ui_event("tutorial_next", {})

func _on_tutorial_skip_pressed() -> void:
	if _tutorial_service and _tutorial_service.has_method("skip"):
		_tutorial_service.skip()
	else:
		_tutorial_overlay.visible = false
	_record_ui_event("tutorial_skipped", {})
