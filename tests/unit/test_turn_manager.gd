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
    await _await_roll()
    var results := turn_manager.get_current_results()
    assert_eq(results.size(), DiceSubsystem.DICE_POOL_SIZE, "Dice roll should return one value per die")
    for value in results:
        assert_gt(value, 0, "Each die should have a positive face value")

func test_lock_and_commit_exhausts_selected_die() -> void:
    turn_manager.request_roll()
    await _await_roll()
    turn_manager.toggle_lock(0)
    turn_manager.commit_dice()
    var exhausted := turn_manager.get_exhausted_indices()
    assert_true(exhausted.has(0), "Locked die should move to exhaust tray after commit")
    assert_false(dice_subsystem.is_die_locked(0), "Die should unlock once exhausted")
    assert_eq(turn_manager.get_state(), TurnManager.TurnState.ROLL_PREP, "Turn should advance to next roll phase")

func test_refresh_returns_exhausted_dice_on_next_roll() -> void:
    turn_manager.request_roll()
    await _await_roll()
    turn_manager.toggle_lock(0)
    turn_manager.commit_dice()
    turn_manager.request_roll()
    await _await_roll()
    var exhausted := turn_manager.get_exhausted_indices()
    assert_eq(exhausted.size(), 0, "Exhausted dice should return for the next roll")
    var results := turn_manager.get_current_results()
    assert_eq(results.size(), DiceSubsystem.DICE_POOL_SIZE, "Dice count remains stable after refresh")

func test_hold_prevents_reroll_until_released() -> void:
    turn_manager.request_roll()
    await _await_roll()
    var initial_results := turn_manager.get_current_results()
    var initial_value := initial_results[0]
    turn_manager.toggle_hold(0)
    turn_manager.request_roll()
    await _await_roll()
    var post_hold_results := turn_manager.get_current_results()
    assert_eq(post_hold_results[0], initial_value, "Held die should keep value between rolls")
    turn_manager.toggle_hold(0)
    turn_manager.request_roll()
    await _await_roll()
    var released_results := turn_manager.get_current_results()
    assert_ne(released_results[0], initial_value, "Releasing hold allows die to reroll")

func test_roll_cycle_stays_within_reasonable_time_budget() -> void:
    var samples := 10
    var max_duration_ms := 0.0
    for _i in samples:
        var start := Time.get_ticks_msec()
        turn_manager.request_roll()
        await _await_roll()
        turn_manager.commit_dice()
        var duration := float(Time.get_ticks_msec() - start)
        if duration > max_duration_ms:
            max_duration_ms = duration
    assert_lt(max_duration_ms, 650.0, "Physics-driven roll should settle within 650ms")

func _await_roll() -> void:
    await dice_subsystem.roll_resolved
