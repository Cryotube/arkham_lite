extends Node
class_name TurnManager

const DiceSubsystem = preload("res://scripts/systems/dice_subsystem.gd")

enum TurnState { IDLE, ROLL_PREP, ROLLING, ACTION, RESOLUTION }

signal turn_started(state: TurnState)
signal dice_committed(results: Array[int])
signal dice_locked_changed(locked_indices: Array[int])
signal turn_completed
signal room_entered(room: Dictionary)
signal room_cycled(room: Dictionary)
signal room_scouted(room: Dictionary)
signal clue_milestone_reached(milestone: int, event_id: String)
signal milestone_event_resolved(event_id: String, outcome: Dictionary)
signal threat_attack_processed(threat_id: String, attack: Dictionary)
signal loot_awarded(loot: Dictionary)

const CLUE_MILESTONES: Array[int] = [3, 6, 10]
const ROOM_CYCLE_OXYGEN_COST: int = 1
const ROOM_CYCLE_THREAT_PENALTY: int = 1
const SCOUT_OXYGEN_COST: int = 1

var _dice_subsystem = null
var _hud_controller = null
var _state: TurnState = TurnState.IDLE
var _current_results: Array[int] = []
var _exhausted_indices: Array[int] = []
var _room_service: Node = null
var _threat_service: Node = null
var _event_resolver: Node = null
var _loot_service: Node = null
var _telemetry_hub: Node = null
var _clues_collected: int = 0
var _last_milestone_event_id: String = ""

func _ready() -> void:
	_resolve_support_services()

const MILESTONE_EVENTS: Dictionary = {
	3: {
		"id": "beacon_charge",
		"title": "Charge the Rescue Beacon",
		"description": "The clues form a partial frequency map. Do you divert scarce materials to boost the emergency beacon or stay stealthy?",
		"choices": [
			{
				"id": "boost_signal",
				"label": "Divert power cells (-2 materials, -1 threat)",
				"outcome": {"materials_delta": -2, "threat_delta": -1, "message": "Beacon hum stabilizes, threat briefly recedes."}
			},
			{
				"id": "mask_presence",
				"label": "Layer masking fields (+1 threat, +1 clue)",
				"outcome": {"threat_delta": 1, "clue_delta": 1, "message": "You stay hidden but decoding slows; a new clue falls into place."}
			}
		]
	},
	6: {
		"id": "decoder_array",
		"title": "Calibrate the Decoder Array",
		"description": "Collected schematics unlock a dormant decoder. Do you risk the array overheating for accelerated insights?",
		"choices": [
			{
				"id": "overclock",
				"label": "Overclock the array (-1 health, -2 threat, scout next room)",
				"outcome": {"health_delta": -1, "threat_delta": -2, "scout_queue": true, "message": "Pain flares as the array blasts noise, but the threat reels."}
			},
			{
				"id": "steady",
				"label": "Run steady diagnostics (-1 materials, spawn retaliatory threat)",
				"outcome": {"materials_delta": -1, "spawn_threat": "signal_intruder", "message": "Diagnostics proceed quietly, but hostile code sneaks through."}
			}
		]
	}
}

func initialize(dice_subsystem, hud_controller) -> void:
	_dice_subsystem = dice_subsystem
	_hud_controller = hud_controller
	if not _dice_subsystem.roll_resolved.is_connected(_on_roll_resolved):
		_dice_subsystem.roll_resolved.connect(_on_roll_resolved)
	if not _dice_subsystem.lock_state_changed.is_connected(_on_lock_state_changed):
		_dice_subsystem.lock_state_changed.connect(_on_lock_state_changed)
	_resolve_support_services()
	_reset_state()

func start_new_run() -> void:
	_reset_state()
	_clues_collected = 0
	_last_milestone_event_id = ""
	start_turn()

func start_turn() -> void:
	_state = TurnState.ROLL_PREP
	_exhausted_indices.clear()
	_dice_subsystem.reset()
	if _hud_controller != null:
		_hud_controller.reset_hud_state()
	turn_started.emit(_state)

func request_roll() -> void:
	if _state in [TurnState.RESOLUTION, TurnState.ROLLING]:
		return
	if _dice_subsystem == null:
		return
	if not _exhausted_indices.is_empty():
		_dice_subsystem.refresh_exhausted_dice()
		_exhausted_indices.clear()
	_state = TurnState.ROLLING
	_dice_subsystem.request_roll()

func toggle_lock(index: int) -> void:
	if _state != TurnState.ACTION:
		return
	if _dice_subsystem == null:
		return
	var should_lock = not _dice_subsystem.is_die_locked(index)
	_dice_subsystem.set_die_locked(index, should_lock)
	_update_hud()

func commit_dice() -> void:
	if _state != TurnState.ACTION:
		return
	if _dice_subsystem == null:
		return
	var newly_exhausted = _dice_subsystem.exhaust_locked_dice()
	for index in newly_exhausted:
		if index not in _exhausted_indices:
			_exhausted_indices.append(index)
	dice_committed.emit(_current_results.duplicate())
	_apply_roll_outcome()
	_update_hud()
	if _exhausted_indices.size() >= DiceSubsystem.DICE_POOL_SIZE:
		_state = TurnState.RESOLUTION
		turn_completed.emit()
	else:
		_state = TurnState.ROLL_PREP

func _on_roll_resolved(results: Array[int]) -> void:
	if _dice_subsystem == null:
		return
	_current_results = results.duplicate()
	_state = TurnState.ACTION
	_update_hud()

func _on_lock_state_changed(_locked: Array[int]) -> void:
	dice_locked_changed.emit(_locked.duplicate())
	_update_hud()

func _update_hud() -> void:
	if _hud_controller == null or _dice_subsystem == null:
		return
	var locked = _dice_subsystem.get_locked_indices()
	_hud_controller.update_for_roll(_current_results, locked, _exhausted_indices)

func _reset_state() -> void:
	_current_results = [1, 1, 1]
	_exhausted_indices.clear()
	_state = TurnState.IDLE

func _apply_roll_outcome() -> void:
	var ledger = _get_resource_ledger()
	if ledger:
		ledger.apply_roll_outcome(_current_results)

func _get_resource_ledger():
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null:
		return null
	var root := tree.get_root()
	if root and root.has_node("ResourceLedger"):
		return root.get_node("ResourceLedger")
	return null

func get_state() -> TurnState:
	return _state

func get_current_results() -> Array[int]:
	return _current_results.duplicate()

func get_exhausted_indices() -> Array[int]:
	return _exhausted_indices.duplicate()

func cycle_top_room() -> void:
	if _room_service == null:
		return
	var cycled: Dictionary = _room_service.cycle_top_room()
	if cycled.is_empty():
		return
	var ledger = _get_resource_ledger()
	if ledger:
		ledger.adjust_oxygen(-ROOM_CYCLE_OXYGEN_COST)
		ledger.adjust_threat(ROOM_CYCLE_THREAT_PENALTY)
	_record_telemetry("room_cycle", {"room_id": cycled.get("id", ""), "oxygen_cost": ROOM_CYCLE_OXYGEN_COST, "threat_penalty": ROOM_CYCLE_THREAT_PENALTY})
	room_cycled.emit(cycled)

func scout_next_room() -> void:
	if _room_service == null:
		return
	var room: Dictionary = _room_service.peek_next_room()
	if room.is_empty():
		return
	var ledger = _get_resource_ledger()
	if ledger:
		ledger.adjust_oxygen(-SCOUT_OXYGEN_COST)
	_record_telemetry("room_scout", {"room_id": room.get("id", ""), "oxygen_cost": SCOUT_OXYGEN_COST})
	room_scouted.emit(room)

func enter_next_room() -> void:
	if _room_service == null:
		return
	var room: Dictionary = _room_service.draw_next_room()
	if room.is_empty():
		return
	_apply_room_rewards(room)
	_handle_room_threat(room)
	_award_room_loot(room)
	_record_telemetry("room_enter", {"room_id": room.get("id", ""), "clues": _clues_collected})
	room_entered.emit(room)

func get_clue_count() -> int:
	return _clues_collected

func _resolve_support_services() -> void:
	_room_service = _get_room_queue()
	_threat_service = _get_threat_service()
	if _threat_service and not _threat_service.threat_attack_resolved.is_connected(_on_threat_attack_resolved):
		_threat_service.threat_attack_resolved.connect(_on_threat_attack_resolved)
	_event_resolver = _get_event_resolver()
	if _event_resolver and not _event_resolver.event_resolved.is_connected(_on_event_resolved):
		_event_resolver.event_resolved.connect(_on_event_resolved)
	_loot_service = _get_loot_service()
	_telemetry_hub = _get_telemetry_hub()

func _apply_room_rewards(room: Dictionary) -> void:
	var ledger = _get_resource_ledger()
	if ledger:
		ledger.adjust_materials(int(room.get("materials_reward", 0)))
		ledger.adjust_oxygen(-int(room.get("oxygen_cost", 0)))
	var clue_gain := int(room.get("clue_reward", 0))
	if clue_gain > 0:
		_clues_collected += clue_gain
		_record_telemetry("clue_gain", {"room_id": room.get("id", ""), "amount": clue_gain, "total": _clues_collected})
		_check_clue_milestones()

func _award_room_loot(room: Dictionary) -> void:
	if _loot_service == null:
		return
	if not _loot_service.has_method("roll_loot_for_room"):
		return
	var loot_variant = _loot_service.roll_loot_for_room(room)
	if typeof(loot_variant) != TYPE_DICTIONARY:
		return
	var loot: Dictionary = loot_variant
	if loot.is_empty():
		return
	_add_loot_to_inventory(loot)
	loot_awarded.emit(loot)

func _handle_room_threat(room: Dictionary) -> void:
	if _threat_service == null:
		return
	var threat_id: String = String(room.get("threat", ""))
	if threat_id.is_empty():
		return
	var template: Dictionary = {}
	if _threat_service.has_method("build_from_template"):
		template = _threat_service.build_from_template(threat_id) as Dictionary
	if template.is_empty():
		template = {"id": threat_id, "name": threat_id.capitalize()}
	_threat_service.latch_threat(template)

func _check_clue_milestones() -> void:
	for milestone in CLUE_MILESTONES:
		if _clues_collected >= milestone and milestone > 0:
			var event_data_variant: Variant = MILESTONE_EVENTS.get(milestone, null)
			if event_data_variant == null:
				continue
			var event_data: Dictionary = event_data_variant as Dictionary
			var event_id: String = String(event_data.get("id", "milestone_%d" % milestone))
			if event_id == _last_milestone_event_id:
				continue
			_trigger_milestone_event(milestone, event_data)
			_last_milestone_event_id = event_id
			break

func _trigger_milestone_event(milestone: int, event_data: Dictionary) -> void:
	if _event_resolver:
		_event_resolver.present_event(event_data)
	_record_telemetry("clue_milestone", {"milestone": milestone, "event_id": event_data.get("id", "")})
	clue_milestone_reached.emit(milestone, String(event_data.get("id", "")))

func _on_event_resolved(outcome: Dictionary) -> void:
	if outcome.is_empty():
		milestone_event_resolved.emit(_last_milestone_event_id, outcome)
		return
	var ledger = _get_resource_ledger()
	if ledger:
		ledger.adjust_materials(int(outcome.get("materials_delta", 0)))
		ledger.adjust_oxygen(int(outcome.get("oxygen_delta", 0)))
		ledger.adjust_health(int(outcome.get("health_delta", 0)))
		ledger.adjust_threat(int(outcome.get("threat_delta", 0)))
	var clue_delta := int(outcome.get("clue_delta", 0))
	if clue_delta != 0:
		_clues_collected = max(0, _clues_collected + clue_delta)
	if outcome.get("scout_queue", false):
		scout_next_room()
	var spawn_threat: String = String(outcome.get("spawn_threat", ""))
	if spawn_threat != "":
		if _threat_service:
			var template: Dictionary = {}
			if _threat_service.has_method("build_from_template"):
				template = _threat_service.build_from_template(spawn_threat) as Dictionary
			if not template.is_empty():
				_threat_service.latch_threat(template)
	_record_telemetry("milestone_resolved", {"event_id": _last_milestone_event_id, "outcome": outcome})
	var scripted_loot: String = String(outcome.get("loot_reward", ""))
	if not scripted_loot.is_empty():
		var loot := {
			"id": scripted_loot,
			"rarity": "scripted",
			"source_room": _last_milestone_event_id
		}
		_add_loot_to_inventory(loot)
		loot_awarded.emit(loot)
	milestone_event_resolved.emit(_last_milestone_event_id, outcome)

func _on_threat_attack_resolved(threat_id: String, attack: Dictionary) -> void:
	var ledger = _get_resource_ledger()
	if ledger:
		ledger.adjust_health(-int(attack.get("damage", 0)))
		ledger.adjust_threat(int(attack.get("threat_delta", 0)))
	_record_telemetry("threat_attack", {"threat_id": threat_id, "damage": attack.get("damage", 0), "threat_delta": attack.get("threat_delta", 0)})
	threat_attack_processed.emit(threat_id, attack.duplicate(true))

func _add_loot_to_inventory(loot: Dictionary) -> void:
	var item_id: String = String(loot.get("id", ""))
	if item_id.is_empty():
		return
	var inventory: Node = _get_equipment_inventory()
	if inventory != null and inventory.has_method("add_loot"):
		inventory.add_loot(item_id)
	_record_telemetry("loot_awarded", loot)

func _get_room_queue():
	if not is_inside_tree():
		return null
	var root := get_tree().get_root()
	if root and root.has_node("RoomQueueService"):
		return root.get_node("RoomQueueService")
	return null

func _get_threat_service():
	if not is_inside_tree():
		return null
	var root := get_tree().get_root()
	if root and root.has_node("ThreatService"):
		return root.get_node("ThreatService")
	return null

func _get_event_resolver():
	if not is_inside_tree():
		return null
	var root := get_tree().get_root()
	if root and root.has_node("EventResolver"):
		return root.get_node("EventResolver")
	return null

func _get_loot_service():
	if not is_inside_tree():
		return null
	var root := get_tree().get_root()
	if root and root.has_node("LootService"):
		return root.get_node("LootService")
	return null

func _get_equipment_inventory():
	if not is_inside_tree():
		return null
	var root := get_tree().get_root()
	if root and root.has_node("EquipmentInventoryModel"):
		return root.get_node("EquipmentInventoryModel")
	return null

func _get_telemetry_hub():
	if not is_inside_tree():
		return null
	var root := get_tree().get_root()
	if root and root.has_node("TelemetryHub"):
		return root.get_node("TelemetryHub")
	return null

func _record_telemetry(event_name: String, payload: Dictionary) -> void:
	if _telemetry_hub == null or not is_instance_valid(_telemetry_hub):
		_telemetry_hub = _get_telemetry_hub()
	if _telemetry_hub and _telemetry_hub.has_method("record"):
		_telemetry_hub.record(event_name, payload.duplicate(true))
