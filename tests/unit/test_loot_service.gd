extends GutTest

var loot_scene := load("res://scripts/services/loot_service.gd")
var loot_service: Node = null

func before_each() -> void:
	loot_service = loot_scene.new()
	add_child_autofree(loot_service)
	await wait_for_frames(1)

func after_each() -> void:
	loot_service = null

func test_roll_loot_returns_candidate() -> void:
	var room := {"id": "test_room", "tags": ["cache"]}
	var loot: Dictionary = loot_service.roll_loot_for_room(room)
	assert_true(loot.has("id"))
	assert_true(loot.get("id") != "")

func wait_for_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame
