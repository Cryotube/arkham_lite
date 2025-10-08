extends Node
class_name SaveServiceStub

const ResourceSnapshot = preload("res://scripts/autoload/resource_snapshot.gd")

## Simple in-memory save service used until full persistence arrives.
## Stores a snapshot of the active run so autoloads can restore state
## after scene reloads or editor-driven resets.

signal snapshot_updated(snapshot: ResourceSnapshot)

var _run_snapshot: ResourceSnapshot = null

func store_run_snapshot(snapshot: ResourceSnapshot) -> void:
	if snapshot == null:
		_run_snapshot = null
		return
	_run_snapshot = _copy_snapshot(snapshot)
	snapshot_updated.emit(_copy_snapshot(_run_snapshot))

func get_run_snapshot() -> ResourceSnapshot:
	if _run_snapshot == null:
		return null
	return _copy_snapshot(_run_snapshot)

func has_run_snapshot() -> bool:
	return _run_snapshot != null

func clear_run_snapshot() -> void:
	_run_snapshot = null

func _copy_snapshot(snapshot: ResourceSnapshot) -> ResourceSnapshot:
	return ResourceSnapshot.new(
		snapshot.health,
		snapshot.max_health,
		snapshot.materials,
		snapshot.max_materials,
		snapshot.oxygen,
		snapshot.max_oxygen,
		snapshot.threat,
		snapshot.max_threat,
		snapshot.threshold_states.duplicate(true)
	)
