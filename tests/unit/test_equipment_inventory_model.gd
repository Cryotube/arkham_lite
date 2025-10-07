extends GutTest

var inventory_scene: GDScript = load("res://scripts/services/equipment_inventory_model.gd") as GDScript
var inventory: Node = null

func before_each() -> void:
	inventory = inventory_scene.new()
	add_child_autofree(inventory)
	await wait_for_frames(1)

func after_each() -> void:
	inventory = null

func test_add_loot_moves_item_to_carry() -> void:
	inventory.add_loot(&"ion_blaster")
	var carry: Array = inventory.get_carry_items()
	assert_eq(carry.size(), 1, "Carry should contain one entry.")
	assert_eq(carry[0].get("id"), "ion_blaster")
	assert_eq(int(carry[0].get("burden", -1)), 2)

func test_place_item_marks_grid_and_updates_burden() -> void:
	inventory.add_loot(&"ion_blaster")
	assert_true(inventory.can_place(&"ion_blaster", Vector2i(0, 0), 0))
	assert_true(inventory.place_item(&"ion_blaster", Vector2i(0, 0), 0))
	await wait_for_frames(1)
	var grid: Array = inventory.get_grid()
	assert_eq(grid[0][0], "ion_blaster")
	assert_eq(grid[0][1], "ion_blaster")
	assert_eq(inventory.get_total_burden(), 2)
	assert_eq(inventory.get_burden_state(), &"safe")

func test_evaluate_placement_detects_conflicts() -> void:
	inventory.add_loot(&"ion_blaster")
	inventory.place_item(&"ion_blaster", Vector2i(0, 0), 0)
	inventory.add_loot(&"seeker_array")
	var result: Dictionary = inventory.evaluate_placement(&"seeker_array", Vector2i(0, 0), 0)
	assert_false(result.get("valid", true), "Placement should be invalid due to overlap.")
	var conflicts: Array = result.get("conflicts", []) as Array
	assert_gt(conflicts.size(), 0, "Conflicts should list overlapping cells.")

func test_rotation_normalizes_shape() -> void:
	inventory.add_loot(&"seeker_array")
	var can_place_rotated: bool = inventory.can_place(&"seeker_array", Vector2i(0, 0), 90)
	assert_true(can_place_rotated, "Vertical piece should fit when rotated.")

func test_slot_bindings_emit_for_module() -> void:
	var observed_slots: Dictionary = {}
	inventory.dice_binding_updated.connect(func(slot: StringName, module_id: StringName) -> void:
		observed_slots[slot] = module_id
	)
	inventory.add_loot(&"ion_blaster")
	inventory.place_item(&"ion_blaster", Vector2i(0, 0), 0)
	assert_true(observed_slots.has(&"die_strength"), "Strength slot should be bound when Ion Blaster equipped.")

func wait_for_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame
