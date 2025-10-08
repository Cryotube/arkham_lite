extends Control
class_name RunHudController

const DieToken = preload("res://scripts/ui/die_token.gd")
const DiceTokenShelf = preload("res://scripts/ui/dice_token_shelf.gd")
const DiceLockSlot = preload("res://scripts/ui/dice_lock_slot.gd")
const TurnManager = preload("res://scripts/systems/turn_manager.gd")

signal roll_requested
signal confirm_requested
signal lock_requested(index: int, should_lock: bool)

var _dice_subsystem = null
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
@onready var _resource_panel = $"MainLayout/ResourcePanel"
@onready var _room_list: VBoxContainer = $"MainLayout/MainBody/LeftDock/RoomList"
@onready var _threat_list: VBoxContainer = $"MainLayout/MainBody/LeftDock/ThreatList"
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

var _turn_manager: TurnManager = null
var _room_queue_service: Node = null
var _threat_service: Node = null
var _event_resolver: Node = null
var _selected_room: Dictionary = {}
var _current_queue: Array[Dictionary] = []
var _last_scouted_room: Dictionary = {}
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
	lock_requested.connect(_on_lock_request)
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

func reset_hud_state() -> void:
	_reset_lock_ui()
	update_for_roll([1, 1, 1], [], [])
	refresh_resource_panel()

func update_for_roll(results: Array[int], locked: Array[int], exhausted: Array[int]) -> void:
	var locked_lookup: Dictionary = {}
	for index in locked:
		locked_lookup[index] = true
	for slot in _lock_slots:
		if slot == null:
			continue
		var token := slot.current_token
		if token and not locked_lookup.has(token.die_index):
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
		token.set_value(value)
		if should_lock:
			var slot_index: int = int(_die_slot_map.get(die_index, -1))
			if slot_index < 0 or slot_index >= _lock_slots.size() or _lock_slots[slot_index].current_token != token:
				if slot_index >= 0 and slot_index < _lock_slots.size():
					_lock_slots[slot_index].release_token(token)
				slot_index = 0 if available_slots.is_empty() else available_slots.pop_front()
				_assign_token_to_slot(token, slot_index)
			else:
				token.set_locked(true)
		else:
			_ensure_token_in_shelf(token)
			token.set_locked(false)
			_die_slot_map.erase(die_index)
		token.set_exhausted(is_exhausted)
	_update_exhaust_label(exhausted)

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

func _reset_lock_ui() -> void:
	_die_slot_map.clear()
	for slot in _lock_slots:
		if slot:
			slot.clear_slot()
	if _dice_token_shelf:
		for token in _dice_tokens:
			if token:
				token.set_locked(false)
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
	lock_requested.emit(die_index, true)

func _on_die_released(token_path: NodePath, die_index: int) -> void:
	var token := _resolve_token_from_path(token_path)
	if token == null:
		return
	_ensure_token_in_shelf(token)
	lock_requested.emit(die_index, false)

func _on_lock_request(index: int, should_lock: bool) -> void:
	if _turn_manager == null:
		return
	if _turn_manager.has_method("set_lock"):
		_turn_manager.set_lock(index, should_lock)
	elif _turn_manager.has_method("toggle_lock"):
		var subsystem = get_dice_subsystem()
		var currently_locked: bool = subsystem != null and subsystem.is_die_locked(index)
		if currently_locked != should_lock:
			_turn_manager.toggle_lock(index)

func _on_room_queue_updated(queue: Array[Dictionary]) -> void:
	_clear_children(_room_list)
	_current_queue.clear()
	for room in queue:
		_current_queue.append(room.duplicate(true))
	if queue.is_empty():
		_room_list.add_child(_make_placeholder_label("No rooms available."))
		_selected_room = {}
		_update_context_buttons()
		return
	for index in queue.size():
		var room: Dictionary = queue[index]
		var button := Button.new()
		button.text = room.get("name", "Unknown Compartment")
		button.tooltip_text = room.get("summary", "")
		button.size_flags_horizontal = Control.SIZE_FILL
		button.pressed.connect(_on_room_selected.bind(index, room.duplicate(true)))
		_room_list.add_child(button)
	_update_context_buttons()

func _on_threats_updated(threats: Array[Dictionary]) -> void:
	_clear_children(_threat_list)
	if threats.is_empty():
		_threat_list.add_child(_make_placeholder_label("No active threats."))
		return
	for threat in threats:
		var button := Button.new()
		var severity: String = String(threat.get("severity", ""))
		button.text = "%s (T-%d | %s)" % [
			threat.get("name", "Unknown Threat"),
			int(threat.get("timer", 0)),
			severity.capitalize()
		]
		var statuses := threat.get("status_effects", []) as Array
		var tooltip_lines: Array[String] = []
		tooltip_lines.append(String(threat.get("summary", "")))
		if not statuses.is_empty():
			var status_strings: Array[String] = []
			for status in statuses:
				status_strings.append("%s (%d)" % [status.get("label", "Status"), int(status.get("duration", 0))])
			tooltip_lines.append("Effects: %s" % ", ".join(status_strings))
		button.tooltip_text = "\n".join(tooltip_lines)
		button.size_flags_horizontal = Control.SIZE_FILL
		button.pressed.connect(_on_threat_selected.bind(threat.duplicate(true)))
		_threat_list.add_child(button)

func _on_room_selected(index: int, room: Dictionary) -> void:
	_selected_room = room
	var summary: String = String(room.get("summary", "Uncharted module."))
	var tags := (room.get("tags", []) as Array)
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

func _on_threat_selected(threat: Dictionary) -> void:
	var header := "[b]%s[/b]" % threat.get("name", "Unknown Threat")
	var timer := int(threat.get("timer", 0))
	var severity: String = String(threat.get("severity", "moderate"))
	var description: String = String(threat.get("summary", "Threat details pending."))
	var statuses := threat.get("status_effects", []) as Array
	var status_line := ""
	if not statuses.is_empty():
		var pieces: Array[String] = []
		for status in statuses:
			pieces.append("%s (%d)" % [status.get("label", "Effect"), int(status.get("duration", 0))])
		status_line = "\nStatuses: %s" % ", ".join(pieces)
	_context_info.text = "%s\nSeverity: %s\nTimer: %d\n%s%s" % [header, severity.capitalize(), timer, description, status_line]

func _make_placeholder_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

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
	var summary: String = String(room.get("summary", ""))
	_context_info.text = "[b]%s entered[/b]\n%s" % [room.get("name", "Room"), summary]
	_show_banner("Room entered: %s" % room.get("name", "Room"), false)
	_update_context_buttons()

func _on_room_cycled(room: Dictionary) -> void:
	_selected_room = {}
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
