extends Node

signal queue_updated(queue: Array[Dictionary])
signal room_entered(room: Dictionary)
signal room_cycled(room: Dictionary)

const QUEUE_SIZE: int = 3

const ROOM_DECK: Array[Dictionary] = [
	{"id": "medbay_antechamber", "name": "Medbay Antechamber", "tags": ["sanctuary", "hazard_low"], "threat": "lurking_stalker", "summary": "Salvage oxygen tanks while a stalker circles the vents.", "clue_reward": 0, "materials_reward": 2, "oxygen_cost": 1},
	{"id": "reactor_cooling", "name": "Reactor Cooling Hub", "tags": ["hazard_high", "materials"], "threat": "thermal_overload", "summary": "Stabilize leaking coolant before heat signatures spike.", "clue_reward": 1, "materials_reward": 3, "oxygen_cost": 2},
	{"id": "cargo_hall", "name": "Collapsed Cargo Hall", "tags": ["cache", "threat_spawn"], "threat": "nesting_chitter", "summary": "Pick through wreckage for parts while larvae hatch nearby.", "clue_reward": 0, "materials_reward": 3, "oxygen_cost": 1},
	{"id": "observation_dome", "name": "Observation Dome", "tags": ["clue", "anomaly"], "threat": "whispering_signal", "summary": "Decode spectral readings to triangulate the escape vector.", "clue_reward": 2, "materials_reward": 1, "oxygen_cost": 1},
	{"id": "hydroponics_sprawl", "name": "Hydroponics Sprawl", "tags": ["sanctuary", "resource_gain"], "threat": "spore_bloom", "summary": "Harvest bio-gel while mutagenic spores thicken the air.", "clue_reward": 0, "materials_reward": 2, "oxygen_cost": 0},
	{"id": "hangar_spindle", "name": "Hangar Spindle", "tags": ["escape", "materials"], "threat": "siren_drones", "summary": "Scavenge power couplings under the gaze of corrupted drones.", "clue_reward": 2, "materials_reward": 2, "oxygen_cost": 2},
	{"id": "drift_vault", "name": "Drift Vault", "tags": ["cache", "clue"], "threat": "gravity_ghost", "summary": "Navigate zero-g vault to secure encoded data caches.", "clue_reward": 1, "materials_reward": 2, "oxygen_cost": 1},
	{"id": "waste_processing", "name": "Waste Processing Sump", "tags": ["hazard_low", "materials"], "threat": "acidic_sludge", "summary": "Extract salvage amid corrosive runoff and compromised filters.", "clue_reward": 0, "materials_reward": 3, "oxygen_cost": 1},
	{"id": "signal_array", "name": "Signal Array Nexus", "tags": ["clue", "anomaly"], "threat": "resonant_feedback", "summary": "Calibrate antennae to triangulate exit route before resonance spikes.", "clue_reward": 2, "materials_reward": 0, "oxygen_cost": 2},
	{"id": "crew_quarters", "name": "Abandoned Crew Quarters", "tags": ["sanctuary", "cache"], "threat": "phantom_echo", "summary": "Search personal lockers while echoing memories destabilize resolve.", "clue_reward": 1, "materials_reward": 1, "oxygen_cost": 0},
	{"id": "hull_breach", "name": "Exterior Hull Breach", "tags": ["hazard_high", "materials"], "threat": "vacuum_surge", "summary": "Brace against decompression to weld plates over hull fissure.", "clue_reward": 0, "materials_reward": 3, "oxygen_cost": 2},
	{"id": "engine_spire", "name": "Engine Spire", "tags": ["escape", "hazard_high"], "threat": "overclocked_core", "summary": "Tame the screaming core before it surges and melts the deck plating.", "clue_reward": 2, "materials_reward": 3, "oxygen_cost": 3},
	{"id": "maintenance_tunnels", "name": "Maintenance Tunnels", "tags": ["hazard_low", "clue"], "threat": "tracking_nanite_swarm", "summary": "Lay decoys and jam signals to shake a rogue nanite swarm.", "clue_reward": 1, "materials_reward": 1, "oxygen_cost": 1},
	{"id": "observation_quarantine", "name": "Observation Quarantine", "tags": ["hazard_med", "resource_gain"], "threat": "containment_failure", "summary": "Divert power to hold back mutated specimens while scavenging supplies.", "clue_reward": 1, "materials_reward": 2, "oxygen_cost": 1},
	{"id": "cryonics_bay", "name": "Cryonics Bay", "tags": ["sanctuary", "resource_gain"], "threat": "frostbite_specter", "summary": "Thaw cryo pods carefully to secure med-gel caches under time pressure.", "clue_reward": 0, "materials_reward": 2, "oxygen_cost": 1},
	{"id": "biodome_ruins", "name": "Biodome Ruins", "tags": ["anomaly", "clue"], "threat": "feral_growth", "summary": "Decode growth patterns while carnivorous flora shadows the trail.", "clue_reward": 2, "materials_reward": 1, "oxygen_cost": 1},
	{"id": "communications_core", "name": "Communications Core", "tags": ["clue", "threat_spawn"], "threat": "signal_intruder", "summary": "Scrub corrupted protocols to reclaim long-range contact.", "clue_reward": 2, "materials_reward": 1, "oxygen_cost": 2},
	{"id": "life_support_hub", "name": "Life Support Hub", "tags": ["resource_gain", "sanctuary"], "threat": "oxygen_syphon", "summary": "Divert spare filters while a siphon threat drains reserves.", "clue_reward": 0, "materials_reward": 2, "oxygen_cost": 0},
	{"id": "gravity_lab", "name": "Gravity Research Lab", "tags": ["anomaly", "hazard_med"], "threat": "quantum_maw", "summary": "Stabilize fields to recover gravity cores before collapse.", "clue_reward": 1, "materials_reward": 2, "oxygen_cost": 2},
	{"id": "archives", "name": "Data Archives", "tags": ["clue", "cache"], "threat": "data_wraith", "summary": "Decrypt logs to uncover escape coordinates guarded by a wraith.", "clue_reward": 2, "materials_reward": 1, "oxygen_cost": 1},
	{"id": "docking_ring", "name": "Docking Ring", "tags": ["escape", "hazard_med"], "threat": "boarding_seraphs", "summary": "Secure the docking umbilicals while spectral boarders push through.", "clue_reward": 2, "materials_reward": 2, "oxygen_cost": 2},
	{"id": "armory_cache", "name": "Armory Cache", "tags": ["materials", "cache"], "threat": "supply_wraith", "summary": "Bypass locked containment to salvage armaments before the wraith consumes inventory.", "clue_reward": 0, "materials_reward": 4, "oxygen_cost": 1},
	{"id": "sensor_blindspot", "name": "Sensor Blindspot", "tags": ["anomaly", "hazard_low"], "threat": "latent_voidling", "summary": "Map the blindspot to re-align sensors and flush out void anomalies.", "clue_reward": 1, "materials_reward": 0, "oxygen_cost": 1},
	{"id": "worship_chamber", "name": "Derelict Worship Chamber", "tags": ["lore", "clue"], "threat": "psionic_echo", "summary": "Piece together cult rituals to learn how they navigated the sector.", "clue_reward": 2, "materials_reward": 0, "oxygen_cost": 1},
	{"id": "transport_spine", "name": "Transport Spine", "tags": ["hazard_med", "materials"], "threat": "tram_cannibal", "summary": "Reactivate tram power without giving away position to marauders.", "clue_reward": 0, "materials_reward": 3, "oxygen_cost": 1},
	{"id": "slipspace_observatory", "name": "Slipspace Observatory", "tags": ["clue", "anomaly"], "threat": "rift_apparition", "summary": "Chart slipspace currents while apparitions claw through reality.", "clue_reward": 3, "materials_reward": 0, "oxygen_cost": 2},
	{"id": "maintenance_bay", "name": "Maintenance Bay 12", "tags": ["cache", "resource_gain"], "threat": "rogue_loader", "summary": "Disable an out-of-control loader to salvage fuel cells.", "clue_reward": 0, "materials_reward": 3, "oxygen_cost": 1},
	{"id": "bioscan_corridor", "name": "Bioscan Corridor", "tags": ["hazard_low", "clue"], "threat": "sporelock", "summary": "Bypass bioscan locks while spores threaten to seal doors permanently.", "clue_reward": 1, "materials_reward": 1, "oxygen_cost": 1},
	{"id": "refinery_overlook", "name": "Refinery Overlook", "tags": ["materials", "hazard_med"], "threat": "pressure_djinn", "summary": "Relieve pressure valves to harvest rare alloys before the djinn breaches containment.", "clue_reward": 0, "materials_reward": 4, "oxygen_cost": 2},
	{"id": "echoing_drift", "name": "Echoing Drift", "tags": ["anomaly", "lore"], "threat": "temporal_murmur", "summary": "Listen to time-warped transmissions for secrets to the sector.", "clue_reward": 1, "materials_reward": 0, "oxygen_cost": 1},
	{"id": "arboretum_heart", "name": "Arboretum Heart", "tags": ["resource_gain", "anomaly"], "threat": "sentient_vines", "summary": "Appease sentient vines to harvest bio-energy safely.", "clue_reward": 0, "materials_reward": 2, "oxygen_cost": 1}
]

var _default_deck: Array[Dictionary] = []
var _deck: Array[Dictionary] = []
var _discard: Array[Dictionary] = []
var _queue: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_initialize_default_deck()
	reset(true)

func reset(force_shuffle: bool = false) -> void:
	if force_shuffle or _deck.is_empty():
		_reset_deck_from_default()
	_queue.clear()
	for _i in QUEUE_SIZE:
		_queue.append(_draw_room())
	queue_updated.emit(_queue_snapshot())

func get_queue() -> Array[Dictionary]:
	return _queue_snapshot()

func peek_next_room() -> Dictionary:
	if _queue.is_empty():
		return {}
	return _queue[0].duplicate(true)

func draw_next_room() -> Dictionary:
	if _queue.is_empty():
		return {}
	var room: Dictionary = _queue[0]
	_queue.remove_at(0)
	_queue.append(_draw_room())
	queue_updated.emit(_queue_snapshot())
	var emitted: Dictionary = room.duplicate(true)
	room_entered.emit(emitted)
	return emitted

func cycle_top_room() -> Dictionary:
	if _queue.is_empty():
		return {}
	var room: Dictionary = _queue[0]
	_queue.remove_at(0)
	_queue.append(_draw_room())
	queue_updated.emit(_queue_snapshot())
	var emitted: Dictionary = room.duplicate(true)
	room_cycled.emit(emitted)
	return emitted

func discard_room(room_id: String) -> void:
	for index in _queue.size():
		var room: Dictionary = _queue[index]
		if room.get("id", "") == room_id:
			_queue.remove_at(index)
			queue_updated.emit(_queue_snapshot())
			return

func _draw_room() -> Dictionary:
	if _deck.is_empty():
		_reset_deck_from_default()
	if _deck.is_empty():
		return {}
	var index: int = _rng.randi_range(0, _deck.size() - 1)
	var room: Dictionary = _deck[index]
	_deck.remove_at(index)
	_discard.append(room)
	return room.duplicate(true)

func _reset_deck_from_default() -> void:
	if _default_deck.is_empty():
		_initialize_default_deck()
	_deck = _default_deck.duplicate(true)
	_discard.clear()

func _initialize_default_deck() -> void:
	if not _default_deck.is_empty():
		return
	_default_deck = ROOM_DECK.duplicate(true)

func _queue_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for room in _queue:
		snapshot.append(room.duplicate(true))
	return snapshot
