extends Resource
class_name EquipmentMatrixConfig

@export var grid_width: int = 6
@export var grid_height: int = 5
@export var base_burden: int = 0
@export var strained_threshold: int = 8
@export var critical_threshold: int = 12
@export var slot_bindings: Dictionary = {}
@export var rotation_rules: Dictionary = {}
@export var cell_labels: Array[StringName] = []

func get_slot_tags(module_id: StringName) -> Array[StringName]:
	var raw: Array = slot_bindings.get(module_id, []) as Array
	var tags: Array[StringName] = []
	for entry in raw:
		tags.append(StringName(entry))
	return tags

func can_rotate(module_id: StringName) -> bool:
	return bool(rotation_rules.get(module_id, true))
