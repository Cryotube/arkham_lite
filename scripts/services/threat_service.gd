extends Node

signal threats_updated(active_threats: Array[Dictionary])
signal threat_latched(threat: Dictionary)
signal threat_cleared(threat: Dictionary)
signal threat_attack_resolved(threat_id: String, attack: Dictionary)

const THREAT_TEMPLATES: Dictionary = {
	"lurking_stalker": {
		"id": "lurking_stalker",
		"name": "Lurking Stalker",
		"timer": 2,
		"severity": "moderate",
		"attack_pattern": {"damage": 1, "threat_delta": 1, "cooldown": 2, "statuses": [{"id": "bleed", "label": "Bleed", "duration": 2}]},
		"status_effects": []
	},
	"thermal_overload": {
		"id": "thermal_overload",
		"name": "Thermal Overload",
		"timer": 1,
		"severity": "critical",
		"attack_pattern": {"damage": 2, "threat_delta": 2, "cooldown": 3, "statuses": [{"id": "heat_burn", "label": "Burn", "duration": 2}]},
		"status_effects": []
	},
	"nesting_chitter": {
		"id": "nesting_chitter",
		"name": "Nesting Chitter",
		"timer": 3,
		"severity": "moderate",
		"attack_pattern": {"damage": 1, "threat_delta": 1, "cooldown": 3, "statuses": [{"id": "dice_lock", "label": "Jam", "duration": 1}]},
		"status_effects": []
	},
	"whispering_signal": {
		"id": "whispering_signal",
		"name": "Whispering Signal",
		"timer": 2,
		"severity": "high",
		"attack_pattern": {"damage": 0, "threat_delta": 2, "cooldown": 2, "statuses": [{"id": "mind_fog", "label": "Mind Fog", "duration": 2}]},
		"status_effects": []
	},
	"spore_bloom": {
		"id": "spore_bloom",
		"name": "Spore Bloom",
		"timer": 3,
		"severity": "moderate",
		"attack_pattern": {"damage": 1, "threat_delta": 1, "cooldown": 3, "statuses": [{"id": "oxygen_leak", "label": "Oxygen Leak", "duration": 2}]},
		"status_effects": []
	},
	"siren_drones": {
		"id": "siren_drones",
		"name": "Siren Drones",
		"timer": 2,
		"severity": "high",
		"attack_pattern": {"damage": 1, "threat_delta": 2, "cooldown": 2, "statuses": [{"id": "sensor_jam", "label": "Sensor Jam", "duration": 1}]},
		"status_effects": []
	},
	"signal_intruder": {
		"id": "signal_intruder",
		"name": "Signal Intruder",
		"timer": 2,
		"severity": "moderate",
		"attack_pattern": {"damage": 1, "threat_delta": 1, "cooldown": 2, "statuses": [{"id": "stagger", "label": "Stagger", "duration": 1}]},
		"status_effects": []
	}
}

var _active_threats: Array[Dictionary] = []

func reset() -> void:
	_active_threats.clear()
	_emit_update()

func latch_threat(threat_info: Dictionary) -> void:
	var threat := threat_info.duplicate(true)
	if not threat.has("id"):
		threat["id"] = "threat_%d" % _active_threats.size()
	if not threat.has("name"):
		threat["name"] = threat.get("id")
	if not threat.has("timer"):
		threat["timer"] = 3
	if not threat.has("severity"):
		threat["severity"] = "moderate"
	if not threat.has("status_effects"):
		threat["status_effects"] = []
	if not threat.has("attack_pattern"):
		threat["attack_pattern"] = {
			"type": "standard",
			"damage": 1,
			"threat_delta": 1,
			"statuses": []
		}
	_active_threats.append(threat)
	threat_latched.emit(threat.duplicate(true))
	_emit_update()

func resolve_threat(threat_id: String) -> void:
	for index in _active_threats.size():
		var threat := _active_threats[index]
		if threat.get("id", "") == threat_id:
			_active_threats.remove_at(index)
			threat_cleared.emit(threat.duplicate(true))
			_emit_update()
			return

func tick_timers() -> void:
	for threat in _active_threats:
		var timer := int(threat.get("timer", 0))
		if timer > 0:
			threat["timer"] = timer - 1
		else:
			_execute_attack(threat)
	_emit_update()

func apply_status(threat_id: String, status: Dictionary) -> void:
	for threat in _active_threats:
		if threat.get("id", "") == threat_id:
			var status_effects: Array = threat.get("status_effects", []) as Array
			status_effects.append(status.duplicate(true))
			threat["status_effects"] = status_effects
			_emit_update()
			return

func clear_status(threat_id: String, status_id: String) -> void:
	for threat in _active_threats:
		if threat.get("id", "") == threat_id:
			var status_effects: Array = threat.get("status_effects", []) as Array
			status_effects = status_effects.filter(func(effect: Dictionary) -> bool:
				return effect.get("id", "") != status_id
			)
			threat["status_effects"] = status_effects
			_emit_update()
			return

func get_threats() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for threat in _active_threats:
		copy.append(threat.duplicate(true))
	return copy

func _emit_update() -> void:
	threats_updated.emit(get_threats())

func _execute_attack(threat: Dictionary) -> void:
	var pattern: Dictionary = threat.get("attack_pattern", {}) as Dictionary
	var cooldown: int = int(pattern.get("cooldown", 1))
	threat["timer"] = max(1, cooldown)
	threat["last_attack"] = {
		"damage": pattern.get("damage", 1),
		"threat_delta": pattern.get("threat_delta", 1),
		"statuses": pattern.get("statuses", [])
	}
	threat_attack_resolved.emit(String(threat.get("id", "")), (threat["last_attack"] as Dictionary).duplicate(true))

func build_from_template(threat_id: String) -> Dictionary:
	var template_variant: Variant = THREAT_TEMPLATES.get(threat_id, null)
	if template_variant == null:
		return {}
	var template: Dictionary = template_variant as Dictionary
	return template.duplicate(true)
