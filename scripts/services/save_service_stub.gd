extends Node
class_name SaveServiceStub

## Simple in-memory save service used until full persistence arrives.
## Stores a snapshot of the active run so autoloads can restore state
## after scene reloads or editor-driven resets.

signal snapshot_updated(snapshot: Dictionary)

var _run_snapshot: Dictionary = {}

func store_run_snapshot(snapshot: Dictionary) -> void:
	_run_snapshot = snapshot.duplicate(true)
	snapshot_updated.emit(_run_snapshot)

func get_run_snapshot() -> Dictionary:
	return _run_snapshot.duplicate(true)

func has_run_snapshot() -> bool:
	return not _run_snapshot.is_empty()

func clear_run_snapshot() -> void:
	_run_snapshot.clear()
