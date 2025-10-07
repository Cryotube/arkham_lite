#!/usr/bin/env python3
"""Utility to regenerate all Bermuda Sector story drafts."""
from pathlib import Path

STORY_CONTENT = {
    "docs/stories/epic-1-crash-survivor-foundation/1.1-godot-project-spine-and-dice-loop-skeleton.md": """# Godot Story: Godot Project Spine & Dice Loop Skeleton

**Epic:** Crash Survivor Foundation  
**Story ID:** 1.1  
**Priority:** High  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Stand up the initial Godot 4.5 project scene that boots into a playable run HUD with a working dice roll/lock/exhaust loop, wiring the `TurnManager` autoload to the `DiceSubsystem` and HUD placeholders. Establish the SubViewport-based 3D dice tray, action inputs, and autoload initialization so later systems can build on a stable spine. References: core loop requirements (docs/game-prd.md:40-95) and architecture systems (docs/architecture.md:40-226).

**Godot Implementation:** Using `GameDirector` root scene with `TurnManager` and `DiceSubsystem` Nodes (GDScript) for deterministic control of the dice cycle  
**Performance Impact:** Expected neutral once object pooling and processing gates applied; must profile SubViewport physics to keep frame budget within 16.67 ms

## Acceptance Criteria
### Functional Requirements
- [ ] Game boots to Run HUD showing Strength/Intellect/Agility dice ready to roll
- [ ] Roll → spend/lock → exhaust → refresh loop functions with touch input
- [ ] Exhausted dice visually transfer to a holding tray and return on next roll
- [ ] Roll/confirm/lock actions emit telemetry stub events for future analytics

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] `DiceSubsystem` SubViewport uses pooled `RigidBody3D` dice and disables processing when idle

### Game Design Requirements
- [ ] Core dice cadence mirrors board-game pacing outlined in PRD (docs/game-prd.md:40-73)
- [ ] Roll/exhaust visuals communicate risk vs reward to player within one screen
- [ ] Dice lock interactions feel responsive (<150 ms input latency)

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/core/game_root.tscn` - Root scene that loads autoloads and instantiates Run HUD
- `res://scenes/core/run_hud.tscn` - HUD shell with dice tray, lock area, and buttons
- `res://scenes/systems/dice_subviewport.tscn` - SubViewport containing dice tray mesh and pooled dice bodies

**New Scripts:**

- `res://scripts/autoload/game_director.gd` - Bootstraps GameDirector autoload and handles state transitions (static typing required)
- `res://scripts/autoload/turn_manager.gd` - Coordinates turn phases and emits state signals (static typing required)
- `res://scripts/gameplay/dice_subsystem.gd` - Controls dice spawning, rolling, locking, pooling (static typing required)
- `res://scripts/ui/run_hud_controller.gd` - Binds HUD controls to TurnManager signals (static typing required)

**New Resources (.tres):**

- `res://resources/dice/dice_face_set.tres` - Defines symbol distribution for starter dice
- `res://resources/config/input_actions.tres` - Declarative definition for project input map (optional helper)

**Modified Files:**

- `project.godot` - Configure window, SubViewport scaling, InputMap actions, and autoload singletons
- `scripts/godot-cli.sh` - Ensure CLI hook runs new smoke scene (if necessary)

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# dice_subsystem.gd
class_name DiceSubsystem
extends Node3D

const DICE_POOL_SIZE := 4
@export_range(1, 6) var roll_animation_frames: int = 3

var _active_dice: Array[RigidBody3D] = []
var _pooled_dice: Array[RigidBody3D] = []

signal roll_resolved(dice_results: Array[int])

func _ready() -> void:
    _initialize_pool()
    set_physics_process(false)

func request_roll() -> void:
    set_physics_process(true)
    # Emit roll signal after dice settle
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/DiceTray`
- Scene Instancing: `GameDirector` instantiates `run_hud.tscn`; `RunHudController` instantiates `dice_subviewport.tscn`

**Node Dependencies:**

- `TurnManager` autoload: orchestrates roll phases and communicates with HUD (GDScript - deterministic control)
- `DiceSubsystem`: handles physics and symbol selection (GDScript - integrates with SubViewport pooling)
- `UiStateStore` (future) placeholder for HUD updates (GDScript)

**Signal Connections:**

- Emits: `turn_started`, `dice_committed`, `dice_locked_changed` from `TurnManager`
- Connects to: `RunHudController` for updating HUD, `DiceSubsystem.roll_resolved` back to `TurnManager`
- Cleanup: disconnect in `_exit_tree()` for HUD controller, disable physics processing when scene freed

**Resource Dependencies:**

- `res://resources/dice/dice_face_set.tres` - Used for dice face weights; preload to avoid stalls
- `res://resources/ui/run_theme.tres` - Placeholder theme for HUD (preload: yes to avoid flicker)

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create test file: `res://tests/unit/test_turn_manager.gd`
- [ ] Write test for `request_roll()` triggering dice physics enable - expect failure
- [ ] Write test for lock/exhaust cycle releasing dice on next turn - expect failure
- [ ] Write performance test verifying frame time stays <16.67 ms with dice pooling - expect failure

C# (GoDotTest):
- Not required for this story (GDScript implementation)

**GREEN Phase - Make Tests Pass:**

- [ ] Implement minimal code to enable/disable physics and emit signals to satisfy tests
- [ ] Implement exhaust pool reset to satisfy lock/exhaust test
- [ ] Ensure SubViewport pooling keeps performance test green
- [ ] Verify all tests are green via `scripts/godot-cli.sh test`

**REFACTOR Phase - Optimize and Clean:**

- [ ] Add static typing to all GDScript (10-20% perf gain)
- [ ] Remove redundant allocations in dice results array
- [ ] Implement object pooling for dice bodies and spark VFX placeholders
- [ ] Clean up signal connections in `_exit_tree()`
- [ ] Profile and verify 60+ FPS maintained with Godot profiler
- [ ] Ensure test coverage >= 80%

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for `TurnManager` and `DiceSubsystem` (RED phase)
- [ ] Implement node hierarchy and pooling to pass tests (GREEN phase)
- [ ] Refactor with static typing and optimization (REFACTOR phase)
- [ ] Create object pool for dice rigid bodies and roll particles
- [ ] Implement signal connections with cleanup between HUD and TurnManager
- [ ] Profile performance to ensure 60+ FPS
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with HUD button input and analytics stub
- [ ] Final performance validation (must maintain 60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

<!-- Only note deviations from requirements, keep under 50 words -->

**Change Log:**

<!-- Only requirement changes during implementation -->

## Godot Technical Context
**Engine Version:** Godot 4.5 (per architecture baseline)  
**Renderer:** Forward+  
**Primary Language:** GDScript - aligns with single-language discipline for maintainability

**Node Architecture:**
```
GameRoot (Node)
└── RunHUD (Control)
    ├── DiceTray (Control)
    │   └── DiceViewport (SubViewportContainer)
    │       └── DiceSubsystem (Node3D)
    ├── ActionButtons (Control)
    └── ExhaustTray (Control)
```

**Performance Requirements:**
- Target FPS: 60+ (mandatory)
- Frame Budget: 16.67ms
- Memory Budget: 450MB (per architecture)
- Draw Calls: < 120 during roll animations

**Object Pooling Required:**
- Dice rigid bodies: Pool size 4 (one per die)
- Recycling strategy: deactivate physics, reset transforms, return to pool post-resolution

## Game Design Context
**GDD Reference:** Epic 1, Story 1.1 (docs/game-prd.md:136-154)

**Game Mechanic:** Dice roll and exhaust cadence establishing core loop

**Godot Implementation Approach:**
- Node Architecture: Autoload-driven `TurnManager` controlling SubViewport dice (docs/architecture.md:88-143)
- Language Choice: GDScript for deterministic turn orchestration and physics hooks
- Performance Target: 60+ FPS with dice collision spikes limited via pooling

**Player Experience Goal:** Provide immediate tactile feedback for rolls while surfacing risk/reward choices without modal dialogs.

**Balance Parameters (Resource-based):**

- Dice faces: baseline distribution defined in `dice_face_set.tres`
- Roll animation length: 0.6s–0.8s (exported variable in subsystem)

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_turn_manager.gd`
- `res://tests/unit/test_dice_subsystem.gd`
- Coverage Target: 80% minimum

**GoDotTest Files (C#):**

- Not applicable for this story

**Test Scenarios (Write First - Red Phase):**

- `TurnManager` emits `dice_committed` after SubViewport settles - must validate 60+ FPS
- `DiceSubsystem` returns dice to pool on next roll - signal emission verification
- Exhaust tray handles pool boundary (all dice locked) - object pool boundary testing
- Performance test: frame time < 16.67ms with repeated rolls

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Execute three consecutive rolls with mixed locks

   - Expected: Locked dice stay, exhaust tray animates correctly on confirm
   - Performance: Must maintain 60+ FPS
   - Profiler Check: Frame time < 16.67ms
   - Language Validation: GDScript signals/physics behave as expected

2. Trigger roll cancel mid-animation

   - Expected: Dice reset without duplicates, TurnManager returns to idle
   - Signal Flow: `dice_locked_changed` only fires when state truly changes
   - Memory: No leaks, signals cleaned up
   - Object Pools: Verify dice bodies reused

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+ FPS consistently (FAIL if below)
- Frame time: < 16.67ms average
- Physics frame: < 3.5ms
- Memory usage: < 300MB for dice scenes
- Draw calls: < 120 during dice animation
- Object pools: Active and recycling properly
- GDScript static typing: Verified (10-20% perf gain)
- C# optimization: N/A
- Dice settle time: < 1.2s per roll

## Dependencies
**Story Dependencies:**

- None (story kicks off epic)

**Godot System Dependencies:**

- Node: `GameRoot` shown above must exist
- Autoload: `TurnManager`, `GameDirector`, `DicePoolCache` configured in autoload settings
- Language: Project configured for typed GDScript (no C# needed yet)

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: `dice_face_set.tres`
- Location: `res://resources/dice/dice_face_set.tres`
- Import Settings: Ensure compression disabled for quick access

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A for this story)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Dice loop confirmed against tutorial expectations in Run HUD

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript because single-language pipeline simplifies review and maintains architecture discipline
- Node Architecture: Autoload-driven coordinators keep Run HUD scene lightweight and modular
- Signal Pattern: Explicit connect/disconnect calls avoid global event bus coupling
- Ensure SubViewport resolution scales with device DPI to preserve readability

**Performance Decisions:**

- Static Typing: All scripts use typed properties to reduce GC pressure
- C# Usage: Deferred unless profiling demands; current scope stays in GDScript
- Object Pooling: Dice bodies and spark particles pooled to avoid allocation spikes
- Dice roll audio and VFX deferred until Story 4.1 to keep frame budget ample
""",

    "docs/stories/epic-1-crash-survivor-foundation/1.2-core-resources-and-hud-feedback.md": """# Godot Story: Core Resources & HUD Feedback

**Epic:** Crash Survivor Foundation  
**Story ID:** 1.2  
**Priority:** High  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Implement the `ResourceLedger` autoload and HUD panels that display and update health, materials, oxygen, and the global threat meter whenever dice results or scripted events occur. Adds warning thresholds, audio cues, and provisional save serialization so resource state persists through scene reloads. References: resource requirements (docs/game-prd.md:155-186) and architecture sections (docs/architecture.md:160-240).

**Godot Implementation:** Using `ResourceLedger` autoload and `HUDController` Control nodes in GDScript for immediate UI binding with static typing  
**Performance Impact:** Low; HUD updates run on main thread with minimal allocations, must maintain <1ms frame cost

## Acceptance Criteria
### Functional Requirements
- [ ] HUD displays four meters (health, materials, oxygen, threat) with numeric values and color-coded thresholds
- [ ] Dice or scripted test events adjust resources and update HUD instantly
- [ ] Threat meter triggers yellow/red visual + audio cues when crossing thresholds
- [ ] Resource state persists across scene reloads using provisional save slots

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] `ResourceLedger` updates fire typed signals and debounce multi-update bursts to avoid UI thrash

### Game Design Requirements
- [ ] Resource readouts communicate survival pressure outlined in PRD (docs/game-prd.md:40-95)
- [ ] Warning cues align with UX accessibility goals (docs/game-prd.md:96-140)
- [ ] Persistence behavior supports short mobile sessions without data loss

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/ui/resource_panel.tscn` - Control scene containing meter widgets
- `res://scenes/ui/threat_meter.tscn` - Specialized Control with thresholds and animations

**New Scripts:**

- `res://scripts/autoload/resource_ledger.gd` - Autoload storing resource values, emitting update signals
- `res://scripts/ui/resource_panel_controller.gd` - Subscribes to ledger updates and animates meters
- `res://scripts/ui/threat_meter_controller.gd` - Handles threshold detection and audio cues
- `res://scripts/services/save_service_stub.gd` - Extends existing SaveService with provisional run state serialization

**New Resources (.tres):**

- `res://resources/ui/resource_meter_theme.tres` - Styles for meters per accessibility guidelines
- `res://resources/config/resource_thresholds.tres` - Defines warning levels for each resource

**Modified Files:**

- `res://scenes/core/run_hud.tscn` - Add resource panel nodes and signal hookups
- `res://scripts/autoload/game_director.gd` - Register ResourceLedger and SaveService interactions

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# resource_ledger.gd
class_name ResourceLedger
extends Node

@export var max_health: int = 8
var _health: int = max_health setget set_health

signal health_changed(current: int, max: int)

func set_health(value: int) -> void:
    var clamped_value := clamp(value, 0, max_health)
    if clamped_value == _health:
        return
    _health = clamped_value
    health_changed.emit(_health, max_health)
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/ResourcePanel`
- Scene Instancing: Resource panel instanced within RunHUD and hooked to ResourceLedger

**Node Dependencies:**

- `ResourceLedger` (autoload) - central resource authority (GDScript)
- `HUDController` - orchestrates panel updates (GDScript)
- `SaveService` - temporary run state serialization (GDScript)

**Signal Connections:**

- Emits: `health_changed`, `materials_changed`, `oxygen_changed`, `threat_changed`
- Connects to: `resource_panel_controller.gd` to update meters; warning signals to `AudioDirector`
- Cleanup: HUD panel disconnects in `_exit_tree()`, SaveService clears provisional slots on run end

**Resource Dependencies:**

- `res://resources/config/resource_thresholds.tres` - used for warning thresholds (preload yes)
- `res://resources/ui/resource_meter_theme.tres` - theme for bars (preload yes)

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_resource_ledger.gd`
- [ ] Write test verifying clamped updates and signal emission - expect failure
- [ ] Write test ensuring persistence roundtrip via SaveService stub - expect failure
- [ ] Write performance test confirming batched updates stay <0.5ms - expect failure

C# (GoDotTest):
- Not required

**GREEN Phase - Make Tests Pass:**

- [ ] Implement ledger setters, typed signals, and throttle logic
- [ ] Implement SaveService provisional serialization to satisfy persistence test
- [ ] Optimize update pipeline to keep performance test green
- [ ] Ensure all tests green

**REFACTOR Phase - Optimize and Clean:**

- [ ] Apply static typing to all ledger and HUD scripts
- [ ] Replace Dictionary-based payloads with typed structs
- [ ] Pool warning VFX/audio players
- [ ] Ensure signal connections cleaned in `_exit_tree()`
- [ ] Profile HUD updates with debugger, confirm <1ms per frame
- [ ] Confirm coverage >=80%

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for ResourceLedger and SaveService provisional flow
- [ ] Implement ledger, panel controller, and threshold cues to pass tests
- [ ] Refactor with typed properties and pooled UI elements
- [ ] Create object pool for warning popups/audio players
- [ ] Implement signal connections linking TurnManager test events to ledger
- [ ] Profile performance to ensure 60+ FPS
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with RunHUD interactions
- [ ] Final performance validation (must maintain 60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript - resource manipulation and UI updates best served in same language as rest of codebase

**Node Architecture:**
```
RunHUD (Control)
└── ResourcePanel (Control)
    ├── HealthMeter (Control)
    ├── MaterialsMeter (Control)
    ├── OxygenMeter (Control)
    └── ThreatMeter (Control)
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: < 80 for HUD (static batched)

**Object Pooling Required:**
- Warning popups: Pool size 3 (one per threshold state)
- AudioStreamPlayer nodes: Pool size 2 reused for cues

## Game Design Context
**GDD Reference:** Epic 1, Story 1.2 (docs/game-prd.md:155-169)

**Game Mechanic:** Resource tracking and threat escalation feedback

**Godot Implementation Approach:**
- Node Architecture: Autoload ledger with Control-based meters (docs/architecture.md:160-216)
- Language Choice: GDScript to share typed signals across HUD and gameplay
- Performance Target: <1ms HUD update time while keeping 60 FPS budget

**Player Experience Goal:** Ensure players perceive survival pressure instantly with readable meters and accessible warning cues.

**Balance Parameters (Resource-based):**

- Warning thresholds defined per resource (e.g., 50% yellow, 25% red)
- Threat escalation increments stored in `resource_thresholds.tres`

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_resource_ledger.gd`
- `res://tests/unit/test_resource_panel_controller.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- N/A

**Test Scenarios (Write First - Red Phase):**

- Ledger clamps values and emits signals exactly once per change - validates 60 FPS by preventing loops
- SaveService stores and restores resource snapshot - signal verification
- Threshold crossing triggers warning event only when crossing boundary - ensures pool boundary usage
- Performance test: batched updates keep frame time <16.67ms

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Adjust resources through debug buttons
   - Expected: meters animate to new values with color change and audio cue where applicable
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms
   - Language Validation: Typed signals deliver expected payload

2. Reload scene after modifying resources
   - Expected: values persist based on provisional save state
   - Signal Flow: Single emission on load
   - Memory: No leaks, ledger resets cleanly on new run
   - Object Pools: Warning popups reused

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average
- Physics frame: <2ms (minimal impact)
- Memory usage: <280MB with HUD assets loaded
- Draw calls: <80 for UI
- Object pools: Active for warning cues
- GDScript static typing: Verified
- C# optimization: N/A
- HUD update cost: <1ms per update burst

## Dependencies
**Story Dependencies:**

- 1.1: Requires dice loop signals to feed resource changes

**Godot System Dependencies:**

- Node: RunHUD scene from Story 1.1
- Autoload: `ResourceLedger`, `SaveService`
- Language: Typed GDScript project-wide

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: `resource_thresholds.tres`
- Location: `res://resources/config/resource_thresholds.tres`
- Import Settings: Keep as text resource for diff-friendly edits

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Resource warnings verified on target devices for readability

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript because ledger integration benefits from single-language pipeline
- Node Architecture: Modular Control scenes keep HUD maintainable
- Signal Pattern: One autoload emits typed signals consumed by multiple panels
- Save stub should live under `scripts/services/` per architecture file structure

**Performance Decisions:**

- Static Typing: All ledger fields typed to integers/floats
- C# Usage: Deferred unless profiling shows need for IL speedups
- Object Pooling: Popups and audio players pooled to prevent GC spikes
- Animations use Tweeners reused via nodes instead of creating new tweens per update
""",

    "docs/stories/epic-1-crash-survivor-foundation/1.3-prototype-room-queue-and-exploration-actions.md": """# Godot Story: Prototype Room Queue & Exploration Actions

**Epic:** Crash Survivor Foundation  
**Story ID:** 1.3  
**Priority:** High  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Create the initial `RoomQueueService` autoload, data-driven room deck, and HUD interactions that present two active rooms plus backlog, handle action consumption, and replenish the queue from Resource-based definitions. Exploration choices must modify resources and threat according to card metadata. References: PRD story (docs/game-prd.md:170-186) and architecture sections (docs/architecture.md:110-220).

**Godot Implementation:** Using `RoomQueueService` autoload and Control-based card list with typed GDScript for data-driven queue management  
**Performance Impact:** Low-medium; queue operations must avoid allocation spikes and prefetch room data to keep frame times within budget

## Acceptance Criteria
### Functional Requirements
- [ ] Room queue displays two selectable rooms plus backlog count sourced from Resource data
- [ ] Selecting a room consumes an action, reveals detailed view, and queues replacement card
- [ ] Exploration outcome adjusts resources/threat per metadata (success/failure paths)
- [ ] Deck reshuffles when exhausted and prevents duplicate draws beyond defined limits

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Room data loaded from `res://resources/rooms/*.tres` with caching and thread-safe refill strategy

### Game Design Requirements
- [ ] Room tags and difficulty reflect PRD archetypes (hazard/cache/sanctuary/anomaly)
- [ ] Action costs align with push-your-luck pacing described in PRD (docs/game-prd.md:40-95)
- [ ] Rewards adjust ResourceLedger values and contribute to clues/accessibility goals

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/ui/room_card.tscn` - Visual representation of a room card with interactions
- `res://scenes/ui/room_queue_panel.tscn` - Panel listing active rooms and backlog indicator

**New Scripts:**

- `res://scripts/autoload/room_queue_service.gd` - Autoload managing deck loading, shuffling, replenishment
- `res://scripts/ui/room_card_controller.gd` - Handles card taps, shows metadata, dispatches exploration requests
- `res://scripts/ui/room_queue_panel_controller.gd` - Binds queue data to UI and handles action gating
- `res://scripts/gameplay/exploration_resolver.gd` - Applies resource/threat outcomes post-selection

**New Resources (.tres):**

- `res://resources/rooms/deck_baseline.tres` - Defines baseline room cards and draw weights
- `res://resources/rooms/room_<slug>.tres` - Individual room definitions (12 baseline cards)

**Modified Files:**

- `res://scripts/autoload/turn_manager.gd` - Integrate room selection into turn phases
- `res://scenes/core/run_hud.tscn` - Add room queue panel and detail overlay placeholder

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# room_queue_service.gd
class_name RoomQueueService
extends Node

@export var deck_resource: Resource

var _active_rooms: Array[RoomCardResource] = []
var _backlog: Array[RoomCardResource] = []

signal room_queue_updated(active_rooms: Array[RoomCardResource], backlog_size: int)

func _ready() -> void:
    _load_deck()
    _refill_active_rooms()
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/RoomQueuePanel`
- Scene Instancing: RunHUD adds RoomQueue panel; RoomQueueService autoload accessible globally

**Node Dependencies:**

- `RoomQueueService` (autoload) - deck management (GDScript)
- `TurnManager` - consumes actions and requests room presentation (GDScript)
- `ResourceLedger` - receives adjustments from exploration resolver

**Signal Connections:**

- Emits: `room_queue_updated`, `room_selected`, `room_resolved`
- Connects to: Room queue panel UI and TurnManager for action gating
- Cleanup: Panel unsubscribes on `_exit_tree()`, service clears decks on new run start

**Resource Dependencies:**

- `res://resources/rooms/deck_baseline.tres` - baseline deck definitions (preload yes)
- `res://resources/config/game_balance.tres` - references for draw weights

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_room_queue_service.gd`
- [ ] Test deck loading and active slot refill logic - expect failure
- [ ] Test action consumption preventing double selection per turn - expect failure
- [ ] Performance test verifying queue update executes under 1ms - expect failure

C# (GoDotTest):
- Not required

**GREEN Phase - Make Tests Pass:**

- [ ] Implement deck load, shuffle, and active/backlog management
- [ ] Integrate TurnManager checks for action availability
- [ ] Optimize queue updates and caching to pass performance test
- [ ] Ensure all tests pass

**REFACTOR Phase - Optimize and Clean:**

- [ ] Add static typing across queue structures
- [ ] Use pooled room card instances to avoid Control instantiation cost
- [ ] Ensure signals cleaned up and deck resets handled gracefully
- [ ] Profile queue refresh with profiler to confirm <1ms spent
- [ ] Maintain >=80% coverage

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for RoomQueueService deck operations
- [ ] Implement queue service, panel controllers, and exploration resolver to satisfy tests
- [ ] Refactor with typed arrays, caching, and pooling
- [ ] Create object pool for `room_card.tscn` instances
- [ ] Implement signal connections between TurnManager and RoomQueueService
- [ ] Profile performance to ensure 60+ FPS during queue updates
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with ResourceLedger adjustments
- [ ] Final performance validation (60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript - consistent with autoload/service architecture

**Node Architecture:**
```
RunHUD (Control)
└── RoomQueuePanel (Control)
    ├── ActiveRoomSlot1 (Control)
    ├── ActiveRoomSlot2 (Control)
    └── BacklogCounter (Label)
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: < 90 for HUD + room cards

**Object Pooling Required:**
- Room card UI nodes: Pool size 4 (two active + buffer)
- Event overlays: pool placeholders for future overlays (size 2)

## Game Design Context
**GDD Reference:** Epic 1, Story 1.3 (docs/game-prd.md:170-183)

**Game Mechanic:** Room queue management and exploration choices

**Godot Implementation Approach:**
- Node Architecture: Autoload manages Resource-based deck feeding Control panels (docs/architecture.md:190-230)
- Language Choice: GDScript ensures consistent data manipulation and signal flow
- Performance Target: Keep queue refresh under 1ms, maintain 60 FPS even during reshuffle

**Player Experience Goal:** Offer at-a-glance room choices and maintain tension by exposing limited information and costs.

**Balance Parameters (Resource-based):**

- Deck composition weights stored in `deck_baseline.tres`
- Room difficulty modifiers exported for designer tuning

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_room_queue_service.gd`
- `res://tests/unit/test_exploration_resolver.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- N/A

**Test Scenarios (Write First - Red Phase):**

- Queue loads baseline deck and populates two active slots - ensures 60 FPS by preloading resources
- Selecting a room decrements action count and triggers replacement draw - signal verification
- Deck reshuffle respects composition limits and avoids duplication beyond defined tags - boundary testing
- Performance test: queue update under 1ms, frame time <16.67ms

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Cycle through draws until deck reshuffle
   - Expected: Backlog counts update, no duplicate anomalies beyond limit
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms
   - Signals: `room_queue_updated` events observed once per change

2. Select room with success/failure outcomes
   - Expected: ResourceLedger adjusts values, threat meter responds per metadata
   - Signal Flow: `room_resolved` fires with results
   - Memory: Room cards reused via pooling
   - Object Pools: Instances reused without leaks

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average
- Physics frame: <2ms (minimal involvement)
- Memory usage: <300MB including room assets
- Draw calls: <90 while cards visible
- Object pools: Room cards and overlays reused
- GDScript static typing: Verified
- C# optimization: N/A
- Queue update CPU cost: <0.6ms

## Dependencies
**Story Dependencies:**

- 1.1: Requires dice loop and TurnManager integration
- 1.2: Needs ResourceLedger for outcome adjustments

**Godot System Dependencies:**

- Node: RunHUD with RoomQueue panel placeholder
- Autoload: `RoomQueueService`, `TurnManager`, `ResourceLedger`
- Language: Typed GDScript pipeline

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: `deck_baseline.tres` and individual room card resources
- Location: `res://resources/rooms/`
- Import Settings: Keep as text resources for merge-friendly edits

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Room queue behavior reviewed for UX clarity on mobile

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript for consistent data-driven gameplay systems
- Node Architecture: Panel composition keeps queue flexible for future expansions
- Signal Pattern: Autoload emits typed updates to decouple UI from service
- Use `ResourceUID` references for cross-links to events/threats as defined in architecture

**Performance Decisions:**

- Static Typing: Arrays typed to `RoomCardResource`
- C# Usage: Deferred until profiling suggests need
- Object Pooling: Room card UI nodes pooled to eliminate Control allocations mid-run
- Prefetch room resources during boot to avoid hitches when presenting new cards
""",

    "docs/stories/epic-1-crash-survivor-foundation/1.4-first-threat-encounter-and-escape-resolution.md": """# Godot Story: First Threat Encounter & Escape Resolution

**Epic:** Crash Survivor Foundation  
**Story ID:** 1.4  
**Priority:** High  
**Points:** 13  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Deliver the first end-to-end threat encounter: spawn a scripted latched threat, run its attack timer, allow combat and evasion resolutions, and trigger the escape prompt once the clue threshold is met. Includes defeat/victory flows, post-run summary, and telemetry stub output. References: PRD story (docs/game-prd.md:187-214) and architecture sections covering ThreatService, CombatResolver, GameDirector state machine (docs/architecture.md:200-340).

**Godot Implementation:** Using `ThreatService` autoload, `CombatResolver` utility, and `GameDirector` state transitions in typed GDScript to orchestrate threat phases  
**Performance Impact:** Medium; timers and dice interactions must be optimized with pooling to maintain frame rate, especially when threat attacks trigger VFX

## Acceptance Criteria
### Functional Requirements
- [ ] Scripted event latches a single threat with attack timer UI and countdown behavior
- [ ] Combat resolution allows spending attack symbols to meet damage threshold; evasion requires agility symbol set
- [ ] Collecting configured clue count unlocks escape prompt; failure triggers defeat screen with summary
- [ ] Post-run summary logs resources, duration, and outputs telemetry stub entries for analytics

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Threat timers and attack animations executed via pooled timers/particles and do not allocate per tick

### Game Design Requirements
- [ ] Threat cadence matches latching behavior described in PRD (docs/game-prd.md:40-95)
- [ ] Escape conditions align with clue economy goals (docs/game-prd.md:40-70)
- [ ] Summary screen communicates key run metrics supporting validation plan

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/ui/threat_overlay.tscn` - Control overlay showing latched threat, timer, combat/evasion options
- `res://scenes/ui/escape_prompt.tscn` - Modal presenting escape decision when clues met
- `res://scenes/ui/post_run_summary.tscn` - Summary panel with run stats and telemetry stub button

**New Scripts:**

- `res://scripts/autoload/threat_service.gd` - Manages threat lifecycle, timers, and resolution signals
- `res://scripts/gameplay/combat_resolver.gd` - Handles symbol validation, damage application, and outcomes
- `res://scripts/ui/threat_overlay_controller.gd` - Binds threat data to overlay and handles player choices
- `res://scripts/ui/escape_prompt_controller.gd` - Validates clue threshold and triggers victory state
- `res://scripts/ui/post_run_summary_controller.gd` - Aggregates run data and fires telemetry stub

**New Resources (.tres):**

- `res://resources/threats/first_latched_threat.tres` - Defines baseline threat stats, timer cadence, rewards
- `res://resources/config/escape_requirements.tres` - Configurable clue thresholds and rewards

**Modified Files:**

- `res://scripts/autoload/turn_manager.gd` - Insert threat phase calls and door into escape check
- `res://scripts/autoload/game_director.gd` - Handle state transitions to `RunCompleted`
- `res://scenes/core/run_hud.tscn` - Add threat overlay and escape prompt placeholders

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# threat_service.gd
class_name ThreatService
extends Node

@export var threat_profile: ThreatProfileResource

var _active_threat: ThreatProfileResource
var _attack_timer := 0.0

signal threat_timer_updated(time_remaining: float)
signal threat_action_resolved(outcome: String)

func spawn_threat(resource: ThreatProfileResource) -> void:
    _active_threat = resource
    _attack_timer = resource.attack_cadence_seconds
    # Emit latch signal to UI
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/ThreatOverlay`
- Scene Instancing: Threat overlay added as CanvasLayer; Post Run summary shown via `GameDirector`

**Node Dependencies:**

- `ThreatService` autoload - orchestrates timers and outcomes (GDScript)
- `CombatResolver` - utility invoked from `TurnManager`
- `GameDirector` - state machine transitions to escape/defeat scenes
- `ResourceLedger` - applies damage/resource adjustments

**Signal Connections:**

- Emits: `threat_timer_updated`, `threat_action_resolved`, `escape_unlocked`
- Connects to: `ThreatOverlayController`, `EscapePromptController`, `GameDirector`
- Cleanup: Timer signals disconnected in `_exit_tree()`, threat resources cleared post-run

**Resource Dependencies:**

- `res://resources/threats/first_latched_threat.tres` - threat definition (preload yes)
- `res://resources/config/escape_requirements.tres` - clue threshold (preload yes)

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_threat_service.gd`
- [ ] Test timer countdown and attack trigger at cadence - expect failure
- [ ] Test combat and evasion resolutions adjusting resources correctly - expect failure
- [ ] Performance test verifying threat tick logic stays <0.5ms per frame - expect failure

C# (GoDotTest):
- Not required

**GREEN Phase - Make Tests Pass:**

- [ ] Implement timer updates using `_process` gating and pooling
- [ ] Implement combat resolver applying damage/evasion results
- [ ] Optimize logic to maintain sub-millisecond tick cost
- [ ] Ensure tests pass

**REFACTOR Phase - Optimize and Clean:**

- [ ] Add static typing to threat resources and overlay controllers
- [ ] Pool VFX/audio for attacks to avoid allocations
- [ ] Cleanup signals and reset state on defeat/victory
- [ ] Validate performance with profiler including timer spikes
- [ ] Achieve coverage >=80%

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for ThreatService timers/combat
- [ ] Implement threat spawn, timer, overlays, escape logic to satisfy tests
- [ ] Refactor with typed structs, pooling, and state cleanup
- [ ] Create object pool for threat attack VFX/audio cues
- [ ] Implement signal connections among TurnManager, ThreatService, GameDirector
- [ ] Profile performance to ensure 60+ FPS even during threat actions
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with ResourceLedger, RoomQueueService, telemetry stub
- [ ] Final performance validation (60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript - threat systems integrate with existing autoload architecture

**Node Architecture:**
```
RunHUD (Control)
└── ThreatOverlay (CanvasLayer)
    ├── ThreatCard (Control)
    ├── TimerDisplay (Label)
    ├── CombatButtons (Control)
    └── EvasionButtons (Control)
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: <110 when overlay active

**Object Pooling Required:**
- Threat attack VFX/audio emitters: pool size 3
- Timer tick indicators: pool size 2 for reuse

## Game Design Context
**GDD Reference:** Epic 1, Story 1.4 (docs/game-prd.md:187-214)

**Game Mechanic:** Latched threat resolution and escape sequence

**Godot Implementation Approach:**
- Node Architecture: Autoload-driven threat service with overlay UI (docs/architecture.md:210-320)
- Language Choice: GDScript ensures consistent integration with ResourceLedger and TurnManager
- Performance Target: Timer updates and attack actions must stay under 1ms to avoid frame drops

**Player Experience Goal:** Provide tense threat countdowns, clear resolution options, and satisfying run wrap-up.

**Balance Parameters (Resource-based):**

- Threat attack cadence and damage defined in `first_latched_threat.tres`
- Clue threshold for escape stored in `escape_requirements.tres`

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_threat_service.gd`
- `res://tests/unit/test_combat_resolver.gd`
- `res://tests/unit/test_escape_prompt_controller.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- N/A

**Test Scenarios (Write First - Red Phase):**

- Timer counts down and emits attack event at defined cadence - ensures 60 FPS by gating processing
- Combat resolution reduces threat HP and updates resource ledger - signal verification
- Escape unlock fires once clue threshold reached and not before - boundary testing
- Performance test: threat tick + overlay update <16.67ms frame budget

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Trigger threat encounter through scripted event
   - Expected: Threat overlay appears, timer counts down, attack resolves on expiry
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms
   - Memory: VFX pooled, no leaks

2. Achieve escape threshold then choose escape
   - Expected: Escape prompt appears, success leads to summary screen with correct stats
   - Signal Flow: `escape_unlocked` fires once, summary collects run metrics
   - Object Pools: Attack VFX reused without re-instantiation

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average (spikes <4ms per architecture requirement)
- Physics frame: <3ms during threat dice rolls
- Memory usage: <320MB with overlay assets
- Draw calls: <110 during threat overlay
- Object pools: Attack/evasion effects reused
- GDScript static typing: Verified
- C# optimization: N/A
- Threat tick CPU cost: <0.8ms

## Dependencies
**Story Dependencies:**

- 1.1: Requires dice loop for threat resolution actions
- 1.2: ResourceLedger updates from damage/escape
- 1.3: Clue acquisition from rooms to unlock escape

**Godot System Dependencies:**

- Node: Threat overlay CanvasLayer within RunHUD
- Autoload: `ThreatService`, `TurnManager`, `GameDirector`, `TelemetryHub`
- Language: Typed GDScript baseline

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: `first_latched_threat.tres`, `escape_requirements.tres`
- Location: `res://resources/threats/`, `res://resources/config/`
- Import Settings: Text resources

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Telemetry stub outputs validated for analytics integration

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript ensures consistent integration with autoload services
- Node Architecture: Overlay + autoload separation supports future threat variants
- Signal Pattern: ThreatService centralizes emissions, GameDirector listens for state transitions
- Escape prompt should reuse UI theme assets for consistency across flows

**Performance Decisions:**

- Static Typing: All timer values floats, resources typed to `ThreatProfileResource`
- C# Usage: Deferred; potential migration if profiling shows GDScript bottlenecks
- Object Pooling: Attack/evasion VFX, audio, and timer tick markers pooled
- Threat timers use `SceneTreeTimer` pooling or manual `_process` gating to maintain budget
""",

    "docs/stories/epic-2-threat-escalation-and-room-depth/2.1-advanced-room-decks-and-events.md": """# Godot Story: Advanced Room Decks & Events

**Epic:** Threat Escalation & Room Depth  
**Story ID:** 2.1  
**Priority:** High  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Expand the room content pipeline to support at least 30 unique room cards with archetype tags, event hooks, and configurable deck composition. Implement the narrative event resolver overlay that presents contextual choices altering resources/threat. References: PRD story (docs/game-prd.md:215-233) and architecture sections on Resource-driven content (docs/architecture.md:120-260).

**Godot Implementation:** Using Resource-authored `RoomCardResource` assets, `RoomQueueService` extension methods, and a reusable `EventResolver` Control scene in typed GDScript  
**Performance Impact:** Moderate; loading additional content must use streaming/batching to avoid frame spikes, event resolver overlays should reuse pooled UI elements

## Acceptance Criteria
### Functional Requirements
- [ ] Room deck expanded to >=30 cards with tags (hazard, cache, sanctuary, anomaly)
- [ ] Deck composition rules enforce tag limits (e.g., max 3 anomalies) and shuffle weights via config
- [ ] Selecting certain rooms triggers narrative event overlay with contextual choices and resource/threat impacts
- [ ] Event outcomes logged to combat log/telemetry stub for later balancing

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Deck loading streams room resources asynchronously during downtime to minimize hitching

### Game Design Requirements
- [ ] Room archetypes align with PRD tags and deliver diversity in difficulty/reward (docs/game-prd.md:40-95, 215-233)
- [ ] Event choices reflect narrative tone and push risk/reward decision making
- [ ] Logs capture data required for balancing (resource deltas, threat escalation)

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/ui/event_resolver.tscn` - Overlay Control presenting narrative text, choices, and outcomes

**New Scripts:**

- `res://scripts/resources/room_card_resource.gd` - Resource script with metadata fields (if not existing)
- `res://scripts/ui/event_resolver_controller.gd` - Handles event presentation, choice callbacks, and logging
- `res://scripts/services/deck_rules_engine.gd` - Applies composition rules when building deck
- `res://scripts/services/event_log_service.gd` - Batches event outcomes for telemetry

**New Resources (.tres):**

- `res://resources/rooms/room_*.tres` - Additional room cards with metadata (tags, difficulty, events)
- `res://resources/config/deck_rules.tres` - Defines tag limits and weights
- `res://resources/events/event_*.tres` - Optional data assets for narrative events

**Modified Files:**

- `res://scripts/autoload/room_queue_service.gd` - Integrate deck rules engine and event triggers
- `res://scenes/ui/room_queue_panel.tscn` - Hook event overlay entry point

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# deck_rules_engine.gd
class_name DeckRulesEngine
extends Resource

@export var max_anomaly_cards: int = 3
@export var tag_weights: Dictionary = {
    "hazard": 1.0,
    "cache": 0.8,
    "sanctuary": 0.7,
    "anomaly": 0.3
}

func compose_deck(source_cards: Array[RoomCardResource]) -> Array[RoomCardResource]:
    # Filter and weighted shuffle respecting tag limits
    return []
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/EventResolver`
- Scene Instancing: Resolver overlay instanced as needed and reused via pooling

**Node Dependencies:**

- `RoomQueueService` - now references deck rules engine and event resolver
- `ResourceLedger` - updated based on event outcomes
- `TelemetryHub` - receives event log entries

**Signal Connections:**

- Emits: `event_presented`, `event_resolved`
- Connects to: `EventResolverController` for UI, `TelemetryHub` for logging, `RoomQueueService` for continuing flow
- Cleanup: Overlay unsubscribes on `_exit_tree()`, event logs flushed post-run

**Resource Dependencies:**

- `res://resources/config/deck_rules.tres` - deck composition configuration (preload yes)
- `res://resources/events/event_catalog.tres` - optional event linking file (preload yes)

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_deck_rules_engine.gd`
- [ ] Test deck composition obeys tag limits and weights - expect failure
- [ ] Create `res://tests/unit/test_event_resolver_controller.gd` verifying choices adjust resources - expect failure
- [ ] Performance test ensuring deck rebuild executes <1.5ms - expect failure

C# (GoDotTest):
- Not required

**GREEN Phase - Make Tests Pass:**

- [ ] Implement deck rules weighting and selection logic
- [ ] Implement event resolver applying outcomes with ResourceLedger integration
- [ ] Optimize deck rebuild (precompute arrays, caching) to pass performance test
- [ ] Ensure tests green

**REFACTOR Phase - Optimize and Clean:**

- [ ] Add static typing across deck/event components
- [ ] Pool event overlay instances and text nodes
- [ ] Preload event data during boot to avoid run-time loads
- [ ] Ensure logs flush efficiently without blocking main thread
- [ ] Maintain coverage >=80%

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for deck rules and event resolver
- [ ] Implement deck composition, event overlay, and logging to satisfy tests
- [ ] Refactor with typed arrays, caching, pooling
- [ ] Create object pool for event overlay nodes
- [ ] Implement signal connections linking RoomQueueService to EventResolver and TelemetryHub
- [ ] Profile performance (deck rebuild/event overlay) to ensure 60 FPS
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with RoomQueueService and ResourceLedger
- [ ] Final performance validation (60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript - maintains single-language pipeline for deck/event systems

**Node Architecture:**
```
RunHUD (Control)
└── EventResolver (CanvasLayer)
    ├── NarrativeText (RichTextLabel)
    ├── ChoiceList (VBoxContainer)
    └── OutcomePreview (Control)
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: <115 when resolver overlay active

**Object Pooling Required:**
- Event choice buttons: pool size 4
- Overlay instances: single pooled CanvasLayer reused per event

## Game Design Context
**GDD Reference:** Epic 2, Story 2.1 (docs/game-prd.md:215-223)

**Game Mechanic:** Room diversity with narrative events influencing resources/threat

**Godot Implementation Approach:**
- Node Architecture: Resource-driven deck feeding event overlays (docs/architecture.md:190-280)
- Language Choice: GDScript for resource parsing and UI integration
- Performance Target: Precompute deck composition during downtime to maintain 60 FPS

**Player Experience Goal:** Deliver variety and narrative flavor, reinforcing push-your-luck by offering meaningful event choices.

**Balance Parameters (Resource-based):**

- Tag weights defined in `deck_rules.tres`
- Event outcome modifiers stored per event resource

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_deck_rules_engine.gd`
- `res://tests/unit/test_event_resolver_controller.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- N/A

**Test Scenarios (Write First - Red Phase):**

- Deck build respects anomaly cap and weight distribution - ensures consistent performance via precompute
- Event selection applies correct ResourceLedger deltas - signal verification
- Event logging batches entries without duplicates - ensures log boundary correctness
- Performance test: deck rebuild <1.5ms, overlay show/hide <0.8ms

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Trigger multiple event-bearing rooms
   - Expected: Overlay shows narrative text and options; choices update resources/threat and log events
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms
   - Signals: `event_resolved` fired once per event

2. Exhaust deck and ensure reshuffle respects composition
   - Expected: Tag limits maintained, weight distribution roughly applied
   - Memory: Room resources reused without leak
   - Object Pools: Event overlay reused

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average
- Physics frame: <2ms
- Memory usage: <340MB with expanded room assets
- Draw calls: <115 with overlay active
- Object pools: Buttons/overlays reused
- GDScript static typing: Verified
- C# optimization: N/A
- Deck rebuild CPU cost: <1.5ms

## Dependencies
**Story Dependencies:**

- 1.3: Extends existing room queue infrastructure

**Godot System Dependencies:**

- Node: Room queue panel and event overlay placeholders from prior stories
- Autoload: `RoomQueueService`, `TelemetryHub`, `ResourceLedger`
- Language: Typed GDScript environment

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: New room cards, event resources, deck rules
- Location: `res://resources/rooms/`, `res://resources/events/`
- Import Settings: Use text resources for version control friendliness

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Event analytics integrated with telemetry stub

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript maintains unified content tooling
- Node Architecture: Overlay reuse prevents UI duplication
- Signal Pattern: RoomQueueService orchestrates events, TelemetryHub logs outcomes
- Deck rule engine should expose inspector-friendly exports for designers

**Performance Decisions:**

- Static Typing: Arrays typed as `RoomCardResource` and `EventResource`
- C# Usage: Not required; GDScript meets needs
- Object Pooling: Event overlay nodes pooled for reuse
- Preload heavy narrative text to avoid loading jank mid-run
""",

    "docs/stories/epic-2-threat-escalation-and-room-depth/2.2-threat-timer-variants-and-status-effects.md": """# Godot Story: Threat Timer Variants & Status Effects

**Epic:** Threat Escalation & Room Depth  
**Story ID:** 2.2  
**Priority:** High  
**Points:** 10  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Extend the threat system to support varied attack cadences (immediate, per turn, delayed burst) and status effects (bleed, oxygen leak, dice lock) with HUD indicators and durations. Update the global threat meter to react to unresolved threats each cycle and log threat actions. References: PRD story (docs/game-prd.md:234-249) and architecture sections covering ThreatService, status resources, HUD integration (docs/architecture.md:200-320).

**Godot Implementation:** Using `ThreatService` enhancements, `StatusEffectResource`, and HUD badge components in typed GDScript to convey threat pressure and statuses  
**Performance Impact:** Moderate; additional timers/status updates must remain lightweight, and UI badges should be pooled to prevent allocations

## Acceptance Criteria
### Functional Requirements
- [ ] Threat cards define attack cadence variants (immediate, per turn, delayed burst) that execute correctly
- [ ] Threat dice can apply status effects (bleed, oxygen leak, dice lock) with UI icons and duration countdowns
- [ ] Global threat meter increments when threats remain unresolved through a full cycle
- [ ] Combat log records threat actions, including status applications and resource impacts

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Status update loop runs in under 1ms and reuses pooled HUD badges/particles

### Game Design Requirements
- [ ] Threat behaviors match escalating pressure goals (docs/game-prd.md:40-95, 234-249)
- [ ] Status effects communicate consequences clearly and impact tactics
- [ ] Combat log entries provide useful telemetry for balancing

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/ui/status_badge.tscn` - Badge displayed on HUD for active statuses

**New Scripts:**

- `res://scripts/resources/status_effect_resource.gd` - Resource defining status metadata (icon, duration, effects)
- `res://scripts/gameplay/status_effect_controller.gd` - Manages applying/removing statuses on player state
- `res://scripts/ui/status_badge_controller.gd` - Handles badge visuals, duration countdown
- `res://scripts/services/combat_log_service.gd` - Captures threat action entries (if not already created)

**New Resources (.tres):**

- `res://resources/status_effects/bleed.tres`, `oxygen_leak.tres`, `dice_lock.tres`
- Threat profiles updated to reference new cadence and status data

**Modified Files:**

- `res://scripts/autoload/threat_service.gd` - Extend to handle cadence variants and status application
- `res://scripts/ui/threat_overlay_controller.gd` - Display status icons and timers
- `res://scripts/autoload/resource_ledger.gd` - Add methods to process status ticks (oxygen drain, etc.)
- `res://resources/threats/*.tres` - Add cadence/status definitions

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# status_effect_controller.gd
class_name StatusEffectController
extends Node

var _active_effects: Array[StatusEffectResource] = []

signal status_applied(effect: StatusEffectResource)
signal status_removed(effect: StatusEffectResource)

func apply(effect: StatusEffectResource) -> void:
    _active_effects.append(effect)
    status_applied.emit(effect)

func tick(delta: float) -> void:
    for effect in _active_effects:
        effect.remaining_time -= delta
        if effect.remaining_time <= 0:
            remove(effect)
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/StatusBadgePanel`
- Scene Instancing: Status badges instanced via pool when statuses applied

**Node Dependencies:**

- `ThreatService` - emits status application and cadence events
- `StatusEffectController` - manages active status list and ticks
- `ResourceLedger` - applies effects (bleed damage, oxygen drain)
- `TelemetryHub` - logs combat log entries

**Signal Connections:**

- Emits: `status_applied`, `status_removed`, `status_tick`
- Connects to: `StatusBadgeController` for visuals, `ResourceLedger` for effect processing, `TelemetryHub` for logs
- Cleanup: Status controller clears effects on run end, badges returned to pool

**Resource Dependencies:**

- `res://resources/status_effects/*.tres` - status definitions
- `res://resources/threats/*.tres` - updated threat profiles referencing new cadences/statuses

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_threat_cadence.gd` verifying each cadence triggers correctly
- [ ] Create `res://tests/unit/test_status_effect_controller.gd` verifying apply/tick/remove flows
- [ ] Performance test ensuring status tick loop stays <1ms for typical counts

C# (GoDotTest):
- Not required

**GREEN Phase - Make Tests Pass:**

- [ ] Implement cadence handling within ThreatService
- [ ] Implement status controller integration with ResourceLedger and HUD
- [ ] Optimize tick logic (typed arrays, early exit) to satisfy performance test
- [ ] Confirm tests pass

**REFACTOR Phase - Optimize and Clean:**

- [ ] Apply static typing to status arrays and timers
- [ ] Pool badge UI nodes, VFX, and audio cues
- [ ] Ensure threat log batching avoids per-frame string allocations
- [ ] Validate performance using profiler during high-pressure sequences
- [ ] Maintain >=80% coverage

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for threat cadences and status effects
- [ ] Implement cadence logic, status controller, HUD badges to satisfy tests
- [ ] Refactor for typed arrays, pooling, efficient logging
- [ ] Create object pool for status badge nodes and effect VFX
- [ ] Implement signal connections linking ThreatService, ResourceLedger, HUD, telemetry
- [ ] Profile performance (threat ticks/status updates) to ensure 60 FPS
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with existing threat overlay and resource systems
- [ ] Final performance validation (60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript - consistent with threat systems and HUD integrations

**Node Architecture:**
```
RunHUD (Control)
├── ThreatOverlay (CanvasLayer)
└── StatusBadgePanel (HBoxContainer)
    └── StatusBadge (Control) [pooled]
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: <120 when multiple badges active

**Object Pooling Required:**
- Status badges: pool size 5
- Status VFX/audio: pool size 3

## Game Design Context
**GDD Reference:** Epic 2, Story 2.2 (docs/game-prd.md:234-243)

**Game Mechanic:** Threat cadence variety and debuff pressure

**Godot Implementation Approach:**
- Node Architecture: Autoload threat service with pooled HUD badges (docs/architecture.md:210-330)
- Language Choice: GDScript ensures interplay with ResourceLedger and UI
- Performance Target: Keep status tick below 1ms; maintain 60 FPS even with multiple statuses

**Player Experience Goal:** Increase tension through timed attacks and ongoing debuffs while keeping feedback immediate and readable.

**Balance Parameters (Resource-based):**

- Status durations and magnitudes stored in `.tres`
- Global threat increment per unresolved threat defined in config resources

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_threat_cadence.gd`
- `res://tests/unit/test_status_effect_controller.gd`
- `res://tests/unit/test_status_badge_controller.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- N/A

**Test Scenarios (Write First - Red Phase):**

- Immediate cadence triggers attack once on spawn - ensures timer logic accuracy
- Per-turn cadence triggers after each player action - signal verification
- Status durations tick down correctly and remove badge when expired - boundary testing
- Performance test: combined status + threat tick loop <16.67ms per frame

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Spawn threats with different cadences
   - Expected: Immediate attack resolves on spawn; per-turn triggers after each dice commit; delayed burst counts down and strikes at zero
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms
   - Logs: Combat log entries captured per attack

2. Apply multiple status effects
   - Expected: Badges appear with duration countdown; bleed drains health each tick; oxygen leak reduces oxygen meter; dice lock prevents locking when active
   - Signal Flow: Status apply/remove signals fired appropriately
   - Object Pools: Badges reused, no duplicate nodes left behind

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average
- Physics frame: <3ms during threat actions
- Memory usage: <330MB with status assets
- Draw calls: <120 when overlay + badges active
- Object pools: Status badges/VFX reused
- GDScript static typing: Verified
- C# optimization: N/A
- Status tick CPU cost: <0.9ms

## Dependencies
**Story Dependencies:**

- 1.4: Builds on initial threat system
- 2.1: Event outcomes may apply statuses

**Godot System Dependencies:**

- Node: Threat overlay and status badge panel
- Autoload: `ThreatService`, `StatusEffectController`, `ResourceLedger`, `TelemetryHub`
- Language: Typed GDScript pipeline

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: Status effect resources, updated threat profiles
- Location: `res://resources/status_effects/`, `res://resources/threats/`
- Import Settings: Text resources for version control

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Threat log integrated with telemetry for balancing

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript suits timer/status logic adjacent to existing systems
- Node Architecture: Status badges separated for reuse and readability
- Signal Pattern: ThreatService central emitter, status controller handles specifics
- Cadence definitions should remain data-driven for future tuning

**Performance Decisions:**

- Static Typing: Arrays typed to `StatusEffectResource`
- C# Usage: Not needed presently
- Object Pooling: Badges and VFX audio reused to avoid allocations
- Threat log uses ring buffer to prevent unbounded growth during runs
""",

    "docs/stories/epic-2-threat-escalation-and-room-depth/2.3-clue-milestones-and-mini-objectives.md": """# Godot Story: Clue Milestones & Mini Objectives

**Epic:** Threat Escalation & Room Depth  
**Story ID:** 2.3  
**Priority:** Medium  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Introduce milestone events triggered when the player collects specific clue counts. Each milestone spawns a mini objective scene with optional challenges that yield rewards or penalties, affecting threat and resources. Escape now requires both clue threshold and final objective completion. References: PRD story (docs/game-prd.md:250-265) and architecture sections covering TurnManager, GameDirector, mini objectives (docs/architecture.md:220-320).

**Godot Implementation:** Using `TurnManager` milestone tracking, `GameDirector` state hooks, and reusable mini objective scenes in typed GDScript to deliver optional challenges  
**Performance Impact:** Low-medium; milestone checks occur at clue updates and should be constant time; mini objective scenes must recycle assets to avoid load spikes

## Acceptance Criteria
### Functional Requirements
- [ ] Clue counter triggers milestone events at configurable thresholds (e.g., 3 and 6 clues)
- [ ] Mini objective scene presents optional challenge with success/failure outcomes influencing resources/threat
- [ ] Failure consequences escalate threat or drain oxygen per configuration
- [ ] Victory sequence requires final objective completion plus clue threshold

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Milestone evaluation executes in O(1) per clue update and uses pooled objective scenes

### Game Design Requirements
- [ ] Milestone beats reinforce progress narrative and tension (docs/game-prd.md:40-95, 250-265)
- [ ] Optional challenges feel rewarding yet risky, aligning with push-your-luck theme
- [ ] Failure penalties meaningful but not run-ending without player agency

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/gameplay/mini_objective.tscn` - Generic mini objective scene with description, challenge buttons
- `res://scenes/ui/mini_objective_overlay.tscn` - Overlay presenting objective with timer (if applicable)

**New Scripts:**

- `res://scripts/autoload/milestone_service.gd` - Tracks clue thresholds and triggers objectives
- `res://scripts/gameplay/mini_objective_controller.gd` - Handles challenge logic, integrates with ResourceLedger/ThreatService
- `res://scripts/ui/mini_objective_overlay_controller.gd` - Binds UI to objective data

**New Resources (.tres):**

- `res://resources/config/milestones.tres` - Defines clue thresholds, objective scenes, rewards/penalties
- `res://resources/objectives/objective_*.tres` - Objective parameter sets (requirements, rewards)

**Modified Files:**

- `res://scripts/autoload/turn_manager.gd` - Fire milestone checks post-clue gain
- `res://scripts/autoload/game_director.gd` - Manage overlay display and final victory gating
- `res://scripts/autoload/resource_ledger.gd` - Provide API for milestone adjustments

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# milestone_service.gd
class_name MilestoneService
extends Node

@export var milestones: Array[MilestoneConfig] = []
var _completed: Dictionary = {}

signal milestone_triggered(config: MilestoneConfig)

func on_clues_updated(total_clues: int) -> void:
    for config in milestones:
        if total_clues >= config.clue_threshold and not _completed.get(config.id, false):
            _completed[config.id] = true
            milestone_triggered.emit(config)
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/MiniObjectiveOverlay`
- Scene Instancing: Overlay instanced/pool-managed when milestone triggered

**Node Dependencies:**

- `MilestoneService` - new autoload listening for clue updates
- `TurnManager` - updates clue count and triggers service
- `GameDirector` - presents overlay and handles optional/mandatory flow
- `ResourceLedger`, `ThreatService` - adjust resources based on outcomes

**Signal Connections:**

- Emits: `milestone_triggered`, `objective_completed`
- Connects to: `GameDirector` for overlay, `ResourceLedger` for effects, `ThreatService` for threat adjustments
- Cleanup: Service resets on new run; overlay returns to pool on close

**Resource Dependencies:**

- `res://resources/config/milestones.tres` - configuration (preload yes)
- `res://resources/objectives/*` - objective definitions

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_milestone_service.gd` verifying thresholds trigger once
- [ ] Create `res://tests/unit/test_mini_objective_controller.gd` verifying success/failure outcomes
- [ ] Performance test ensuring milestone check remains constant time

C# (GoDotTest):
- Not required

**GREEN Phase - Make Tests Pass:**

- [ ] Implement milestone tracking logic and objective invocation
- [ ] Implement objective controllers applying resource/threat effects
- [ ] Optimize evaluation path to satisfy performance test
- [ ] Confirm tests pass

**REFACTOR Phase - Optimize and Clean:**

- [ ] Add static typing to milestone structures
- [ ] Pool overlay scenes to reuse UI components
- [ ] Ensure objective results logged via telemetry stub
- [ ] Validate performance with profiler after repeated triggers
- [ ] Maintain coverage >=80%

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for milestones/objectives
- [ ] Implement service, overlay, and outcome handling to satisfy tests
- [ ] Refactor with typed data, pooling, telemetry logging
- [ ] Create object pool for mini objective overlay
- [ ] Implement signal connections between TurnManager, MilestoneService, GameDirector, ResourceLedger
- [ ] Profile performance (milestone check/overlay) to ensure 60 FPS
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with clue acquisition and escape gating
- [ ] Final performance validation (60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript - milestone logic integrates with existing autoload systems

**Node Architecture:**
```
RunHUD (Control)
└── MiniObjectiveOverlay (CanvasLayer)
    └── MiniObjective (Control)
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: <115 when overlay active

**Object Pooling Required:**
- Mini objective overlay: pool size 2
- Challenge buttons and VFX: pool size 4

## Game Design Context
**GDD Reference:** Epic 2, Story 2.3 (docs/game-prd.md:250-261)

**Game Mechanic:** Clue progression milestones introducing optional challenges

**Godot Implementation Approach:**
- Node Architecture: Autoload service driving overlays (docs/architecture.md:220-310)
- Language Choice: GDScript ensures consistent integration with TurnManager/ResourceLedger
- Performance Target: Milestone evaluation constant time; overlays preloaded to avoid frame drops

**Player Experience Goal:** Reinforce progress while offering high-stakes branching choices that affect the run.

**Balance Parameters (Resource-based):**

- Thresholds, rewards, penalties stored in `milestones.tres`
- Objective timers/difficulty values stored per objective resource

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_milestone_service.gd`
- `res://tests/unit/test_mini_objective_controller.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- N/A

**Test Scenarios (Write First - Red Phase):**

- Milestone triggers only once per threshold and persists across reloads - ensures constant-time evaluation
- Successful objective applies defined rewards and logs completion - signal verification
- Failed objective applies penalties correctly and escalates threat - boundary testing
- Performance test: milestone check + overlay spawn <1ms when triggered

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Collect clues to hit multiple thresholds
   - Expected: Milestones trigger overlays; once completed, no duplicate triggers
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms
   - Telemetry: Entries recorded for completion/failure

2. Fail optional objective intentionally
   - Expected: Penalty applied (threat spike/oxygen drain), overlay closes, run continues
   - Signal Flow: `objective_completed` fired with failure flag
   - Object Pools: Overlay reused without leaks

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average
- Physics frame: <2.5ms
- Memory usage: <335MB with overlays
- Draw calls: <115 when overlay active
- Object pools: Overlay/components reused
- GDScript static typing: Verified
- C# optimization: N/A
- Milestone check CPU cost: <0.2ms per clue update

## Dependencies
**Story Dependencies:**

- 1.4: Escape prompt base implementation
- 2.1: Additional room content awarding clues

**Godot System Dependencies:**

- Node: RunHUD overlay placeholder
- Autoload: `TurnManager`, `MilestoneService`, `GameDirector`, `ResourceLedger`, `TelemetryHub`
- Language: Typed GDScript pipeline

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: `milestones.tres`, `objective_*.tres`
- Location: `res://resources/config/`, `res://resources/objectives/`
- Import Settings: Text resources for diffs

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Milestone events documented for balancing reference

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript suits milestone logic integrated with TurnManager
- Node Architecture: Overlay reuse maintains UX consistency
- Signal Pattern: MilestoneService isolates logic, GameDirector handles presentation
- Consider replicating milestone data into debug overlay for QA verification

**Performance Decisions:**

- Static Typing: Milestone arrays typed for quick lookup
- C# Usage: Not necessary
- Object Pooling: Mini objective overlays and components reused
- Preload objective assets at run start to avoid mid-run loading stutter
""",

    "docs/stories/epic-2-threat-escalation-and-room-depth/2.4-push-your-luck-time-mechanics.md": """# Godot Story: Push-Your-Luck Time Mechanics

**Epic:** Threat Escalation & Room Depth  
**Story ID:** 2.4  
**Priority:** Medium  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Implement new time-management actions allowing players to discard top room cards for a time/oxygen cost, scout upcoming rooms with partial info, and visualize action costs. Telemetry must capture time spent cycling vs accepting rooms. References: PRD story (docs/game-prd.md:266-283) and architecture TurnManager/time economics sections (docs/architecture.md:110-230).

**Godot Implementation:** Using `TurnManager` action economy extensions, `RoomQueueService` integrations, and HUD `ActionChip` components in typed GDScript to manage push-your-luck options  
**Performance Impact:** Low; actions should rely on existing systems with minor UI updates, ensuring operations remain under 1ms per use

## Acceptance Criteria
### Functional Requirements
- [ ] New action consumes oxygen/time to discard current top room and draw replacement, respecting deck rules
- [ ] Scouting action reveals upcoming room metadata (tag, difficulty) without consuming draw and applies temporary modifier
- [ ] HUD clearly communicates action costs and prevents resource underflow
- [ ] Telemetry records counts and time spent on cycle/scout actions for balancing

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Action economy updates leverage pooling for UI chips and run in <0.8ms per action

### Game Design Requirements
- [ ] Time management options reinforce push-your-luck decisions (docs/game-prd.md:40-95, 266-283)
- [ ] Costs balanced to avoid trivializing tension while offering agency
- [ ] Telemetry supports validation of player usage patterns

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/ui/action_chip.tscn` - Visual representation of action buttons with cost indicators

**New Scripts:**

- `res://scripts/ui/action_chip_controller.gd` - Displays cost, handles availability logic, triggers TurnManager actions
- `res://scripts/autoload/time_economy_service.gd` - Tracks available time/oxygen actions per turn (optional helper)
- `res://scripts/services/telemetry_actions_logger.gd` - Records action usage into telemetry stub

**Modified Files:**

- `res://scripts/autoload/turn_manager.gd` - Add discard/scout actions and resource checks
- `res://scripts/autoload/room_queue_service.gd` - Implement discard and scout operations
- `res://scenes/ui/room_queue_panel.tscn` - Display new action chips and reveal preview slot
- `res://scripts/autoload/resource_ledger.gd` - Provide cost deduction helpers

**New Resources (.tres):**

- `res://resources/config/time_mechanics.tres` - Configurable costs and modifiers for actions

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# turn_manager.gd (excerpt)
func discard_top_room() -> void:
    if not _can_pay_cost(time_mechanics_config.discard_cost):
        return
    resource_ledger.apply_time_cost(time_mechanics_config.discard_cost)
    room_queue_service.discard_top_room()
    telemetry_actions_logger.log_discard()
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/RoomQueuePanel/ActionChips`
- Scene Instancing: Action chips pooled and reused based on availability

**Node Dependencies:**

- `TurnManager` - orchestrates action availability and cost payment
- `RoomQueueService` - performs discard/scout operations
- `ResourceLedger` - applies oxygen/time costs
- `TelemetryHub` - receives action metrics

**Signal Connections:**

- Emits: `action_performed(action_id)`, `scout_preview_ready(room_data)`
- Connects to: HUD chips for enabling/disabling, telemetry logger for data capture
- Cleanup: Chips disconnect in `_exit_tree()`

**Resource Dependencies:**

- `res://resources/config/time_mechanics.tres` - cost configuration (preload yes)
- `res://resources/rooms/*` - used for scouting preview data

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_turn_manager_time_actions.gd` verifying cost gating and actions
- [ ] Create `res://tests/unit/test_room_queue_scout.gd` verifying preview data
- [ ] Performance test ensuring discard/scout operations <0.8ms

C# (GoDotTest):
- Not required

**GREEN Phase - Make Tests Pass:**

- [ ] Implement cost checks and action methods in TurnManager/RoomQueueService
- [ ] Implement scouting preview data and temporary modifiers
- [ ] Optimize for minimal allocations to pass performance test
- [ ] Confirm tests pass

**REFACTOR Phase - Optimize and Clean:**

- [ ] Add static typing to action config structures
- [ ] Pool action chip UI nodes and preview overlays
- [ ] Batching telemetry submissions to avoid per-action network queues (stubbed)
- [ ] Validate performance via profiler while spamming actions
- [ ] Maintain coverage >=80%

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for discard/scout logic and preview data
- [ ] Implement TurnManager cost gating, RoomQueueService actions, HUD chips to satisfy tests
- [ ] Refactor to typed config, pooling, telemetry batching
- [ ] Create object pool for action chips and preview overlays
- [ ] Implement signal connections linking actions to telemetry and HUD state
- [ ] Profile performance (action usage) to ensure 60 FPS
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with ResourceLedger and threat escalation
- [ ] Final performance validation (60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript - aligns with existing TurnManager and HUD components

**Node Architecture:**
```
RoomQueuePanel (Control)
├── ActionChips (HBoxContainer)
│   ├── DiscardChip (Control) [pooled]
│   └── ScoutChip (Control) [pooled]
└── ScoutPreview (Control)
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: <100 for room panel with chips

**Object Pooling Required:**
- Action chips: pool size 2 per action type
- Preview overlays: pool size 1 (reused)

## Game Design Context
**GDD Reference:** Epic 2, Story 2.4 (docs/game-prd.md:266-276)

**Game Mechanic:** Time/oxygen-based push-your-luck actions for room cycling and scouting

**Godot Implementation Approach:**
- Node Architecture: TurnManager gating actions, RoomQueueService performing operations (docs/architecture.md:110-230)
- Language Choice: GDScript ensures straightforward integration with existing services
- Performance Target: Minimal overhead for action usage; maintain frame stability

**Player Experience Goal:** Provide agency over room options while preserving tension through visible costs and limited usage.

**Balance Parameters (Resource-based):**

- Costs and modifiers defined in `time_mechanics.tres`
- Telemetry thresholds stored for analytics review

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_turn_manager_time_actions.gd`
- `res://tests/unit/test_room_queue_scout.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- N/A

**Test Scenarios (Write First - Red Phase):**

- Discard action blocked when insufficient oxygen/time - ensures proper gating
- Scout preview reveals metadata without consuming card - signal verification
- Action telemetry increments counters correctly - boundary testing
- Performance test: discard + scout operations <0.8ms per invocation

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Use discard action repeatedly until oxygen low
   - Expected: Costs deducted, action disabled when insufficient resources, deck draws replacements respecting rules
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms
   - Telemetry: Entries counted via debug overlay/log

2. Use scout action to peek upcoming room
   - Expected: Preview displays limited info; temporary modifier applied when drawing scouted room
   - Signal Flow: `scout_preview_ready` fired with correct data
   - Object Pools: Action chips reused without instantiating new nodes

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average
- Physics frame: <2ms
- Memory usage: <320MB with additional UI assets
- Draw calls: <100 while chips visible
- Object pools: Chips/preview reused
- GDScript static typing: Verified
- C# optimization: N/A
- Action execution CPU cost: <0.8ms

## Dependencies
**Story Dependencies:**

- 1.3: Base room queue implementation
- 2.1: Expanded deck content for cycling/scouting

**Godot System Dependencies:**

- Node: Room queue panel with action area placeholder
- Autoload: `TurnManager`, `RoomQueueService`, `ResourceLedger`, `TelemetryHub`
- Language: Typed GDScript environment

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: `time_mechanics.tres`
- Location: `res://resources/config/time_mechanics.tres`
- Import Settings: Text resource for version control

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Telemetry validated for action usage capture

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript consistent with existing autoloads and UI controllers
- Node Architecture: Action chips as reusable Controls keep HUD lightweight
- Signal Pattern: TurnManager centralizes action signals, TelemetryHub logs usage
- Provide debug affordance to tweak costs quickly during balancing sessions

**Performance Decisions:**

- Static Typing: Config parsed into typed structs for quick access
- C# Usage: Not needed at current complexity
- Object Pooling: Action chips and preview overlays reused to prevent GC spikes
- Evaluate using `process_mode` toggles to disable chips when overlay hidden for extra savings
""",

    "docs/stories/epic-3-equipment-matrix-and-progression/3.1-equipment-matrix-ui-and-constraints.md": """# Godot Story: Equipment Matrix UI & Constraints

**Epic:** Equipment Matrix & Progression  
**Story ID:** 3.1  
**Priority:** High  
**Points:** 13  
**Status:** Draft  
**Language:** GDScript (with optional C# helper for grid packing if needed)  
**Performance Target:** 60+ FPS

## Description
Implement the grid-based equipment matrix allowing drag-and-drop placement of gear with shape constraints, rotation, burden tracking, and quick-remove actions. Build the HUD panel that integrates with dice slots and supports accessibility requirements. References: PRD story (docs/game-prd.md:284-300) and architecture sections on EquipmentController, UI component system (docs/architecture.md:120-260, 300-380).

**Godot Implementation:** Using `EquipmentController` Control scene, typed GDScript for drag/drop logic, and optional C# helper for packing heuristics if profiling demands  
**Performance Impact:** Medium; drag interactions and overlap checks must remain responsive (<150 ms), UI should pool tooltip/feedback elements to avoid GC spikes

## Acceptance Criteria
### Functional Requirements
- [ ] Equipment matrix grid supports placing/removing rotating items of varying shapes (L, 2x1, etc.)
- [ ] Invalid placements prevented with visual/audio feedback; valid placements update burden totals
- [ ] Equipped items can bind to dice slots or passives per resource metadata
- [ ] UI exposes quick-remove option without interrupting combat flow

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Drag/drop overlap checks execute under 0.8ms; feedback elements pooled

### Game Design Requirements
- [ ] Matrix supports tactical loadout planning as described in PRD (docs/game-prd.md:40-95, 284-300)
- [ ] Feedback communicates burden and slot bindings clearly for mobile
- [ ] Accessibility (text scaling, color palette) supported by Control layout

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/ui/equipment_matrix.tscn` - Grid Control containing slot cells and drop targets
- `res://scenes/ui/equipment_item_card.tscn` - Visual representation for gear pieces
- `res://scenes/ui/equipment_inventory_panel.tscn` - Panel embedding matrix, item list, burden meter

**New Scripts:**

- `res://scripts/ui/equipment_controller.gd` - Core drag/drop, placement validation, burden tracking
- `res://scripts/ui/equipment_item_card.gd` - Handles rotation, tooltip display, dice binding preview
- `res://scripts/gameplay/equipment_inventory_model.gd` - Autoload or singleton tracking equipped items, linking to dice costs
- `res://scripts/ui/equipment_feedback_service.gd` - Pools error/success cues (haptics/audio)
- Optional: `res://scripts/utils/grid_packer.cs` - C# helper to optimize packing if required

**New Resources (.tres):**

- `res://resources/equipment/module_*.tres` - Gear definitions with shape mask, dice costs, effects
- `res://resources/config/equipment_matrix.tres` - Grid dimensions, base burden, dice slot bindings

**Modified Files:**

- `res://scenes/core/run_hud.tscn` - Add equipment panel to layout
- `res://scripts/autoload/resource_ledger.gd` - Interface with burden/slot updates if necessary
- `res://scripts/autoload/turn_manager.gd` - Recognize gear activation requests

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# equipment_controller.gd
class_name EquipmentController
extends Control

@export var grid_width: int = 6
@export var grid_height: int = 4

var _cells: PackedVector2Array
var _placed_items: Array[EquipmentInstance] = []

signal gear_equipped(module: EquipmentModuleResource)
signal gear_removed(module: EquipmentModuleResource)

func try_place_item(instance: EquipmentInstance, origin_cell: Vector2i) -> bool:
    if not _fits(instance, origin_cell):
        equipment_feedback_service.show_invalid_feedback(origin_cell)
        return false
    _commit_item(instance, origin_cell)
    return true
```

**C# Implementation (for performance-critical systems):**
```csharp
// grid_packer.cs (optional)
[GlobalClass]
public partial class GridPacker : Node
{
    public bool Fits(bool[,] grid, bool[,] mask, Vector2I origin)
    {
        // No allocations, iterate with spans
        return true;
    }
}
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/EquipmentPanel`
- Scene Instancing: Equipment panel instanced and connected to EquipmentInventoryModel

**Node Dependencies:**

- `EquipmentInventoryModel` (autoload) - stores equipped modules, exposes signals for dice costs
- `ResourceLedger` - updates burden or resource adjustments
- `TurnManager` - triggers module activations
- `TelemetryHub` - logs loadout changes

**Signal Connections:**

- Emits: `gear_equipped`, `gear_removed`, `gear_activated`
- Connects to: `EquipmentInventoryModel`, `TurnManager`, `TelemetryHub`
- Cleanup: Disconnect signals and return pooled cards in `_exit_tree()`

**Resource Dependencies:**

- `res://resources/equipment/module_*.tres` - gear definitions (preload async during loading screen)
- `res://resources/config/equipment_matrix.tres` - grid configuration (preload yes)

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_equipment_controller.gd` verifying placement logic
- [ ] Create `res://tests/unit/test_equipment_inventory_model.gd` verifying persistence/binding
- [ ] Performance test ensuring placement checks <0.8ms

C# (GoDotTest):
- [ ] If `GridPacker` used, create `res://tests/unit/GridPackerTests.cs` verifying fits logic and no allocations

**GREEN Phase - Make Tests Pass:**

- [ ] Implement grid placement, rotation, removal, burden updates
- [ ] Implement inventory model storing equipped modules with dice bindings
- [ ] Optimize placement checks (precomputed masks) to satisfy performance test
- [ ] Confirm tests pass in both languages (if C# helper used)

**REFACTOR Phase - Optimize and Clean:**

- [ ] Apply static typing to item lists, grid cells
- [ ] Pool equipment item cards and feedback cues
- [ ] Ensure cross-device drag thresholds tuned for mobile
- [ ] Validate performance with profiler while dragging multiple items
- [ ] Maintain >=80% coverage

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for equipment controller and inventory model (plus GoDotTest if grid helper used)
- [ ] Implement matrix UI, placement validation, burden tracking to satisfy tests
- [ ] Refactor with typed structures, pooling, optional C# optimization
- [ ] Create object pool for equipment item cards and feedback effects
- [ ] Implement signal connections with inventory model, TurnManager, telemetry
- [ ] Profile performance to ensure 60+ FPS during drag/drop
- [ ] Language optimization (GDScript static typing, optional C# no-LINQ)
- [ ] Integration testing with ResourceLedger and dice tray bindings
- [ ] Final performance validation (60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript (C# optional) - maintain single-language focus but allow micro-optimization

**Node Architecture:**
```
EquipmentPanel (Control)
├── MatrixGrid (GridContainer)
│   └── MatrixCell (Control) x N
├── ItemList (ScrollContainer)
└── BurdenMeter (Control)
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: <140 when matrix expanded

**Object Pooling Required:**
- Equipment item cards: pool size 12 (matching starting gear + stash)
- Feedback cues (audio/text): pool size 4

## Game Design Context
**GDD Reference:** Epic 3, Story 3.1 (docs/game-prd.md:284-292)

**Game Mechanic:** Resident Evil-style inventory puzzle enabling spatial loadout planning

**Godot Implementation Approach:**
- Node Architecture: Control nodes with drag/drop handling (docs/architecture.md:230-340)
- Language Choice: GDScript for core logic; optional C# helper if profiling indicates need
- Performance Target: Keep drag operations responsive and avoid UI stutter on mobile

**Player Experience Goal:** Deliver tactile, readable inventory management on touch devices with clear feedback.

**Balance Parameters (Resource-based):**

- Grid size, burden thresholds defined in `equipment_matrix.tres`
- Dice slot bindings per module stored in module resources

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_equipment_controller.gd`
- `res://tests/unit/test_equipment_inventory_model.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- `res://tests/unit/GridPackerTests.cs` (only if helper used)

**Test Scenarios (Write First - Red Phase):**

- Placement fails when overlap occurs; success when valid - ensures integrity and performance
- Rotation updates mask boundaries correctly - signal verification
- Equipped gear updates dice binding signals and burden meter - boundary testing
- Performance test: drag/validate cycle <0.8ms processing cost

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Drag varied shapes around matrix with rotation
   - Expected: Valid placements snap, invalid placements show feedback; burden meter updates
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms even during rapid dragging
   - Accessibility: Text scaling support verified

2. Equip item bound to dice slot and activate in combat
   - Expected: Dice tray highlights binding; activation consumes dice and triggers placeholder effect
   - Signal Flow: `gear_equipped` -> `TurnManager` -> `ResourceLedger` updates
   - Object Pools: Cards reused when removing/adding gear

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average
- Physics frame: <2ms (UI heavy)
- Memory usage: <360MB with gear assets
- Draw calls: <140 when matrix visible
- Object pools: Item cards and feedback reusing properly
- GDScript static typing: Verified
- C# optimization: No LINQ/no allocations if helper used
- Drag validation CPU cost: <0.8ms

## Dependencies
**Story Dependencies:**

- 1.x: Dice loop and ResourceLedger foundation
- 2.x: Additional room equipment rewards coming later (3.2)

**Godot System Dependencies:**

- Node: RunHUD needs equipment panel placeholder
- Autoload: `EquipmentInventoryModel`, `TurnManager`, `ResourceLedger`, `TelemetryHub`
- Language: Typed GDScript baseline; optional C# integration pipeline ready

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: Module definitions, matrix config
- Location: `res://resources/equipment/`, `res://resources/config/`
- Import Settings: Text resources for diff-friendly editing

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (if helper used)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (if used)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- UX reviewed for readability on mobile resolutions

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript primary; evaluate C# helper only if profiling indicates need
- Node Architecture: GridContainer ensures responsive layout with theme scaling
- Signal Pattern: Equipment controller communicates through inventory model and TurnManager
- Provide debug overlay for placement grid to aid QA and tuning

**Performance Decisions:**

- Static Typing: Use typed arrays for cells and equipment instances
- C# Usage: Optional micro-optimization; ensure no allocations if adopted
- Object Pooling: Gear cards, feedback cues, and tooltips pooled
- Avoid per-drag instantiation by reusing drag ghost nodes and highlight overlays
""",

    "docs/stories/epic-3-equipment-matrix-and-progression/3.2-loot-generation-and-gear-effects.md": """# Godot Story: Loot Generation & Gear Effects

**Epic:** Equipment Matrix & Progression  
**Story ID:** 3.2  
**Priority:** High  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Implement loot generation tying gear drops to room/threat types and progression depth. Ensure equipped items consume dice to trigger effects (damage, conversion, resources) with cooldowns and rarities. Provide distinct visuals for rare items. References: PRD story (docs/game-prd.md:300-314) and architecture sections on EquipmentController, Resource-driven content (docs/architecture.md:120-320, 360-410).

**Godot Implementation:** Using `LootTableResource`, `EquipmentInventoryModel`, and `EquipmentController` integrations in typed GDScript to deliver rewarding gear drops  
**Performance Impact:** Medium; loot rolls should be data-driven and cached to avoid runtime overhead; activation effects must reuse pooled nodes

## Acceptance Criteria
### Functional Requirements
- [ ] Loot tables tie drops to room/threat tags and run depth (early/late tiers)
- [ ] Gear items define dice costs, effects, and cooldowns; consuming dice updates exhaust pool immediately
- [ ] Rare items introduce unique symbols/visuals distinct from commons
- [ ] Gear activation resolves instantly and updates ResourceLedger/ThreatService as appropriate

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Loot generation executes <1ms per drop (preloaded tables) and activation effects pooled

### Game Design Requirements
- [ ] Loot supports varied builds and tactical options (docs/game-prd.md:40-95, 300-314)
- [ ] Rarity visuals communicate value and support progression fantasy
- [ ] Dice consumption integrates with push-your-luck cadence

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/ui/loot_drop_popup.tscn` - Displays drop summary and rarity flair
- `res://scenes/fx/gear_activation_vfx.tscn` - Pooled effect for gear usage

**New Scripts:**

- `res://scripts/resources/loot_table_resource.gd` - Defines drop weights per tag/depth
- `res://scripts/services/loot_service.gd` - Autoload or utility generating loot from tables
- `res://scripts/gameplay/gear_activation_system.gd` - Resolves dice costs, cooldowns, and effects
- `res://scripts/ui/loot_drop_popup_controller.gd` - Presents drop info and handles auto-add option

**New Resources (.tres):**

- `res://resources/loot/loot_table_room.tres`, `loot_table_threat.tres`
- `res://resources/equipment/module_*.tres` - updated to include rarity, cooldown, effect definitions
- `res://resources/fx/gear_activation_vfx.tres`

**Modified Files:**

- `res://scripts/autoload/room_queue_service.gd` - Spawn loot post-exploration (where applicable)
- `res://scripts/autoload/threat_service.gd` - Trigger loot on threat defeat
- `res://scripts/ui/equipment_controller.gd` - Hook activation logic and cooldown states

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# loot_service.gd
class_name LootService
extends Node

@export var room_loot_table: LootTableResource
@export var threat_loot_table: LootTableResource

func roll_loot(context: LootContext) -> Array[EquipmentModuleResource]:
    var table := context.is_threat ? threat_loot_table : room_loot_table
    return table.pick_modules(context)
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/LootPopup`
- Scene Instancing: Loot popup pooled, gear activation VFX pooled under `fx/`

**Node Dependencies:**

- `LootService` - provides drop results
- `EquipmentInventoryModel` - stores new gear
- `EquipmentController` - displays and binds items
- `TurnManager` - handles activation requests & dice spending
- `ResourceLedger`, `ThreatService` - apply effects from gear

**Signal Connections:**

- Emits: `loot_awarded`, `gear_activated`, `cooldown_updated`
- Connects to: Equipment controller, HUD, telemetry logging
- Cleanup: Cooldown timers disconnected on gear removal; VFX returned to pool

**Resource Dependencies:**

- `res://resources/loot/*.tres` - loot tables
- `res://resources/equipment/module_*.tres` - gear metadata
- `res://resources/fx/gear_activation_vfx.tres` - effect resource

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_loot_service.gd` verifying tag/depth weighting
- [ ] Create `res://tests/unit/test_gear_activation_system.gd` verifying dice cost consumption & cooldowns
- [ ] Performance test ensuring loot roll <1ms with preloaded tables

C# (GoDotTest):
- Not required

**GREEN Phase - Make Tests Pass:**

- [ ] Implement loot service picking modules per tables
- [ ] Implement activation system applying effects, managing cooldown timers
- [ ] Optimize data structures (precomputed arrays) to pass performance test
- [ ] Ensure tests pass

**REFACTOR Phase - Optimize and Clean:**

- [ ] Add static typing across loot/gear systems
- [ ] Pool VFX/audio for gear activation and loot popups
- [ ] Ensure dice consumption integrated with TurnManager/ResourceLedger
- [ ] Validate performance in profiler while spamming activations
- [ ] Maintain coverage >=80%

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for loot service and gear activation
- [ ] Implement loot generation, gear effects, cooldowns to satisfy tests
- [ ] Refactor with typed data, pooling, telemetry integration
- [ ] Create object pool for loot popup and gear activation VFX
- [ ] Implement signal connections linking loot, equipment, TurnManager, telemetry
- [ ] Profile performance to ensure 60+ FPS when activating gear
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with room/threat rewards and equipment matrix
- [ ] Final performance validation (60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript - suits data-driven loot/gear logic alongside existing systems

**Node Architecture:**
```
RunHUD (Control)
└── LootPopup (CanvasLayer)
    └── LootSummary (Control)

EquipmentController (Control)
└── ActivationEffects (Node)
    └── GearActivationVFX (GPUParticles3D) [pooled]
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: <150 when loot popup + VFX active

**Object Pooling Required:**
- Loot popup nodes: pool size 2
- Activation VFX/audio: pool size 4

## Game Design Context
**GDD Reference:** Epic 3, Story 3.2 (docs/game-prd.md:300-308)

**Game Mechanic:** Gear acquisition altering tactics and dice usage

**Godot Implementation Approach:**
- Node Architecture: Resource-based loot, pooled UI & VFX (docs/architecture.md:240-360)
- Language Choice: GDScript ensures integration with autoload services
- Performance Target: Keep loot rolls/gear activations under 1ms CPU

**Player Experience Goal:** Reward exploration/combat with meaningful gear, reinforcing dice economy choices.

**Balance Parameters (Resource-based):**

- Drop weights per tag stored in `loot_table_*.tres`
- Cooldown durations, dice costs exported per module resource

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_loot_service.gd`
- `res://tests/unit/test_gear_activation_system.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- N/A

**Test Scenarios (Write First - Red Phase):**

- Loot roll respects tag weights and depth thresholds - ensures data-driven fairness
- Activation consumes dice, updates exhaust pool, enforces cooldown - signal verification
- Rare item visuals flagged for UI to differentiate - boundary testing
- Performance test: loot roll + activation effect <16.67ms total, <1ms CPU each

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Defeat threat and observe loot drop
   - Expected: Popup shows gear with rarity flair, auto-add to stash, telemetry entry created
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms during drop animation
   - Object Pools: Popup reused

2. Activate gear with dice cost during combat
   - Expected: Dice consumed, exhaust tray updates, effect plays with pooled VFX
   - Signal Flow: `gear_activated` -> `TurnManager` -> `ResourceLedger`
   - Cooldown: Gear temporarily unavailable and re-enabled after timer

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average
- Physics frame: <3ms
- Memory usage: <370MB with loot assets loaded
- Draw calls: <150 with popup/VFX active
- Object pools: Popups/VFX reused without spikes
- GDScript static typing: Verified
- C# optimization: N/A
- Loot roll CPU cost: <1ms

## Dependencies
**Story Dependencies:**

- 3.1: Equipment matrix to house gear
- 2.x: Room/threat content awarding loot

**Godot System Dependencies:**

- Node: Equipment panel, loot popup placeholder
- Autoload: `LootService`, `EquipmentInventoryModel`, `TurnManager`, `ResourceLedger`, `TelemetryHub`
- Language: Typed GDScript pipeline

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: Loot tables, module definitions, activation VFX
- Location: `res://resources/loot/`, `res://resources/equipment/`, `res://resources/fx/`
- Import Settings: Text resources for gear/loot; binary for VFX if needed

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Loot telemetry validated for balancing metrics

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript leverages existing service patterns; no need for C# micro-optimization yet
- Node Architecture: Loot service decoupled for reuse by multiple systems, popup overlay matches existing UI style
- Signal Pattern: LootService emits results, EquipmentInventoryModel handles storage
- Consider synergy with remote config (Story 4.4) for balancing in future

**Performance Decisions:**

- Static Typing: Precompute arrays and typed dictionaries for drop tables
- C# Usage: Not required now; revisit if profiling indicates
- Object Pooling: Popups, VFX, and activation audio pooled
- Preload loot tables at game boot to avoid runtime loading cost
""",

    "docs/stories/epic-3-equipment-matrix-and-progression/3.3-experience-and-level-up-choices.md": """# Godot Story: Experience & Level-Up Choices

**Epic:** Equipment Matrix & Progression  
**Story ID:** 3.3  
**Priority:** Medium  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Create the XP system that tallies rewards from threats/objectives and offers level-up nodes with at least three upgrade options (new die, symbol modifier, passive perk). Upgrades modify the dice tray immediately and persist via saves. Provide reject option with banked XP logic. References: PRD story (docs/game-prd.md:315-329) and architecture sections covering ResourceLedger, SaveService, dice subsystem (docs/architecture.md:80-220, 320-360).

**Godot Implementation:** Using `ResourceLedger` XP extension, `LevelUpService`, and `DiceSubsystem` integration in typed GDScript to update dice pools and persistence  
**Performance Impact:** Low-medium; level-up overlays and dice modifications must avoid reloading scenes; XP calculations executed on event triggers

## Acceptance Criteria
### Functional Requirements
- [ ] XP accumulates from configured sources (threat defeats, objectives) and triggers level-up when thresholds reached
- [ ] Level-up UI presents ≥3 upgrade choices (new die, symbol modifier, passive perk)
- [ ] Selected upgrade immediately updates dice tray and persists via SaveService
- [ ] Reject option banks level for later with minor resource cost per PRD

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Level-up overlay operations execute <1ms per choice selection and reuse pooled components

### Game Design Requirements
- [ ] Upgrade options align with build diversity goals (docs/game-prd.md:40-95, 315-329)
- [ ] Dice tray updates maintain clarity and update exhaust pool appropriately
- [ ] Reject option imposes cost but preserves agency

## Technical Specifications
### Files to Create/Modify
**New Scenes (.tscn):**

- `res://scenes/ui/level_up_overlay.tscn` - Overlay presenting upgrades and bank option
- `res://scenes/ui/upgrade_card.tscn` - Visual card for each upgrade choice

**New Scripts:**

- `res://scripts/services/level_up_service.gd` - Tracks XP thresholds, manages upgrade selection
- `res://scripts/ui/level_up_overlay_controller.gd` - Handles UI, selection logic, cost enforcement
- `res://scripts/resources/upgrade_option_resource.gd` - Describes upgrade effects
- `res://scripts/gameplay/dice_upgrade_system.gd` - Applies dice/tray changes to `DiceSubsystem`

**Modified Files:**

- `res://scripts/autoload/resource_ledger.gd` - Add XP field and signals
- `res://scripts/autoload/turn_manager.gd` - Award XP from combat/objectives
- `res://scripts/autoload/save_service.gd` - Persist XP and upgrade selections
- `res://scripts/gameplay/dice_subsystem.gd` - Support dynamic dice additions/modifiers

**New Resources (.tres):**

- `res://resources/config/level_up_curve.tres` - XP thresholds and costs
- `res://resources/upgrades/upgrade_*.tres` - Upgrade definitions for nodes

### Node/Class Definitions
**GDScript Implementation (for game logic):**
```gdscript
# level_up_service.gd
class_name LevelUpService
extends Node

@export var level_up_curve: LevelUpCurveResource
var _xp: int = 0
var _pending_levels: int = 0

signal level_up_ready(options: Array[UpgradeOptionResource])
signal upgrade_selected(option: UpgradeOptionResource)

func add_xp(amount: int) -> void:
    _xp += amount
    while _xp >= level_up_curve.get_xp_for_level(current_level + _pending_levels + 1):
        _pending_levels += 1
        level_up_ready.emit(_generate_options())
```

### Integration Points
**Scene Tree Integration:**

- Parent Scene: `res://scenes/core/run_hud.tscn`
- Node Path: `/root/GameRoot/RunHUD/LevelUpOverlay`
- Scene Instancing: Overlay pooled; upgrade cards instanced from pool

**Node Dependencies:**

- `LevelUpService` - new autoload hooking ResourceLedger and TurnManager events
- `DiceSubsystem` - updates dice pool when upgrade applied
- `ResourceLedger` - stores XP and handles reject cost
- `SaveService` - persists XP and applied upgrades
- `TelemetryHub` - logs upgrade choices

**Signal Connections:**

- Emits: `level_up_ready`, `upgrade_selected`, `upgrade_declined`
- Connects to: Overlay controller for UI, DiceSubsystem for updates, TelemetryHub for logging
- Cleanup: Reset pending levels on new run; overlay returns to pool

**Resource Dependencies:**

- `res://resources/config/level_up_curve.tres` - thresholds/costs (preload yes)
- `res://resources/upgrades/upgrade_catalog.tres` - available upgrades (preload yes)

## TDD Workflow (Red-Green-Refactor)
**RED Phase - Write Failing Tests First:**

GDScript (GUT):
- [ ] Create `res://tests/unit/test_level_up_service.gd` verifying XP accumulation and options generation
- [ ] Create `res://tests/unit/test_dice_upgrade_system.gd` verifying dice tray updates and persistence
- [ ] Performance test ensuring overlay selection <1ms CPU

C# (GoDotTest):
- Not required

**GREEN Phase - Make Tests Pass:**

- [ ] Implement XP tracking and level-up option generation
- [ ] Implement dice upgrade system modifying SubViewport dice resources
- [ ] Optimize overlay selection logic to satisfy performance test
- [ ] Ensure tests pass

**REFACTOR Phase - Optimize and Clean:**

- [ ] Add static typing across services and upgrade resources
- [ ] Pool overlay and upgrade cards
- [ ] Ensure SaveService persists upgrades and handles migrations
- [ ] Validate performance and memory under repeated upgrades
- [ ] Maintain coverage >=80%

## Implementation Tasks
**TDD Tasks (Red-Green-Refactor):**

- [ ] Write GUT tests for level-up service and dice upgrade system
- [ ] Implement XP accrual, upgrade UI, dice modifications to satisfy tests
- [ ] Refactor using typed structures, pooling, telemetry logging
- [ ] Create object pool for upgrade cards and overlay
- [ ] Implement signal connections among LevelUpService, DiceSubsystem, SaveService
- [ ] Profile performance to ensure 60+ FPS during overlay usage
- [ ] Language optimization (GDScript static typing)
- [ ] Integration testing with threat/objective XP sources and equipment synergy
- [ ] Final performance validation (60+ FPS)

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
**Engine Version:** Godot 4.5  
**Renderer:** Forward+  
**Primary Language:** GDScript - ensures consistent integration with existing systems

**Node Architecture:**
```
RunHUD (Control)
└── LevelUpOverlay (CanvasLayer)
    ├── UpgradeList (VBoxContainer)
    │   └── UpgradeCard (Control) [pooled]
    └── RejectButton (Button)
```

**Performance Requirements:**
- Target FPS: 60+
- Frame Budget: 16.67ms
- Memory Budget: 450MB
- Draw Calls: <130 when overlay active

**Object Pooling Required:**
- Upgrade cards: pool size 6 (three options + buffer)
- Overlay: pool size 1 reused

## Game Design Context
**GDD Reference:** Epic 3, Story 3.3 (docs/game-prd.md:315-323)

**Game Mechanic:** XP-based progression with customizable upgrade choices

**Godot Implementation Approach:**
- Node Architecture: Autoload service driving overlay UI (docs/architecture.md:250-360)
- Language Choice: GDScript to interact with ResourceLedger, SaveService, DiceSubsystem
- Performance Target: Overlay updates minimal; maintain frame consistency

**Player Experience Goal:** Offer meaningful build-defining choices with immediate feedback and persistence.

**Balance Parameters (Resource-based):**

- XP thresholds, reject cost stored in `level_up_curve.tres`
- Upgrade effects defined in `upgrade_*.tres`

## Testing Requirements
### Unit Tests (TDD Mandatory)
**GUT Test Files (GDScript):**

- `res://tests/unit/test_level_up_service.gd`
- `res://tests/unit/test_dice_upgrade_system.gd`
- Coverage Target: 80%

**GoDotTest Files (C#):**

- N/A

**Test Scenarios (Write First - Red Phase):**

- XP accumulation triggers pending levels correctly - ensures data integrity
- Selecting upgrade modifies dice tray (additional die/symbol) and persists - signal verification
- Reject option banks level and deducts cost once - boundary testing
- Performance test: overlay selection logic <1ms CPU, frame time <16.67ms

### Game Testing
**Manual Test Cases (Godot Editor):**

1. Earn XP through threat defeat to trigger level-up
   - Expected: Overlay appears with three distinct upgrades; selection updates dice tray and saves state
   - Performance: 60+ FPS maintained
   - Profiler: Frame time <16.67ms
   - Save/Load: Reload project to confirm upgrade persisted

2. Reject upgrade to bank for later
   - Expected: XP banked, resource penalty applied, overlay closes; next trigger shows updated options
   - Signal Flow: `upgrade_declined` fired with cost details
   - Object Pools: Overlay/cards reused

### Performance Tests
**Godot Profiler Metrics (Mandatory):**

- Frame rate: 60+
- Frame time: <16.67ms average
- Physics frame: <2ms (UI heavy)
- Memory usage: <340MB with overlay assets
- Draw calls: <130 with overlay active
- Object pools: Upgrade cards reused without churn
- GDScript static typing: Verified
- C# optimization: N/A
- Upgrade application CPU cost: <1ms

## Dependencies
**Story Dependencies:**

- 3.1 & 3.2: Equipment matrix and loot integration provide gear synergy
- 2.3: Mini objectives may award XP

**Godot System Dependencies:**

- Node: Level-up overlay placeholder in RunHUD
- Autoload: `LevelUpService`, `ResourceLedger`, `SaveService`, `DiceSubsystem`, `TelemetryHub`
- Language: Typed GDScript pipeline

**Resource Dependencies:**

- Resource Type: `.tres`
- Asset: `level_up_curve.tres`, `upgrade_*.tres`
- Location: `res://resources/config/`, `res://resources/upgrades/`
- Import Settings: Text resources for diff-friendly editing

## Definition of Done
- All acceptance criteria met
- TDD followed (tests written first, then implementation)
- GUT tests passing (GDScript) with 80%+ coverage
- GoDotTest passing (C#) with 80%+ coverage (N/A)
- Performance: 60+ FPS maintained on all platforms
- Static typing used in all GDScript
- C# optimized (no LINQ in hot paths) (N/A)
- Object pooling active for spawned entities
- Signals properly connected and cleaned up
- No GDScript or C# errors/warnings
- Node hierarchy follows architecture
- Resources (.tres) configured properly
- Export templates tested
- Documentation updated
- Upgrade choices logged for telemetry analysis

## Notes
**Godot Implementation Notes:**

- Language Choice: GDScript ensures easy integration across autoload services
- Node Architecture: Overlay design consistent with other modals, supporting text scaling
- Signal Pattern: LevelUpService centralizes logic, overlay purely presentational
- Provide debug console commands to grant XP for QA testing

**Performance Decisions:**

- Static Typing: XP values ints, upgrade arrays typed to resources
- C# Usage: Not required
- Object Pooling: Overlay/cards reused, dice modifications operate on preloaded resources
- Prefetch upgrade resources to avoid runtime loads when overlay appears
""",

    "docs/stories/epic-3-equipment-matrix-and-progression/3.4-meta-progression-and-unlocks.md": """# Godot Story: Meta Progression & Unlocks

**Epic:** Equipment Matrix & Progression  
**Story ID:** 3.4  
**Priority:** Medium  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Implement the meta progression layer that records run outcomes, grants unlocks (rooms, threats, equipment), and exposes a codex with lore/stat tracking. Provide a profile-aware meta screen showing unlock dependencies plus a codex detail view. References: docs/game-prd.md:330-344 and docs/architecture.md:240-360, 400-460.

**Godot Implementation:** `MetaProgressService` autoload + `SaveService` persistence + `CodexController` UI in typed GDScript for replay incentives  
**Performance Impact:** Low-medium; evaluation happens post-run and meta screens must stay responsive on mobile

## Acceptance Criteria
### Functional Requirements
- [ ] Completing a run writes a run summary and awards unlocks defined in `unlock_tree.tres`
- [ ] Meta screen renders unlock tree with prerequisites, current status, and highlights new unlocks
- [ ] Codex lists discovered threats/rooms/equipment with lore snippets and stats; locked entries hidden
- [ ] Profile selector supports at least two local profiles with independent progress/reset

### Technical Requirements
- Code follows GDScript/C# best practices with static typing
- Maintains 60+ FPS on all target devices (frame time <16.67ms)
- Object pooling implemented for spawned entities
- Signals properly connected and cleaned up
- GUT/GoDotTest coverage >= 80%
- [ ] Unlock evaluation executes <0.5ms per run; tree/codex reuse pooled nodes to avoid allocations

### Game Design Requirements
- [ ] Unlock cadence matches PRD replay goals
- [ ] Codex tone aligns with sci-fi horror theme and supports accessibility (scalable fonts)
- [ ] Profiles can be reset independently for QA/beta without touching other data

## Technical Specifications
- Scenes: `meta_progress_screen.tscn`, `codex_panel.tscn`
- Scripts: `meta_progress_service.gd`, `meta_progress_screen_controller.gd`, `codex_controller.gd`, `profile_manager.gd`
- Resources: `unlock_tree.tres`, `codex` entries
- Modified: `post_run_summary_controller.gd`, `save_service.gd`, `game_director.gd`

## TDD Workflow (Red-Green-Refactor)
- RED: tests for MetaProgressService evaluation/persistence, ProfileManager isolation, CodexController rendering
- GREEN: implement evaluation logic, profile storage, pooled UI nodes
- REFACTOR: enforce static typing, pooling, SaveService schema versioning

## Implementation Tasks
- [ ] Write unit tests (RED)
- [ ] Implement meta progression service/profile manager/codex UI (GREEN)
- [ ] Refactor for typed data, pooling, telemetry logging (REFACTOR)
- [ ] Integration testing with post-run summary and SaveService persistence
- [ ] Profile meta screen to ensure 60+ FPS and evaluation <0.5ms

**Debug Log:**
| Task | File | Change | Reverted? |
|------|------|--------|-----------|
| | | | |

**Completion Notes:**

**Change Log:**

## Godot Technical Context
- Engine: Godot 4.5 Forward+
- Primary language: GDScript
- Node architecture: pooled unlock/codex entries per docs/architecture.md:320-420
- Performance: 60 FPS; draw calls <140 in meta screens; memory <360MB with meta assets

## Game Design Context
- Replay incentives via unlocks/codex (PRD Epic 3 Story 3.4)

## Testing Requirements
- Unit tests + manual scenarios: grant unlocks, switch profiles, browse codex
- Performance capture via profiler when navigating meta/codex

## Dependencies
- Depends on Stories 3.2/3.3 for unlock data; integrates with Story 1.4 post-run summary

## Definition of Done
- Acceptance criteria met; tests passing; telemetry/export updated; documentation refreshed

## Notes
- Provide dev tools to grant/reset unlocks for QA
- Plan future cloud sync integration but keep stubbed behind flag
""",

    "docs/stories/epic-4-atmosphere-ux-polish-and-live-ops-hooks/4.1-visual-and-audio-atmosphere-pass.md": """# Godot Story: Visual & Audio Atmosphere Pass

**Epic:** Atmosphere, UX Polish & Live Ops Hooks  
**Story ID:** 4.1  
**Priority:** Medium  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript (plus shaders/resources)  
**Performance Target:** 60+ FPS

## Description
Add ambient particle/lighting effects, tiered graphics settings, and dynamic soundtrack transitions responding to the threat meter while preserving HUD clarity. References: docs/game-prd.md:345-360 and docs/architecture.md:280-380.

**Godot Implementation:** `RenderSettingsService`, `AmbientEffectsController`, and `ThreatMusicController` in typed GDScript with pooled resources  
**Performance Impact:** High; requires tier degradation and profiling to maintain frame budget

## Acceptance Criteria
- [ ] Ambient effects toggle per tier (Performance/Balanced/Atmosphere) with persistence
- [ ] Threat meter states trigger music layer transitions (`Calm`, `Alert`, `Critical`)
- [ ] Graphics settings panel provides live preview and logs telemetry
- [ ] Dice/HUD elements remain legible under all tiers (contrast check)

## Technical Specifications
- Scenes: `ambient_effects.tscn`, `graphics_settings_panel.tscn`
- Scripts: `render_settings_service.gd`, `graphics_settings_panel.gd`, `threat_music_controller.gd`, `ambient_effects_controller.gd`
- Resources: renderer presets, particle presets, music layers, shaders
- Modified: `project.godot`, `run_hud.tscn`, threat/resource autoloads for state signals

## TDD Workflow
- RED: tests for tier switching/persistence + music controller + perf stub
- GREEN: implement tier toggle, audio layering, effect pooling
- REFACTOR: typed tier data, pooling, telemetry logging, CI perf baseline

## Implementation Tasks
- [ ] Write unit tests
- [ ] Implement tier toggles + audio/effect controllers
- [ ] Refactor with typed dicts, pooling, ConfigFile persistence
- [ ] Profile GPU/CPU across tiers to ensure 60+ FPS

**Debug Log:** Table placeholder

## Definition of Done
- Acceptance criteria satisfied; tests and perf checks passing; docs updated with tier guidance
""",

    "docs/stories/epic-4-atmosphere-ux-polish-and-live-ops-hooks/4.2-onboarding-and-tutorials.md": """# Godot Story: Onboarding & Tutorials

**Epic:** Atmosphere, UX Polish & Live Ops Hooks  
**Story ID:** 4.2  
**Priority:** Medium  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Deliver contextual tutorials for the first run with skip/next controls, persistent completion state, and codex “Learn More” unlocks. References: docs/game-prd.md:361-378 and docs/architecture.md:150-260, 340-380.

**Godot Implementation:** `TutorialService` autoload orchestrating prompt overlays, highlight masks, and telemetry logging in typed GDScript  
**Performance Impact:** Low; overlays should reuse pooled nodes (<0.5ms update)

## Acceptance Criteria
- [ ] Tutorial steps trigger (dice loop, rooms, threats) during first run
- [ ] Prompts support skip/next and completion persists per profile
- [ ] Codex “Learn More” entries unlock when related tutorial completes
- [ ] Analytics events fire for tutorial start/completion/skip/drop-off

## Technical Specifications
- Scenes: `tutorial_prompt.tscn`, `tutorial_highlight_mask.tscn`
- Scripts: `tutorial_service.gd`, `tutorial_prompt_controller.gd`, `tutorial_highlight_controller.gd`, `tutorial_state_repository.gd`
- Resources: `tutorial_flow.tres`, codex entries
- Modified: `game_director.gd`, `run_hud_controller.gd`, telemetry logger

## TDD Workflow
- RED: tests for TutorialService & PromptController
- GREEN: implement flow, overlays, telemetry hooks
- REFACTOR: typed data, pooling, persistence

## Definition of Done
- Acceptance criteria met; tests passing; analytics dashboards updated; documentation refreshed
""",

    "docs/stories/epic-4-atmosphere-ux-polish-and-live-ops-hooks/4.3-accessibility-and-ux-refinements.md": """# Godot Story: Accessibility & UX Refinements

**Epic:** Atmosphere, UX Polish & Live Ops Hooks  
**Story ID:** 4.3  
**Priority:** Medium  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Add accessibility settings (text scaling, color palettes, vibration toggle, simplified controls, captions) and polish HUD layouts to avoid overlap under larger fonts. References: docs/game-prd.md:379-397 and docs/architecture.md:280-360.

**Godot Implementation:** `AccessibilityService` autoload + themed Control layouts + caption overlay in typed GDScript  
**Performance Impact:** Low; settings updates must be lightweight (<0.5ms)

## Acceptance Criteria
- [ ] Settings panel exposes text scale, color palettes, vibration toggle, simplified controls, captions toggle
- [ ] HUD adapts to larger fonts without clipping critical info
- [ ] Audio cues display captions when enabled
- [ ] UX heuristics review items addressed and documented

## Technical Specifications
- Scenes: `accessibility_settings_panel.tscn`, `caption_overlay.tscn`
- Scripts: `accessibility_service.gd`, `accessibility_settings_controller.gd`, `caption_overlay_controller.gd`, `haptics_service.gd`
- Resources: theme variants, scaled fonts, caption catalog
- Modified: `run_hud_controller.gd`, `audio_director.gd`, `project.godot`

## Definition of Done
- Acceptance criteria satisfied; tests + heuristics checklist complete; documentation updated
""",

    "docs/stories/epic-4-atmosphere-ux-polish-and-live-ops-hooks/4.4-analytics-and-live-ops-foundations.md": """# Godot Story: Analytics & Live Ops Foundations

**Epic:** Atmosphere, UX Polish & Live Ops Hooks  
**Story ID:** 4.4  
**Priority:** Medium  
**Points:** 8  
**Status:** Draft  
**Language:** GDScript  
**Performance Target:** 60+ FPS

## Description
Integrate analytics batching, remote config scaffolding, Sentry crash breadcrumbs, and a live-ops export script to support soft-launch instrumentation. References: docs/game-prd.md:398-416 and docs/architecture.md:240-430.

**Godot Implementation:** Extend `TelemetryHub`, add `RemoteConfigService` & `SentryBridge` autoloads, plus exporter utility in typed GDScript  
**Performance Impact:** Medium; telemetry tick must stay under 0.5ms and remote config fetch async

## Acceptance Criteria
- [ ] Telemetry batching with offline queue flushes every 10 events/15s
- [ ] Remote config fetch applies balancing parameters with fallback defaults
- [ ] Sentry crash/error reporting includes gameplay breadcrumbs and respects opt-in
- [ ] Live-ops exporter outputs aggregated JSON/CSV snapshot

## Technical Specifications
- Scripts: `telemetry_hub.gd` (extended), `remote_config_service.gd`, `sentry_bridge.gd`, `live_ops_exporter.gd`
- Resources: `remote_config_defaults.tres`, `event_schema.tres`
- Modified: `project.godot`, `game_director.gd`, gameplay systems emitting events

## Definition of Done
- Acceptance criteria met; tests passing; telemetry dashboards receiving data; documentation updated with schema/opt-in notes
""",

}

def main() -> None:
    for rel_path, content in STORY_CONTENT.items():
        file_path = Path(rel_path)
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content)
    print(f"Wrote {len(STORY_CONTENT)} stories.")

if __name__ == "__main__":
    main()
