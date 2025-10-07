extends Resource
class_name EquipmentModuleResource

@export var module_id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var shape_mask: Array[Vector2i] = [Vector2i.ZERO]
@export var burden: int = 1
@export var dice_costs: Array[StringName] = []
@export var passive_slots: Array[StringName] = []
@export var allow_rotation: bool = true

func get_mask() -> Array[Vector2i]:
	var mask: Array[Vector2i] = []
	for cell in shape_mask:
		mask.append(Vector2i(cell))
	return mask

