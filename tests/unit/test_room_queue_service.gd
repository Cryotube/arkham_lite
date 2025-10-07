extends GutTest

var service_scene := load("res://scripts/services/room_queue_service.gd")
var room_service: Node = null

func before_each() -> void:
	room_service = service_scene.new()
	add_child_autofree(room_service)
	await wait_for_frames(1)

func after_each() -> void:
	room_service = null

func test_queue_initializes_with_three_rooms() -> void:
	var queue := room_service.get_queue() as Array
	assert_eq(queue.size(), 3, "Room queue should preload three entries.")
	for room in queue:
		assert_true(room.has("id"), "Room entries need an id.")
		assert_true(room.has("name"), "Room entries need a display name.")
		assert_true(room.has("clue_reward"), "Room should expose clue reward for balancing.")

func test_cycle_replaces_top_room() -> void:
	var initial_queue := room_service.get_queue() as Array
	var first_id: String = String(initial_queue[0].get("id", ""))
	room_service.cycle_top_room()
	var updated_queue := room_service.get_queue() as Array
	assert_eq(updated_queue.size(), 3)
	if updated_queue[0].get("id", "") == first_id:
		# deck reshuffle may return same card occasionally; ensure at least order changed.
		assert_true(updated_queue != initial_queue, "Cycling should change queue ordering even if the top id repeats.")
	else:
		assert_true(true, "Top room replaced.")

func wait_for_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame
