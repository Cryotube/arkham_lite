extends GutTest

var ledger: ResourceLedgerSingleton
var save_service: SaveServiceStub

func before_each() -> void:
	save_service = SaveServiceStub.new()
	ledger = ResourceLedgerSingleton.new()
	ledger.set_save_service(save_service)
	add_child_autofree(save_service)
	add_child_autofree(ledger)
	ledger.reset()

func after_each() -> void:
	ledger = null
	save_service = null

func test_setters_clamp_and_emit() -> void:
	var signal_count := {"value": 0}
	ledger.health_changed.connect(func(current: int, _max: int) -> void:
		signal_count.value += 1
		assert_gte(current, 0)
	)
	ledger.set_health(-5)
	assert_eq(ledger.get_health(), 0)
	assert_eq(signal_count.value, 1)

func test_snapshot_persistence_roundtrip() -> void:
	ledger.adjust_materials(-4)
	ledger.adjust_oxygen(-2)
	var snapshot := save_service.get_run_snapshot()
	assert_not_null(snapshot)
	assert_eq(snapshot.materials, ledger.get_materials())
	assert_eq(snapshot.oxygen, ledger.get_oxygen())
	var rehydrated := ResourceLedgerSingleton.new()
	rehydrated.set_save_service(save_service)
	add_child_autofree(rehydrated)
	rehydrated._ready()
	assert_eq(rehydrated.get_materials(), ledger.get_materials())
	assert_eq(rehydrated.get_oxygen(), ledger.get_oxygen())

func test_threshold_cross_emits() -> void:
	var levels: Array[StringName] = []
	ledger.threat_threshold_crossed.connect(func(level: StringName) -> void:
		levels.append(level)
	)
	ledger.set_threat(80)
	ledger.set_threat(95)
	assert_true(levels.has("warning"))
	assert_true(levels.has("critical"))
