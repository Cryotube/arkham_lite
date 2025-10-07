extends Node

var _pool_template: Array[Dictionary] = []

func ensure_pool(size: int) -> Array[Dictionary]:
    if _pool_template.is_empty() or _pool_template.size() != size:
        _pool_template.clear()
        for index in size:
            _pool_template.append({
                "value": 1,
                "locked": false,
                "exhausted": false
            })
    var clone: Array[Dictionary] = []
    for state in _pool_template:
        clone.append(state.duplicate(true))
    return clone

func reset() -> void:
    _pool_template.clear()
