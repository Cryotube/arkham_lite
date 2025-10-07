extends GutTest

var dice_subsystem: DiceSubsystem
var turn_manager: TurnManager

func before_each() -> void:
    dice_subsystem = DiceSubsystem.new()
    add_child_autofree(dice_subsystem)
    turn_manager = TurnManager.new()
    turn_manager.initialize(dice_subsystem, null)
    turn_manager.start_turn()

func after_each() -> void:
    if is_instance_valid(turn_manager):
        turn_manager.free()
    dice_subsystem = null
    turn_manager = null

func test_request_roll_generates_three_results() -> void:
    turn_manager.request_roll()
    var results := turn_manager.get_current_results()
    assert_eq(results.size(), DiceSubsystem.DICE_POOL_SIZE, "Dice roll should return one value per die")
    for value in results:
        assert_gt(value, 0, "Each die should have a positive face value")

func test_lock_and_commit_exhausts_selected_die() -> void:
    turn_manager.request_roll()
    turn_manager.toggle_lock(0)
    turn_manager.commit_dice()
    var exhausted := turn_manager.get_exhausted_indices()
    assert_true(exhausted.has(0), "Locked die should move to exhaust tray after commit")
    assert_false(dice_subsystem.is_die_locked(0), "Die should unlock once exhausted")
    assert_eq(turn_manager.get_state(), TurnManager.TurnState.ROLL_PREP, "Turn should advance to next roll phase")

func test_refresh_returns_exhausted_dice_on_next_roll() -> void:
    turn_manager.request_roll()
    turn_manager.toggle_lock(0)
    turn_manager.commit_dice()
    turn_manager.request_roll()
    var exhausted := turn_manager.get_exhausted_indices()
    assert_eq(exhausted.size(), 0, "Exhausted dice should return for the next roll")
    var results := turn_manager.get_current_results()
    assert_eq(results.size(), DiceSubsystem.DICE_POOL_SIZE, "Dice count remains stable after refresh")

func test_roll_cycle_stays_within_reasonable_time_budget() -> void:
    var frames := 120
    var start := Time.get_ticks_msec()
    for _i in frames:
        turn_manager.request_roll()
        turn_manager.commit_dice()
    var elapsed := Time.get_ticks_msec() - start
    var average_frame_time := float(elapsed) / float(frames)
    assert_lt(average_frame_time, 16.67 * 2.0, "Average simulated roll loop should stay under 33ms budget")
