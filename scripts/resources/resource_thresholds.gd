extends Resource
class_name ResourceThresholds

@export var health_warning: float = 0.5
@export var health_critical: float = 0.25

@export var materials_warning: float = 0.35
@export var materials_critical: float = 0.15

@export var oxygen_warning: float = 0.5
@export var oxygen_critical: float = 0.25

@export var threat_warning: float = 0.6
@export var threat_critical: float = 0.8

func get_thresholds() -> Dictionary:
	return {
		"health": {
			"warning": health_warning,
			"critical": health_critical,
		},
		"materials": {
			"warning": materials_warning,
			"critical": materials_critical,
		},
		"oxygen": {
			"warning": oxygen_warning,
			"critical": oxygen_critical,
		},
		"threat": {
			"warning": threat_warning,
			"critical": threat_critical,
		},
	}
