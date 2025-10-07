extends Resource
class_name DiceFaceSet

@export var faces: Array[int] = [1, 2, 3, 4, 5, 6]

func get_faces() -> Array[int]:
    return faces.duplicate()
