extends GutTest

var inventory_scene := load("res://scripts/services/equipment_inventory_model.gd")
var inventory: Node = null

func before_each() -> void:
	inventory = inventory_scene.new()
	add_child_autofree(inventory)
	await wait_for_frames(1)

func after_each() -> void:
	inventory = null

func test_add_loot_moves_item_to_carry() -> void:
	inventory.add_loot("ion_blaster")
	var carry: Array = inventory.get_carry_items()
	assert_eq(carry.size(), 1)
	assert_eq(carry[0].get("id"), "ion_blaster")

func test_place_item_marks_grid() -> void:
	inventory.add_loot("ion_blaster")
	var origin := Vector2i(0, 0)
	var can_place: bool = inventory.can_place("ion_blaster", origin, 0)
	assert_true(can_place)
	var placed: bool = inventory.place_item("ion_blaster", origin, 0)
	assert_true(placed)
	var grid: Array = inventory.get_grid()
	assert_eq(grid[0][0], "ion_blaster")
	assert_eq(grid[0][1], "ion_blaster")

func wait_for_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame
