extends HBoxContainer
class_name ResourcePanelController

const NORMAL_COLOR: Color = Color("22c55e")
const WARNING_COLOR: Color = Color("fbbf24")
const CRITICAL_COLOR: Color = Color("ef4444")

@export var thresholds_resource: Resource

@onready var _health_bar: ProgressBar = $"HealthMeter/HealthProgressBar"
@onready var _health_label: Label = $"HealthMeter/HealthValueLabel"
@onready var _materials_bar: ProgressBar = $"MaterialsMeter/MaterialsProgressBar"
@onready var _materials_label: Label = $"MaterialsMeter/MaterialsValueLabel"
@onready var _oxygen_bar: ProgressBar = $"OxygenMeter/OxygenProgressBar"
@onready var _oxygen_label: Label = $"OxygenMeter/OxygenValueLabel"
@onready var _threat_meter_node: Node = $"ThreatMeter"

var _threshold_map: Dictionary = {}

func _ready() -> void:
	_load_thresholds()
	var ledger = _get_resource_ledger()
	var threat_meter = _get_threat_meter()
	if ledger:
		ledger.health_changed.connect(_on_health_changed)
		ledger.materials_changed.connect(_on_materials_changed)
		ledger.oxygen_changed.connect(_on_oxygen_changed)
		ledger.threat_changed.connect(_on_threat_changed)
		if threat_meter and threat_meter.has_method("handle_threshold_cross"):
			ledger.threat_threshold_crossed.connect(threat_meter.handle_threshold_cross)
	refresh()

func _exit_tree() -> void:
	var ledger = _get_resource_ledger()
	var threat_meter = _get_threat_meter()
	if ledger:
		if ledger.health_changed.is_connected(_on_health_changed):
			ledger.health_changed.disconnect(_on_health_changed)
		if ledger.materials_changed.is_connected(_on_materials_changed):
			ledger.materials_changed.disconnect(_on_materials_changed)
		if ledger.oxygen_changed.is_connected(_on_oxygen_changed):
			ledger.oxygen_changed.disconnect(_on_oxygen_changed)
		if ledger.threat_changed.is_connected(_on_threat_changed):
			ledger.threat_changed.disconnect(_on_threat_changed)
		if threat_meter and threat_meter.has_method("handle_threshold_cross") and ledger.threat_threshold_crossed.is_connected(threat_meter.handle_threshold_cross):
			ledger.threat_threshold_crossed.disconnect(threat_meter.handle_threshold_cross)

func refresh() -> void:
	var ledger = _get_resource_ledger()
	var threat_meter = _get_threat_meter()
	if not ledger:
		return
	_on_health_changed(ledger.get_health(), ledger.max_health)
	_on_materials_changed(ledger.get_materials(), ledger.max_materials)
	_on_oxygen_changed(ledger.get_oxygen(), ledger.max_oxygen)
	if threat_meter and threat_meter.has_method("update_threat"):
		threat_meter.update_threat(ledger.get_threat(), ledger.max_threat)

func _on_health_changed(current: int, max_value: int) -> void:
	_update_meter(_health_bar, _health_label, "Health", current, max_value, "health")

func _on_materials_changed(current: int, max_value: int) -> void:
	_update_meter(_materials_bar, _materials_label, "Materials", current, max_value, "materials")

func _on_oxygen_changed(current: int, max_value: int) -> void:
	_update_meter(_oxygen_bar, _oxygen_label, "Oxygen", current, max_value, "oxygen")

func _on_threat_changed(current: int, max_value: int) -> void:
	var threat_meter = _get_threat_meter()
	if threat_meter and threat_meter.has_method("update_threat"):
		threat_meter.update_threat(current, max_value)

func _update_meter(bar: ProgressBar, value_label: Label, title: String, current: int, max_value: int, key: StringName) -> void:
	bar.max_value = float(max_value)
	bar.value = float(current)
	value_label.text = "%d / %d" % [current, max_value]
	var ratio: float = 0.0
	if max_value > 0:
		ratio = float(current) / float(max_value)
	var status := _status_for_ratio(key, ratio)
	value_label.add_theme_color_override("font_color", _color_for_status(status))
	bar.modulate = _color_for_status(status)

func _load_thresholds() -> void:
	if thresholds_resource and thresholds_resource.has_method("get_thresholds"):
		_threshold_map = thresholds_resource.get_thresholds()
	else:
		_threshold_map = {}
	var threat_meter = _get_threat_meter()
	if threat_meter and threat_meter.has_method("configure"):
		threat_meter.configure(_threshold_map)

func _status_for_ratio(key: StringName, ratio: float) -> StringName:
	var data: Dictionary = _threshold_map.get(key, {})
	var warning := float(data.get("warning", 0.5))
	var critical := float(data.get("critical", 0.25))
	if key == "threat":
		warning = float(data.get("warning", 0.6))
		critical = float(data.get("critical", 0.85))
	if key == "threat":
		if ratio >= critical:
			return "critical"
		if ratio >= warning:
			return "warning"
	else:
		if ratio <= critical:
			return "critical"
		if ratio <= warning:
			return "warning"
	return "stable"

func _color_for_status(status: StringName) -> Color:
	match status:
		"warning":
			return WARNING_COLOR
		"critical":
			return CRITICAL_COLOR
		_:
			return NORMAL_COLOR

func _get_resource_ledger():
	var tree := get_tree()
	if tree == null:
		return null
	var root := tree.get_root()
	if root and root.has_node("ResourceLedger"):
		return root.get_node("ResourceLedger")
	return null

func _get_threat_meter():
	if _threat_meter_node and _threat_meter_node.has_method("update_threat"):
		return _threat_meter_node
	return null
