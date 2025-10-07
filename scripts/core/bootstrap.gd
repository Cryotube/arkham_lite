extends Node
class_name Bootstrap

## Minimal bootstrap node so the autoloaded GameDirector can attach the run HUD.
func _ready() -> void:
    # Ensure the scene tree has a deterministic root for the GameDirector to parent into.
    set_process(false)
