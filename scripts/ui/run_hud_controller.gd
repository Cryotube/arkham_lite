extends Control
class_name RunHudController

signal roll_requested
signal confirm_requested
signal lock_requested(index: int)

var _dice_subsystem = null
@onready var _die_labels: Array[Label] = [
	$"MainLayout/DiceSection/DiceValues/Die0" as Label,
	$"MainLayout/DiceSection/DiceValues/Die1" as Label,
	$"MainLayout/DiceSection/DiceValues/Die2" as Label
]
@onready var _lock_buttons: Array[Button] = [
	$"MainLayout/DiceSection/LockRow/Lock0",
	$"MainLayout/DiceSection/LockRow/Lock1",
	$"MainLayout/DiceSection/LockRow/Lock2"
]
@onready var _roll_button: Button = $"MainLayout/DiceSection/ActionButtons/RollButton"
@onready var _confirm_button: Button = $"MainLayout/DiceSection/ActionButtons/ConfirmButton"
@onready var _exhaust_label: Label = $"MainLayout/DiceSection/ExhaustTray/ExhaustLabel"
@onready var _resource_panel = $"MainLayout/ResourcePanel"
@onready var _room_list: VBoxContainer = $"MainLayout/MainBody/LeftDock/RoomList"
@onready var _threat_list: VBoxContainer = $"MainLayout/MainBody/LeftDock/ThreatList"
@onready var _context_info: RichTextLabel = $"MainLayout/MainBody/RightColumn/ContextInfo"
@onready var _enter_room_button: Button = $"MainLayout/MainBody/RightColumn/ContextActions/EnterButton"
@onready var _cycle_room_button: Button = $"MainLayout/MainBody/RightColumn/ContextActions/CycleButton"
@onready var _scout_room_button: Button = $"MainLayout/MainBody/RightColumn/ContextActions/ScoutButton"
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

func _ready() -> void:
	_connect_inputs()
	_connect_services()
	if _equipment_tab != null and _equipment_tab.has_signal("placement_failed"):
		_equipment_tab.placement_failed.connect(_on_equipment_placement_failed)
	if _dice_subsystem == null and has_node("MainLayout/DiceSection/DiceViewportContainer/DiceViewport/DiceRoot"):
		_dice_subsystem = get_node("MainLayout/DiceSection/DiceViewportContainer/DiceViewport/DiceRoot")
	reset_hud_state()
	refresh_resource_panel()

func _connect_inputs() -> void:
	_roll_button.pressed.connect(_on_roll_pressed)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	for index in _lock_buttons.size():
		_lock_buttons[index].pressed.connect(_on_lock_button_pressed.bind(index))
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
	lock_requested.connect(_turn_manager.toggle_lock)
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
	if _dice_subsystem == null and has_node("MainLayout/DiceSection/DiceViewportContainer/DiceViewport/DiceRoot"):
		_dice_subsystem = get_node("MainLayout/DiceSection/DiceViewportContainer/DiceViewport/DiceRoot")
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
