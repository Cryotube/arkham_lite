extends GutTest

const RUN_HUD_SCENE := preload("res://scenes/ui/run_hud.tscn")
const TurnManager := preload("res://scripts/systems/turn_manager.gd")

var ledger: ResourceLedgerSingleton

func before_each() -> void:
	ledger = _fetch_autoload("ResourceLedger")
	if ledger:
		ledger.start_new_run(true)

func after_each() -> void:
	ledger = null

func test_turn_cycle_updates_ledger_and_hud_display() -> void:
	var hud: RunHudController = RUN_HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await wait_for_frames(1)
	var dice_subsystem: Node = hud.get_dice_subsystem()
	assert_not_null(dice_subsystem)
	var turn_manager: TurnManager = TurnManager.new()
	add_child_autofree(turn_manager)
	turn_manager.initialize(dice_subsystem, hud)
	hud.set_turn_manager(turn_manager)
	turn_manager.start_new_run()
	await wait_for_frames(1)
	turn_manager.request_roll()
	await wait_for_frames(2)
	var results := turn_manager.get_current_results()
	assert_eq(results.size(), 3)
	turn_manager.commit_dice()
	await wait_for_frames(1)
	assert_gt(ledger.get_threat(), 0)
	var token_label: Label = hud.get_node("MainLayout/DiceDock/DiceViewportFrame/ViewportOverlay/DiceOverlay/OverlayVBox/AvailableDiceRow/DieToken0/VBox/ValueLabel")
	assert_eq(token_label.text.to_int(), results[0])

func wait_for_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame

func _fetch_autoload(name: String) -> Variant:
	var root := get_tree().get_root()
	if root:
		var path := NodePath(name)
		if root.has_node(path):
			return root.get_node(path)
	return null
