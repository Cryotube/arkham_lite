extends GutTest

var ledger: ResourceLedgerSingleton
var save_service: SaveServiceStub
var panel_scene: PackedScene

func before_each() -> void:
	ledger = _fetch_autoload("ResourceLedger")
	save_service = _fetch_autoload("SaveService")
	if save_service:
		save_service.clear_run_snapshot()
	if ledger:
		ledger.start_new_run(true)
	panel_scene = load("res://scenes/ui/resource_panel.tscn")

func after_each() -> void:
	ledger = null
	save_service = null
	panel_scene = null

func test_panel_reacts_to_ledger_updates() -> void:
	var panel := panel_scene.instantiate()
	add_child_autofree(panel)
	await wait_for_frames(1)
	assert_not_null(ledger)
	ledger.set_health(2)
	await wait_for_frames(1)
	var label: Label = panel.get_node("HealthMeter/HealthValueLabel")
	assert_eq(label.text, "2 / 8")
	ledger.set_threat(70)
	await wait_for_frames(1)
	var threat_label: Label = panel.get_node("ThreatMeter/ThreatStatusLabel")
	assert_true(threat_label.text.find("Warning") != -1)

func test_resource_panel_update_meets_budget() -> void:
	var panel := panel_scene.instantiate()
	add_child_autofree(panel)
	await wait_for_frames(1)
	var iterations := 96
	var start := Time.get_ticks_usec()
	for index in range(iterations):
		ledger.set_health(index % (ledger.max_health + 1))
		ledger.set_materials(index % (ledger.max_materials + 1))
		ledger.set_oxygen(index % (ledger.max_oxygen + 1))
		ledger.set_threat(min(ledger.max_threat, index * 2))
	var elapsed := Time.get_ticks_usec() - start
	var avg_update := float(elapsed) / float(iterations * 4)
	assert_lt(avg_update, 800.0, "Average resource update exceeded 0.8ms budget: %s μs" % avg_update)

func wait_for_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame

func _fetch_autoload(name: String) -> Variant:
	var root := get_tree().get_root()
	if root and root.has_node(name):
		return root.get_node(name)
	return null
