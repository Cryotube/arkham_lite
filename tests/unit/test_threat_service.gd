extends GutTest

var service_scene := load("res://scripts/services/threat_service.gd")
var threat_service: Node = null

func before_each() -> void:
	threat_service = service_scene.new()
	add_child_autofree(threat_service)
	await wait_for_frames(1)

func after_each() -> void:
	threat_service = null

func test_latch_and_resolve_threat() -> void:
	var emitted := []
	threat_service.threat_latched.connect(func(threat: Dictionary) -> void:
		emitted.append(threat)
	)
	threat_service.latch_threat({"id": "test", "name": "Test Threat", "timer": 2})
	assert_eq(threat_service.get_threats().size(), 1)
	assert_eq(emitted.size(), 1)
	threat_service.resolve_threat("test")
	assert_eq(threat_service.get_threats().size(), 0)

func test_tick_timers_reduces_countdown() -> void:
	threat_service.latch_threat({"id": "tick", "timer": 3})
	threat_service.tick_timers()
	var threats := threat_service.get_threats() as Array
	assert_eq(threats[0].get("timer"), 2)

func test_attack_fires_when_timer_expires() -> void:
	var attacks: Array = []
	threat_service.threat_attack_resolved.connect(func(threat_id: String, attack: Dictionary) -> void:
		attacks.append({"id": threat_id, "attack": attack})
	)
	threat_service.latch_threat({"id": "thermal_overload", "timer": 0, "attack_pattern": {"damage": 2, "threat_delta": 2, "cooldown": 3, "statuses": []}})
	threat_service.tick_timers()
	var threats := threat_service.get_threats() as Array
	assert_eq(threats[0].get("timer"), 3)
	assert_eq(attacks.size(), 1)
	assert_eq(attacks[0].attack.get("damage"), 2)

func test_status_application_tracks_effects() -> void:
	threat_service.latch_threat({"id": "status_demo"})
	threat_service.apply_status("status_demo", {"id": "bleed", "label": "Bleed", "duration": 2})
	var threats := threat_service.get_threats() as Array
	var effects := threats[0].get("status_effects", []) as Array
	assert_eq(effects.size(), 1)
	threat_service.clear_status("status_demo", "bleed")
	threats = threat_service.get_threats() as Array
	effects = threats[0].get("status_effects", []) as Array
	assert_eq(effects.size(), 0)

func wait_for_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame
