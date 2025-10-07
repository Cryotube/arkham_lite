extends Node

const RUN_HUD_SCENE: PackedScene = preload("res://scenes/ui/run_hud.tscn")

var _run_hud = null
var _dice_subsystem = null
var _turn_manager: TurnManager = null
var _initialized: bool = false

func _ready() -> void:
	if _initialized:
		return
	_initialize_run()

func _initialize_run() -> void:
	await _spawn_run_hud()
	_wire_turn_manager()
	_initialized = true

func _spawn_run_hud() -> void:
	var hud_instance := RUN_HUD_SCENE.instantiate()
	hud_instance.name = "RunHUD"
	get_tree().root.call_deferred("add_child", hud_instance)
	await hud_instance.ready
	_run_hud = hud_instance
	_dice_subsystem = _run_hud.get_dice_subsystem()

func _wire_turn_manager() -> void:
	_turn_manager = TurnManagerSingleton
	_turn_manager.initialize(_dice_subsystem, _run_hud)
	_run_hud.set_turn_manager(_turn_manager)
	var ledger = _get_resource_ledger()
	if ledger:
		ledger.start_new_run()
	var room_queue = _get_room_queue_service()
	if room_queue:
		room_queue.reset(true)
	var threat_service = _get_threat_service()
	if threat_service:
		threat_service.reset()
	var equipment_inventory = _get_equipment_inventory()
	if equipment_inventory:
		equipment_inventory.reset()
	_turn_manager.start_new_run()
	_run_hud.refresh_resource_panel()
	_record_telemetry("run_initialized", {})

func restart_run() -> void:
	if not _initialized:
		_initialize_run()
		return
	var ledger = _get_resource_ledger()
	if ledger:
		ledger.start_new_run(true)
	var room_queue = _get_room_queue_service()
	if room_queue:
		room_queue.reset(true)
	var threat_service = _get_threat_service()
	if threat_service:
		threat_service.reset()
	var equipment_inventory = _get_equipment_inventory()
	if equipment_inventory:
		equipment_inventory.reset()
	_turn_manager.start_new_run()
	_run_hud.reset_hud_state()
	_record_telemetry("run_restarted", {"forced": true})

func _get_resource_ledger():
	var root := get_tree().get_root()
	if root and root.has_node("ResourceLedger"):
		return root.get_node("ResourceLedger")
	return null

func get_current_hud():
	return _run_hud

func get_dice_subsystem():
	return _dice_subsystem

func _get_room_queue_service():
	var root := get_tree().get_root()
	if root and root.has_node("RoomQueueService"):
		return root.get_node("RoomQueueService")
	return null

func _get_threat_service():
	var root := get_tree().get_root()
	if root and root.has_node("ThreatService"):
		return root.get_node("ThreatService")
	return null

func _get_equipment_inventory():
	var root := get_tree().get_root()
	if root and root.has_node("EquipmentInventoryModel"):
		return root.get_node("EquipmentInventoryModel")
	return null

func _get_telemetry_hub():
	var root := get_tree().get_root()
	if root and root.has_node("TelemetryHub"):
		return root.get_node("TelemetryHub")
	return null

func _record_telemetry(event_name: String, payload: Dictionary) -> void:
	var hub: Node = _get_telemetry_hub()
	if hub and hub.has_method("record"):
		hub.record(event_name, payload)
