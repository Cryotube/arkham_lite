# Bermuda Sector Backlog

This backlog translates the Bermuda Sector PRD and architecture into actionable epics and stories ready for Game Scrum Master execution. All stories assume statically typed GDScript, 60 FPS targets, and mobile-first UX as defined in `docs/architecture.md`.

## Epic 1: Crash Survivor Foundation
**Goal:** Deliver a playable end-to-end slice covering dice loop, resources, and a minimal escape run.

### Story 1.1 Godot Project Spine & Dice Loop Skeleton — Status: Draft
- **Acceptance Criteria**
  1. Scene boots into playable dice tray with roll, lock, exhaust phases.
  2. Strength/Intellect/Agility dice refresh automatically after confirm.
  3. Exhausted dice visually park in separate pool with shader highlight.
  4. Basic touch controls (tap, drag) operate dice without errors.
- **Technical Notes**
  - Leverage `TurnManager` and `DiceSubsystem` patterns (`docs/architecture.md`, TurnManager System, DiceSubsystem sections).
  - Configure InputMap actions `roll_dice`, `lock_die`, `confirm_action` (Input System Architecture).
  - Implement 3D dice in SubViewport with pooling per Physics Configuration.
- **Dependencies**: None.

### Story 1.2 Core Resources & HUD Feedback — Status: Draft
- **Acceptance Criteria**
  1. HUD shows health, materials, oxygen, threat meter with numeric values.
  2. Dice and scripted events change resources with instant UI feedback.
  3. Threat meter triggers warning states (yellow/red) with audio cue.
  4. Resource state persists through scene reload via provisional save.
- **Technical Notes**
  - Follow `ResourceLedger` and `HUDController` specs (ResourceLedger, HUDController sections).
  - Use `SaveService` async writes for persistence (Save System Implementation).
  - Integrate warning animations via `UiStateStore` and pooled popups (UI State Management).
- **Dependencies**: Story 1.1.

### Story 1.3 Prototype Room Queue & Exploration Actions — Status: Draft
- **Acceptance Criteria**
  1. Room queue populates from data with difficulty, rewards, and event hooks.
  2. Selecting a room consumes an action, reveals details, queues replacement.
  3. Exploration outcomes adjust resources/threat per metadata.
  4. Empty queue auto-replenishes and shuffles when deck exhausted.
- **Technical Notes**
  - Implement `RoomQueueService` autoload and resource pipeline (RoomQueueService, Resource Architecture).
  - Use `res://resources/rooms/` data assets; thread-safe deck refills per Data Persistence Architecture.
  - Hook HUD updates through `ResourceLedger` signals.
- **Dependencies**: Stories 1.1, 1.2.

### Story 1.4 First Threat Encounter & Escape Resolution — Status: Draft
- **Acceptance Criteria**
  1. Scripted trigger latches threat, displays timer, rolls on expiry.
  2. Combat allows damage threshold resolution; evasion requires agility symbols.
  3. Collecting required clues unlocks escape prompt; failure shows defeat screen.
  4. Post-run summary logs resources, duration, telemetry stub output.
- **Technical Notes**
  - Use `ThreatService` and `CombatResolver` patterns (ThreatService section).
  - Escape prompt integrates with `GameDirector` state machine (State Machine Architecture).
  - Telemetry via `TelemetryHub` and analytics bridge (Analytics Integration).
- **Dependencies**: Stories 1.1–1.3.

## Epic 2: Threat Escalation & Room Depth
**Goal:** Broaden content and push-your-luck dynamics with varied rooms, threats, and time pressure.

### Story 2.1 Advanced Room Decks & Events — Status: Draft
- **Acceptance Criteria**
  1. Room data expanded to 30 cards with tags (hazard, cache, sanctuary, anomaly).
  2. Deck rules enforce composition limits via data-driven config.
  3. Narrative events surface contextual choices affecting resources/threat.
  4. Event resolver logs outcomes for tuning.
- **Technical Notes**
  - Extend resource schema and authoring pipeline (Resource Architecture, Data Persistence).
  - Event presentation uses `UiManager` overlays with pooled tooltips (UI Component System).
  - Deck configuration stored in `res://config/game_balance.tres` per Configuration Management.
- **Dependencies**: Story 1.3.

### Story 2.2 Threat Timer Variants & Status Effects — Status: Draft
- **Acceptance Criteria**
  1. Threat cards support unique timers (immediate, every turn, delayed burst).
  2. Threat dice inflict statuses (bleed, oxygen leak, dice lock) with UI icons/durations.
  3. Global threat meter reacts to unresolved threats each cycle.
  4. Combat log records threat actions for QA review.
- **Technical Notes**
  - Augment `ThreatService` timers and state machine (`ThreatService`, Entity State Machines).
  - Status effects implemented via `status_effects` resources and HUD badges (Resource Architecture, HUDController).
  - Combat log persisted via `TelemetryHub` custom events.
- **Dependencies**: Stories 1.4, 2.1.

### Story 2.3 Clue Milestones & Mini Objectives — Status: Draft
- **Acceptance Criteria**
  1. Clue counter triggers mini objectives at thresholds.
  2. Mini objectives offer optional challenges with rewards/penalties.
  3. Failing objectives escalates threat or drains oxygen.
  4. Victory sequence requires final objective plus clue threshold.
- **Technical Notes**
  - Implement milestone logic in `TurnManager` with signals to `GameDirector` (Gameplay Systems Overview, Game State Machine).
  - Mini objective scenes built as reusable packed scenes under `res://scenes/gameplay/`.
  - Rewards integrate with `ResourceLedger` and `EquipmentInventoryModel`.
- **Dependencies**: Stories 1.2–1.4, 2.1.

### Story 2.4 Push-Your-Luck Time Mechanics — Status: Draft
- **Acceptance Criteria**
  1. New actions discard top room at time/oxygen cost.
  2. Scouting reveals upcoming room with partial info/modifier.
  3. UI communicates action costs and prevents negative resources.
  4. Telemetry tracks time spent cycling vs accepting rooms.
- **Technical Notes**
  - Action economy handled by `TurnManager` action points and timers (TurnManager System).
  - UI overlays leverage `ActionChip` components (UI Component System).
  - Telemetry events extend `TelemetryHub` schema (Analytics Integration).
- **Dependencies**: Stories 1.3, 1.4, 2.1.

## Epic 3: Equipment Matrix & Progression
**Goal:** Deliver inventory puzzle, loot progression, and dice upgrades enabling build diversity.

### Story 3.1 Equipment Matrix UI & Constraints — Status: Draft
- **Acceptance Criteria**
  1. Grid-based equipment matrix supports drag, drop, rotate of varying shapes.
  2. Collision rules prevent overlap and provide haptic/audio feedback.
  3. Equipped items bind to dice slots or passives as defined in data.
  4. UI shows burden totals and quick-remove options without blocking combat.
- **Technical Notes**
  - Build matrix using `EquipmentController` Control nodes (`EquipmentController` section).
  - Apply anchoring and responsive layout guidelines (UI Architecture, UI State Management).
  - Feedback cues driven through pooled audio/particle managers (Audio Architecture, Particle System Architecture).
- **Dependencies**: Stories 1.1–1.4.

### Story 3.2 Loot Generation & Gear Effects — Status: Draft
- **Acceptance Criteria**
  1. Loot tables align with room/threat types and run depth.
  2. Gear items define dice costs, effects, cooldowns, rarities.
  3. Consuming dice via equipment updates exhaust pool immediately.
  4. Rare items introduce unique symbols with distinct visuals.
- **Technical Notes**
  - Utilize `equipment_module_resource` schema and pooling (Resource Architecture, EquipmentController).
  - Add loot generation utilities under `scripts/services/` per folder plan.
  - Visual variants handled via theme system and atlas assets (Sprite Management, Theme Guidelines).
- **Dependencies**: Stories 3.1, 2.x systems.

### Story 3.3 Experience & Level-Up Choices — Status: Draft
- **Acceptance Criteria**
  1. XP accrues from threats/objectives and tracks thresholds.
  2. Level-up screen offers at least three upgrade options.
  3. Selected upgrades adjust dice tray and persist in saves.
  4. Reject option banks level with minor cost.
- **Technical Notes**
  - Extend `ResourceLedger` for XP and call `UiManager` for level-up overlay (ResourceLedger, UI Architecture).
  - Persist upgrades via `MetaProgressResource` (Data Persistence Architecture).
  - Dice tray updates follow `DiceSubsystem` refresh patterns.
- **Dependencies**: Stories 1.2, 1.4, 3.1, 3.2.

### Story 3.4 Meta Progression & Unlocks — Status: Draft
- **Acceptance Criteria**
  1. Run results unlock new cards/equipment recorded in codex.
  2. Meta progression screen shows unlock tree with prerequisites.
  3. Codex tracks discovered content with lore snippets.
  4. Save system supports multiple profiles syncing unlocks cross-device when available.
- **Technical Notes**
  - Use `SaveService` and `MetaProgressResource` for persistent unlocks (Save System Implementation).
  - Codex UI reuses `UiManager` and `TooltipPanel` components (UI Component System).
  - Unlock tree data stored in `res://data/meta_progress/` resources.
- **Dependencies**: Stories 1.4, 3.2, 3.3.

## Epic 4: Atmosphere, UX Polish & Live Ops Hooks
**Goal:** Elevate presentation, onboarding, accessibility, and telemetry for launch readiness.

### Story 4.1 Visual & Audio Atmosphere Pass — Status: Draft
- **Acceptance Criteria**
  1. Dynamic lighting, particles, and shaders tuned for mobile performance.
  2. Layered soundtrack reacts to threat meter; ambient SFX per room type.
  3. Graphics settings toggle (performance vs fidelity) with live preview.
  4. Dice symbols and UI remain readable under atmospheric effects.
- **Technical Notes**
  - Implement rendering tiers per Rendering Pipeline Configuration.
  - Use `AudioDirector` snapshots tied to threat levels (Audio Mixing Configuration).
  - Validate performance with profiling gates (Performance Strategy, Particle Performance).
- **Dependencies**: Stories 1.x, 2.x, 3.x foundations.

### Story 4.2 Onboarding & Tutorials — Status: Draft
- **Acceptance Criteria**
  1. Contextual tutorial prompts trigger on first run with skip/next controls.
  2. Tutorial completion state persists per profile.
  3. Codex houses “Learn More” entries for advanced mechanics.
  4. Analytics flags tutorial drop-off points.
- **Technical Notes**
  - Use `TutorialService` autoload and overlay scenes (TutorialService section).
  - Persist states via `ConfigFile` and `SaveService` (UI State Management, Save System Implementation).
  - Telemetry events extend `TelemetryHub` schema.
- **Dependencies**: Stories 1.x, 2.x, 3.x.

### Story 4.3 Accessibility & UX Refinements — Status: Draft
- **Acceptance Criteria**
  1. Settings for text scaling, color palettes, vibration toggle, simplified controls.
  2. UI layouts adapt to larger fonts without overlap.
  3. Audio cues have caption equivalents where needed.
  4. UX heuristics review issues addressed.
- **Technical Notes**
  - Apply Control node anchoring/containers for responsive layout (UI Architecture).
  - Accessibility settings stored in `ConfigFile` with runtime updates (UI State Management).
  - Caption system integrates with `AudioDirector` and `UiStateStore`.
- **Dependencies**: Stories 1.2, 1.4, 4.2.

### Story 4.4 Analytics & Live Ops Foundations — Status: Draft
- **Acceptance Criteria**
  1. Analytics SDK captures runs, session length, upgrades, failure causes.
  2. Remote config toggles balancing parameters without code changes.
  3. Crash/error reporting tied to gameplay context.
  4. Live ops dashboard prototype surfaces key metrics for soft launch.
- **Technical Notes**
  - Implement analytics per `TelemetryHub` and OpenGameAnalytics integration (Analytics Integration).
  - Remote config scaffold through REST bridge referenced in architecture (External Integrations section).
  - Crash reporting via Sentry plugin with scrubbed PII (Sentry integration guidance).
- **Dependencies**: Stories 1.4, 2.4, 3.4.

